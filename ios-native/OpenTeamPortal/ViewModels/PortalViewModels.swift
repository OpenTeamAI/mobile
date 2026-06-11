import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    enum Phase {
        case email
        case code
    }

    @Published var phase: Phase = .email
    @Published var email = ""
    @Published var code = ""
    @Published var isBusy = false
    @Published var errorMessage: String?

    func submit(app: AppViewModel) async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }

        do {
            switch phase {
            case .email:
                try await app.apiClient.requestEmailCode(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
                phase = .code
            case .code:
                let session = try await app.apiClient.verifyEmailCode(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    code: code.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                app.completeLogin(session)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class PortalViewModel: ObservableObject {
    @Published var chats: [PortalChatSummary] = []
    @Published var selectedChat: PortalChatSummary?
    @Published var config: PortalConfig?
    @Published var version: PortalVersion?
    @Published var officialApps: [PortalOfficialApp] = []
    @Published var query = ""
    @Published var isLoading = false
    @Published var isLoadingMetadata = false
    @Published var errorMessage: String?
    @Published var metadataErrorMessage: String?
    @Published var showsSettings = false

    private let api: PortalAPI
    private let cache: PortalCache

    init(api: PortalAPI, cache: PortalCache) {
        self.api = api
        self.cache = cache
    }

    func loadMetadata() async {
        isLoadingMetadata = true
        defer { isLoadingMetadata = false }

        do {
            config = try await api.loadConfig()
        } catch {
            metadataErrorMessage = error.localizedDescription
        }

        do {
            version = try await api.loadVersion()
        } catch {
            metadataErrorMessage = error.localizedDescription
        }

        do {
            officialApps = try await api.loadOfficialAppsCatalog().apps
        } catch {
            metadataErrorMessage = error.localizedDescription
        }
    }

    var filteredChats: [PortalChatSummary] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else {
            return chats
        }
        return chats.filter {
            $0.title.lowercased().contains(term) ||
            $0.lastMessagePreview.lowercased().contains(term)
        }
    }

    func load(gatewayId: String?) async {
        let key = Self.cacheKey(gatewayId: gatewayId)
        if let cached = try? cache.load([PortalChatSummary].self, forKey: key) {
            chats = cached
            selectedChat = selectedChat ?? cached.first
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let fresh = try await api.loadChats(gatewayId: gatewayId)
            chats = fresh
            selectedChat = selectedChat ?? fresh.first
            try? cache.save(fresh, forKey: key)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createChat(title: String = "New task", gatewayId: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let detail = try await api.createChat(CreateChatRequest(title: title), gatewayId: gatewayId)
            let summary = PortalChatSummary(
                id: detail.id,
                title: detail.title,
                updatedAt: detail.updatedAt,
                execPath: detail.execPath,
                workflowExecPath: detail.workflowExecPath,
                workdir: detail.workdir,
                gatewayId: detail.gatewayId,
                agentId: detail.agentId,
                spaceId: detail.spaceId,
                workplaceId: detail.workplaceId,
                publishedWorkflowId: detail.publishedWorkflowId,
                lastMessagePreview: detail.lastMessagePreview,
                isRunning: detail.isRunning,
                isQueued: detail.isQueued,
                queuePosition: detail.queuePosition
            )
            chats.insert(summary, at: 0)
            selectedChat = summary
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func cacheKey(gatewayId: String?) -> String {
        let value = gatewayId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "chats" : "chats:\(value)"
    }
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var detail: PortalChatDetail?
    @Published var draft = ""
    @Published var selectedModel = "Standard"
    @Published var selectedSpeed = "Standard"
    @Published var isLoading = false
    @Published var isStreaming = false
    @Published var errorMessage: String?
    @Published var streamStatus: String?
    @Published var structuredView: PortalStructuredViewModel?

    let summary: PortalChatSummary
    private let gatewayId: String?
    private let api: PortalAPI
    private let cache: PortalCache

    init(summary: PortalChatSummary, gatewayId: String?, api: PortalAPI, cache: PortalCache) {
        self.summary = summary
        self.gatewayId = summary.gatewayId ?? gatewayId
        self.api = api
        self.cache = cache
    }

    func load() async {
        if let cached = try? cache.load(PortalChatDetail.self, forKey: "chat:\(summary.id)") {
            detail = cached
            structuredView = cached.currentView
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let fresh = try await api.loadChat(id: summary.id, gatewayId: gatewayId)
            detail = fresh
            structuredView = fresh.currentView
            try? cache.save(fresh, forKey: "chat:\(summary.id)")
            await loadStructuredView()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadStructuredView() async {
        do {
            let status = try await api.loadChatViewStatus(chatId: summary.id, gatewayId: gatewayId)
            if let viewModel = status.viewModel {
                structuredView = viewModel
            } else if status.available {
                throw PortalError.htmlOnlyView(summary.title)
            }
        } catch PortalError.htmlOnlyView(let title) {
            streamStatus = "\(title) needs a native view model."
        } catch {
            // Workspace view is optional for the chat path; keep the thread usable.
        }
    }

    func send() async {
        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !isStreaming else {
            return
        }

        draft = ""
        appendOptimisticUserMessage(content)
        isStreaming = true
        streamStatus = "Thinking"
        errorMessage = nil
        defer {
            isStreaming = false
        }

        do {
            let stream = try api.streamMessage(
                chatId: summary.id,
                gatewayId: gatewayId,
                content: content,
                images: [],
                files: []
            )
            for try await update in stream {
                try Task.checkCancellation()
                apply(update)
                if update.done {
                    break
                }
            }
            if let detail {
                try? cache.save(detail, forKey: "chat:\(summary.id)")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stop() async {
        do {
            detail = try await api.stopChat(id: summary.id, gatewayId: gatewayId)
            streamStatus = "Stopped"
            isStreaming = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func appendOptimisticUserMessage(_ content: String) {
        var next = detail
        let now = ISO8601DateFormatter().string(from: Date())
        let userMessage = PortalMessage(
            id: UUID().uuidString,
            role: "user",
            content: content,
            createdAt: now,
            state: "completed",
            activities: nil,
            images: nil,
            files: nil
        )
        let assistant = PortalMessage(
            id: UUID().uuidString,
            role: "assistant",
            content: "",
            createdAt: now,
            state: "in_progress",
            activities: [],
            images: nil,
            files: nil
        )
        next?.messages.append(userMessage)
        next?.messages.append(assistant)
        detail = next
    }

    private func apply(_ update: TextStreamUpdate) {
        if let errorMessage = update.errorMessage {
            self.errorMessage = errorMessage
            return
        }
        if let run = update.codexRun {
            streamStatus = run.queuePosition.map { "Queued \($0)" } ?? run.status
        }
        if let queue = update.codexQueue {
            streamStatus = queue.position.map { "Queued \($0)" } ?? queue.status
        }
        if let event = update.codexEvent {
            append(activity: event)
        }
        if let final = update.codexFinal {
            replaceAssistantText(final.responseText)
            streamStatus = "Done"
        }
        if !update.value.isEmpty {
            appendAssistantText(update.value)
        }
        if update.done {
            streamStatus = "Done"
        }
    }

    private func append(activity: PortalActivityEvent) {
        guard var next = detail, let index = next.messages.lastIndex(where: { !$0.isUser }) else {
            return
        }
        var message = next.messages[index]
        var activities = message.activities ?? []
        if let existingIndex = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[existingIndex] = activity
        } else {
            activities.append(activity)
        }
        message.activities = activities
        next.messages[index] = message
        detail = next
    }

    private func appendAssistantText(_ text: String) {
        guard var next = detail, let index = next.messages.lastIndex(where: { !$0.isUser }) else {
            return
        }
        next.messages[index].content += text
        detail = next
    }

    private func replaceAssistantText(_ text: String) {
        guard var next = detail, let index = next.messages.lastIndex(where: { !$0.isUser }) else {
            return
        }
        next.messages[index].content = text
        next.messages[index].state = "completed"
        detail = next
    }
}
