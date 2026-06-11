import Foundation

struct ServerSentEvent: Equatable {
    var event: String?
    var data: String
}

struct TextStreamUpdate: Equatable {
    var done: Bool
    var value: String
    var runId: String?
    var sequence: Int?
    var errorMessage: String?
    var codexRun: CodexRunUpdate?
    var codexEvent: PortalActivityEvent?
    var codexFinal: CodexFinalUpdate?
    var codexQueue: CodexQueueUpdate?
}

struct CodexRunUpdate: Equatable {
    var runId: String
    var status: String
    var lastEventSequence: Int
    var queuePosition: Int?
    var startedAt: String
    var updatedAt: String
}

struct CodexFinalUpdate: Equatable {
    var responseText: String
    var threadId: String
    var runId: String
    var sequence: Int?
}

struct CodexQueueUpdate: Equatable {
    var status: String
    var position: Int?
    var runId: String
    var sequence: Int?
}

struct SSEParser {
    private var eventName: String?
    private var dataLines: [String] = []

    mutating func feed(line: String) -> ServerSentEvent? {
        if line.isEmpty {
            guard !dataLines.isEmpty else {
                eventName = nil
                return nil
            }

            let event = ServerSentEvent(event: eventName, data: dataLines.joined(separator: "\n"))
            eventName = nil
            dataLines = []
            return event
        }

        if line.hasPrefix(":") {
            return nil
        }

        let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        let field = String(parts.first ?? "")
        var value = parts.count > 1 ? String(parts[1]) : ""
        if value.hasPrefix(" ") {
            value.removeFirst()
        }

        switch field {
        case "event":
            eventName = value
        case "data":
            dataLines.append(value)
        default:
            break
        }

        return nil
    }

    mutating func finish() -> ServerSentEvent? {
        feed(line: "")
    }
}

enum PortalStreamDecoder {
    static func decode(event: ServerSentEvent) throws -> TextStreamUpdate? {
        try decode(data: event.data)
    }

    static func decode(data: String) throws -> TextStreamUpdate? {
        if data.hasPrefix("[DONE]") {
            return TextStreamUpdate(done: true, value: "")
        }

        guard let payload = data.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: payload) as? [String: Any] else {
            return nil
        }

        let runId = json["run_id"] as? String
        let sequence = json["sequence"] as? Int

        if let error = json["error"] as? [String: Any] {
            return TextStreamUpdate(
                done: true,
                value: "",
                runId: runId,
                sequence: sequence,
                errorMessage: error["message"] as? String ?? "Stream failed."
            )
        }

        if let run = json["codex_run"] as? [String: Any] {
            return TextStreamUpdate(
                done: false,
                value: "",
                runId: runId,
                sequence: sequence,
                codexRun: CodexRunUpdate(
                    runId: run["run_id"] as? String ?? runId ?? "",
                    status: String(describing: run["status"] ?? ""),
                    lastEventSequence: run["last_event_sequence"] as? Int ?? 0,
                    queuePosition: run["queue_position"] as? Int,
                    startedAt: String(describing: run["started_at"] ?? ""),
                    updatedAt: String(describing: run["updated_at"] ?? "")
                )
            )
        }

        if let event = json["codex_event"] as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: event) {
            let decoder = JSONDecoder.portal
            var activity = try decoder.decode(PortalActivityEvent.self, from: data)
            activity.sequence = sequence
            return TextStreamUpdate(
                done: false,
                value: "",
                runId: runId,
                sequence: sequence,
                codexEvent: activity
            )
        }

        if let final = json["codex_final"] as? [String: Any] {
            return TextStreamUpdate(
                done: false,
                value: "",
                runId: runId,
                sequence: sequence,
                codexFinal: CodexFinalUpdate(
                    responseText: String(describing: final["response_text"] ?? ""),
                    threadId: String(describing: final["thread_id"] ?? ""),
                    runId: final["run_id"] as? String ?? runId ?? "",
                    sequence: sequence
                )
            )
        }

        if let queue = json["codex_queue"] as? [String: Any] {
            return TextStreamUpdate(
                done: false,
                value: "",
                runId: runId,
                sequence: sequence,
                codexQueue: CodexQueueUpdate(
                    status: String(describing: queue["status"] ?? ""),
                    position: queue["position"] as? Int,
                    runId: queue["run_id"] as? String ?? runId ?? "",
                    sequence: sequence
                )
            )
        }

        let choices = json["choices"] as? [[String: Any]]
        let delta = choices?.first?["delta"] as? [String: Any]
        return TextStreamUpdate(
            done: false,
            value: delta?["content"] as? String ?? "",
            runId: runId,
            sequence: sequence
        )
    }
}

extension JSONDecoder {
    static var portal: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

extension JSONEncoder {
    static var portal: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

