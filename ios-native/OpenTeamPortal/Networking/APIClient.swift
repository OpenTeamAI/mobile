import Foundation

struct EmptyResponse: Codable, Equatable {}

protocol PortalAPI {
    func loadHealth() async throws -> PortalHealth
    func loadConfig() async throws -> PortalConfig
    func loadVersion() async throws -> PortalVersion
    func loadOfficialAppsCatalog() async throws -> PortalOfficialAppsCatalog
    func requestEmailCode(email: String) async throws
    func verifyEmailCode(email: String, code: String) async throws -> PortalSession
    func restoreSession() async throws -> PortalSession
    func signOut() async throws
    func loadTeams() async throws -> PortalTeamsResponse
    func loadChats(gatewayId: String?) async throws -> [PortalChatSummary]
    func createChat(_ input: CreateChatRequest, gatewayId: String?) async throws -> PortalChatDetail
    func loadChat(id: String, gatewayId: String?) async throws -> PortalChatDetail
    func stopChat(id: String, gatewayId: String?) async throws -> PortalChatDetail
    func loadChatViewStatus(chatId: String, gatewayId: String?) async throws -> PortalSpaceViewStatus
    func streamMessage(
        chatId: String,
        gatewayId: String?,
        content: String,
        images: [PortalMessageImage],
        files: [PortalMessageFile]
    ) throws -> AsyncThrowingStream<TextStreamUpdate, Error>
    func resumeRun(
        chatId: String,
        runId: String,
        gatewayId: String?,
        afterSequence: Int
    ) throws -> AsyncThrowingStream<TextStreamUpdate, Error>
}

final class APIClient: PortalAPI {
    private enum PathScope {
        case root
        case api
        case v1
    }

    private let environment: PortalEnvironment
    private let urlSession: URLSession
    private let sessionStore: SessionStore

    init(
        environment: PortalEnvironment = .production,
        urlSession: URLSession = .shared,
        sessionStore: SessionStore
    ) {
        self.environment = environment
        self.urlSession = urlSession
        self.sessionStore = sessionStore
    }

    func loadHealth() async throws -> PortalHealth {
        try await requestFromRoot("/health")
    }

    func loadConfig() async throws -> PortalConfig {
        try await requestFromAPI("/config")
    }

    func loadVersion() async throws -> PortalVersion {
        try await requestFromAPI("/version")
    }

    func loadOfficialAppsCatalog() async throws -> PortalOfficialAppsCatalog {
        try await request("/apps/official/catalog")
    }

    func requestEmailCode(email: String) async throws {
        let _: NativeAuthStartResponse = try await request(
            "/auths/email/code",
            method: "POST",
            body: ["email": email]
        )
    }

    func verifyEmailCode(email: String, code: String) async throws -> PortalSession {
        let user: PortalUser = try await request(
            "/auths/email/verify",
            method: "POST",
            body: ["email": email, "code": code]
        )
        guard let token = user.token, !token.isEmpty else {
            throw PortalError.missingToken
        }

        try sessionStore.save(token: token)
        let teams = try await loadTeams().items
        return PortalSession(token: token, user: user, teams: teams)
    }

    func restoreSession() async throws -> PortalSession {
        guard sessionStore.currentToken() != nil else {
            throw PortalError.missingToken
        }

        let user: PortalUser = try await request("/auths/")
        let token = user.token ?? sessionStore.currentToken() ?? ""
        let teamsResponse = try await loadTeams()
        let teams = teamsResponse.items
        return PortalSession(token: token, user: user, teams: teams)
    }

    func signOut() async throws {
        let _: EmptyResponse = try await request("/auths/signout")
        try sessionStore.clear()
    }

    func loadTeams() async throws -> PortalTeamsResponse {
        try await request("/gateways/teams")
    }

    func loadChats(gatewayId: String?) async throws -> [PortalChatSummary] {
        try await request(withGatewayQuery("/codex/chats", gatewayId: gatewayId))
    }

    func createChat(
        _ input: CreateChatRequest = CreateChatRequest(),
        gatewayId: String?
    ) async throws -> PortalChatDetail {
        var nextInput = input
        if nextInput.gatewayId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            nextInput.gatewayId = gatewayId
        }
        return try await request("/codex/chats", method: "POST", body: nextInput)
    }

    func loadChat(id: String, gatewayId: String?) async throws -> PortalChatDetail {
        try await request(withGatewayQuery("/codex/chats/\(id.urlPathEncoded)", gatewayId: gatewayId))
    }

    func stopChat(id: String, gatewayId: String?) async throws -> PortalChatDetail {
        try await request(
            withGatewayQuery("/codex/chats/\(id.urlPathEncoded)/stop", gatewayId: gatewayId),
            method: "POST",
            body: EmptyResponse()
        )
    }

    func loadChatViewStatus(chatId: String, gatewayId: String?) async throws -> PortalSpaceViewStatus {
        try await request(
            withGatewayQuery("/codex/chats/\(chatId.urlPathEncoded)/view/status", gatewayId: gatewayId)
        )
    }

    func streamMessage(
        chatId: String,
        gatewayId: String?,
        content: String,
        images: [PortalMessageImage] = [],
        files: [PortalMessageFile] = []
    ) throws -> AsyncThrowingStream<TextStreamUpdate, Error> {
        let body = SendMessageRequest(content: content, images: images, files: files)
        return try stream(
            withGatewayQuery(
                "/codex/chats/\(chatId.urlPathEncoded)/messages/stream",
                gatewayId: gatewayId
            ),
            method: "POST",
            body: body
        )
    }

    func resumeRun(
        chatId: String,
        runId: String,
        gatewayId: String?,
        afterSequence: Int
    ) throws -> AsyncThrowingStream<TextStreamUpdate, Error> {
        try stream(
            withGatewayQuery(
                "/codex/chats/\(chatId.urlPathEncoded)/runs/\(runId.urlPathEncoded)/stream?after_sequence=\(max(afterSequence, 0))",
                gatewayId: gatewayId
            ),
            method: "GET",
            bodyData: nil
        )
    }

    private func request<T: Decodable>(_ path: String, method: String = "GET") async throws -> T {
        try await perform(path: path, scope: .v1, method: method, bodyData: nil)
    }

    private func requestFromRoot<T: Decodable>(_ path: String, method: String = "GET") async throws -> T {
        try await perform(path: path, scope: .root, method: method, bodyData: nil)
    }

    private func requestFromAPI<T: Decodable>(_ path: String, method: String = "GET") async throws -> T {
        try await perform(path: path, scope: .api, method: method, bodyData: nil)
    }

    private func request<T: Decodable, Body: Encodable>(
        _ path: String,
        method: String,
        body: Body
    ) async throws -> T {
        let data = try JSONEncoder.portal.encode(body)
        return try await perform(path: path, scope: .v1, method: method, bodyData: data)
    }

    private func perform<T: Decodable>(
        path: String,
        scope: PathScope,
        method: String,
        bodyData: Data?
    ) async throws -> T {
        var request = try makeRequest(path: path, scope: scope, method: method, bodyData: bodyData)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        try validate(response: response, data: data)

        if T.self == EmptyResponse.self, data.isEmpty {
            return EmptyResponse() as! T
        }
        return try JSONDecoder.portal.decode(T.self, from: data)
    }

    private func stream<Body: Encodable>(
        _ path: String,
        method: String,
        body: Body
    ) throws -> AsyncThrowingStream<TextStreamUpdate, Error> {
        let data = try JSONEncoder.portal.encode(body)
        return try stream(path, method: method, bodyData: data)
    }

    private func stream(
        _ path: String,
        method: String,
        bodyData: Data?
    ) throws -> AsyncThrowingStream<TextStreamUpdate, Error> {
        var request = try makeRequest(path: path, scope: .v1, method: method, bodyData: bodyData)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await urlSession.bytes(for: request)
                    try validate(response: response, data: Data())

                    var parser = SSEParser()
                    for try await line in bytes.lines {
                        if let event = parser.feed(line: line),
                           let update = try PortalStreamDecoder.decode(event: event) {
                            continuation.yield(update)
                            if update.done {
                                continuation.finish()
                                return
                            }
                        }
                    }

                    if let event = parser.finish(),
                       let update = try PortalStreamDecoder.decode(event: event) {
                        continuation.yield(update)
                    }
                    continuation.yield(TextStreamUpdate(done: true, value: ""))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func makeRequest(
        path: String,
        scope: PathScope,
        method: String,
        bodyData: Data?
    ) throws -> URLRequest {
        let baseURL: URL
        switch scope {
        case .root:
            baseURL = environment.baseURL
        case .api:
            baseURL = environment.apiRootURL
        case .v1:
            baseURL = environment.apiBaseURL
        }

        let base = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard let url = URL(string: "\(base)/\(normalizedPath)") else {
            throw PortalError.invalidURL(path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = bodyData
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = sessionStore.currentToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func withGatewayQuery(_ path: String, gatewayId: String?) -> String {
        let value = gatewayId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !value.isEmpty else {
            return path
        }

        let separator = path.contains("?") ? "&" : "?"
        return "\(path)\(separator)gateway_id=\(value.urlQueryEncoded)"
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw PortalError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            if let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let detail = payload["detail"] as? String
                    ?? payload["message"] as? String
                    ?? "Request failed with HTTP \(http.statusCode)."
                throw PortalError.backend(detail)
            }
            throw PortalError.backend("Request failed with HTTP \(http.statusCode).")
        }
    }
}

private extension String {
    var urlPathEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self
    }

    var urlQueryEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
