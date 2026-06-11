import Foundation

final class MockAPIClient: PortalAPI {
    private let user = PortalUser(
        id: "appreview",
        email: "reviewer@example.invalid",
        name: "App Review",
        role: "owner",
        profileImageUrl: nil,
        token: "mock-token"
    )

    private let team = PortalTeam(
        id: "appreview-fcac0871",
        gatewayId: "appreview-fcac0871",
        name: "appreview-fcac0871",
        role: "owner",
        isDefault: true
    )

    func loadHealth() async throws -> PortalHealth {
        PortalHealth(status: true)
    }

    func loadConfig() async throws -> PortalConfig {
        PortalConfig(
            status: true,
            name: "openteam.ai",
            version: "0.8.12",
            defaultLocale: "en-US",
            defaultModels: "",
            defaultPromptSuggestions: [],
            features: PortalFeatureFlags(
                auth: true,
                authTrustedHeader: false,
                enableApiKeys: false,
                enableSignup: false,
                enableLoginForm: true,
                enableWebSearch: false,
                enableGoogleDriveIntegration: false,
                enableOnedriveIntegration: false,
                enableImageGeneration: false,
                enableAdminExport: false,
                enableAdminChatAccess: false,
                enableAdminAnalytics: false,
                enableCommunitySharing: false,
                enableMemories: false,
                enableAutocompleteGeneration: false,
                enableDirectConnections: false,
                enableVersionUpdateCheck: false,
                enableVoiceTranscription: true
            )
        )
    }

    func loadVersion() async throws -> PortalVersion {
        PortalVersion(version: "0.8.12", deploymentId: nil)
    }

    func loadOfficialAppsCatalog() async throws -> PortalOfficialAppsCatalog {
        PortalOfficialAppsCatalog(
            schemaVersion: 1,
            source: "portal_app_service",
            appHome: "/home/openteam/.apps",
            apps: [
                PortalOfficialApp(
                    id: "canlii",
                    displayName: "CanLII",
                    version: "0.2.1",
                    expectedVersion: "0.2.1",
                    channel: "stable",
                    category: "Legal",
                    description: "Use the official CanLII API for Canadian case, legislation, and citator metadata.",
                    icon: "canlii",
                    websiteUrl: "https://www.canlii.org/",
                    skillCount: 5,
                    auth: PortalOfficialAppAuth(mode: "public", portalProvider: "canlii", runTokenRequired: true),
                    app: PortalOfficialAppSurface(kind: "official_app", surfaces: ["connect", "skills"]),
                    capabilities: PortalOfficialAppCapabilities(
                        requiresBrowser: false,
                        requiresFilesystem: false,
                        supportsTeamInstall: false,
                        supportsConfirmedWrites: false,
                        stateless: true
                    ),
                    connect: PortalOfficialAppConnect(
                        provider: "canlii",
                        kind: "public_api_mcp",
                        runtimeBinding: "podman_local_mcp",
                        mcpServerNames: ["canlii"],
                        credentialBoundary: "portal_service_secret",
                        sessionRequired: false,
                        browserProfileRequired: false
                    )
                ),
                PortalOfficialApp(
                    id: "westlaw",
                    displayName: "Westlaw Canada",
                    version: "0.1.2",
                    expectedVersion: "0.1.2",
                    channel: "stable",
                    category: "Legal",
                    description: "Use an authorized Westlaw Canada browser profile for legal research.",
                    icon: "westlaw",
                    websiteUrl: "https://1.next.westlaw.com/",
                    skillCount: 3,
                    auth: PortalOfficialAppAuth(mode: "public", portalProvider: "westlaw", runTokenRequired: true),
                    app: PortalOfficialAppSurface(kind: "official_app", surfaces: ["connect", "skills"]),
                    capabilities: PortalOfficialAppCapabilities(
                        requiresBrowser: true,
                        requiresFilesystem: false,
                        supportsTeamInstall: false,
                        supportsConfirmedWrites: true,
                        stateless: false
                    ),
                    connect: PortalOfficialAppConnect(
                        provider: "westlaw",
                        kind: "browser_profile_mcp",
                        runtimeBinding: "podman_local_mcp",
                        mcpServerNames: ["westlaw", "browser"],
                        credentialBoundary: "browser_profile",
                        sessionRequired: true,
                        browserProfileRequired: true
                    )
                )
            ]
        )
    }

    func requestEmailCode(email: String) async throws {}

    func verifyEmailCode(email: String, code: String) async throws -> PortalSession {
        PortalSession(token: "mock-token", user: user, teams: [team])
    }

    func restoreSession() async throws -> PortalSession {
        PortalSession(token: "mock-token", user: user, teams: [team])
    }

    func signOut() async throws {}

    func loadTeams() async throws -> PortalTeamsResponse {
        PortalTeamsResponse(items: [team])
    }

    func loadChats(gatewayId: String?) async throws -> [PortalChatSummary] {
        [Self.chatSummary]
    }

    func createChat(_ input: CreateChatRequest, gatewayId: String?) async throws -> PortalChatDetail {
        Self.chatDetail(title: input.title ?? "New task", userText: "")
    }

    func loadChat(id: String, gatewayId: String?) async throws -> PortalChatDetail {
        Self.chatDetail()
    }

    func stopChat(id: String, gatewayId: String?) async throws -> PortalChatDetail {
        var detail = Self.chatDetail()
        detail.isRunning = false
        return detail
    }

    func loadChatViewStatus(chatId: String, gatewayId: String?) async throws -> PortalSpaceViewStatus {
        PortalSpaceViewStatus(
            available: true,
            entryPath: nil,
            entryKind: "view_json",
            source: "mock",
            viewModel: PortalStructuredViewModel(
                title: "Gmail summary",
                subtitle: "Native structured workspace view",
                blocks: [
                    PortalStructuredBlock(
                        id: "header",
                        type: "header",
                        title: "Gmail summary",
                        subtitle: "Recent email overview",
                        description: nil,
                        content: nil,
                        items: nil,
                        columns: nil,
                        rows: nil,
                        fields: nil
                    ),
                    PortalStructuredBlock(
                        id: "items",
                        type: "items",
                        title: "Account",
                        subtitle: nil,
                        description: nil,
                        content: nil,
                        items: [
                            PortalStructuredItem(label: "Email", value: .string("reviewer@example.invalid"), tone: nil),
                            PortalStructuredItem(label: "Unread", value: .number(0), tone: "success")
                        ],
                        columns: nil,
                        rows: nil,
                        fields: nil
                    )
                ]
            )
        )
    }

    func streamMessage(
        chatId: String,
        gatewayId: String?,
        content: String,
        images: [PortalMessageImage],
        files: [PortalMessageFile]
    ) throws -> AsyncThrowingStream<TextStreamUpdate, Error> {
        AsyncThrowingStream { continuation in
            Task {
                continuation.yield(TextStreamUpdate(done: false, value: "", codexEvent: PortalActivityEvent(
                    kind: "thinking",
                    phase: "started",
                    id: "think-1",
                    title: "Reading Gmail",
                    detail: "Searching recent messages for reviewer@example.invalid.",
                    text: nil,
                    command: nil,
                    status: nil,
                    aggregatedOutput: nil,
                    exitCode: nil,
                    updatedAt: nil,
                    sequence: 1
                )))
                try await Task.sleep(nanoseconds: 250_000_000)
                continuation.yield(TextStreamUpdate(done: false, value: "I can read your connected Gmail account. "))
                try await Task.sleep(nanoseconds: 120_000_000)
                continuation.yield(TextStreamUpdate(done: false, value: "There are no urgent unread messages in this review inbox."))
                continuation.yield(TextStreamUpdate(done: true, value: ""))
                continuation.finish()
            }
        }
    }

    func resumeRun(
        chatId: String,
        runId: String,
        gatewayId: String?,
        afterSequence: Int
    ) throws -> AsyncThrowingStream<TextStreamUpdate, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(TextStreamUpdate(done: true, value: ""))
            continuation.finish()
        }
    }

    private static let chatSummary = PortalChatSummary(
        id: "could-you-read-my-email",
        title: "could you read my email",
        updatedAt: "2026-06-04T22:00:00Z",
        execPath: nil,
        workflowExecPath: nil,
        workdir: nil,
        gatewayId: "appreview-fcac0871",
        agentId: nil,
        spaceId: nil,
        workplaceId: nil,
        publishedWorkflowId: nil,
        lastMessagePreview: "reviewer@example.invalid",
        isRunning: false,
        isQueued: false,
        queuePosition: nil
    )

    private static func chatDetail(
        title: String = "could you read my email",
        userText: String = "could you read my email"
    ) -> PortalChatDetail {
        PortalChatDetail(
            id: "could-you-read-my-email",
            title: title,
            updatedAt: "2026-06-04T22:00:00Z",
            execPath: nil,
            workflowExecPath: nil,
            workdir: nil,
            gatewayId: "appreview-fcac0871",
            agentId: nil,
            spaceId: nil,
            workplaceId: nil,
            publishedWorkflowId: nil,
            lastMessagePreview: "reviewer@example.invalid",
            isRunning: false,
            isQueued: false,
            queuePosition: nil,
            createdAt: "2026-06-04T22:00:00Z",
            messages: [
                PortalMessage(
                    id: "u1",
                    role: "user",
                    content: userText,
                    createdAt: "2026-06-04T22:00:00Z",
                    state: "completed",
                    activities: nil,
                    images: nil,
                    files: nil
                ),
                PortalMessage(
                    id: "a1",
                    role: "assistant",
                    content: "I checked the connected Gmail account for reviewer@example.invalid. There are no urgent unread messages in the review inbox.",
                    createdAt: "2026-06-04T22:00:05Z",
                    state: "completed",
                    activities: [
                        PortalActivityEvent(
                            kind: "command_execution",
                            phase: "completed",
                            id: "gmail-search",
                            title: "Gmail search",
                            detail: "Searched recent messages.",
                            text: nil,
                            command: "gmail.search query:newer_than:7d",
                            status: "success",
                            aggregatedOutput: "No urgent unread messages found.",
                            exitCode: 0,
                            updatedAt: "2026-06-04T22:00:04Z",
                            sequence: 1
                        )
                    ],
                    images: nil,
                    files: nil
                )
            ],
            queuedMessages: [],
            currentView: nil,
            liveRun: nil
        )
    }
}
