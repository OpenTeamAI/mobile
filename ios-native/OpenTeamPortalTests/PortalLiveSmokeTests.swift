import XCTest
@testable import OpenTeamPortal

final class PortalLiveSmokeTests: XCTestCase {
    func testAppReviewAuthTeamChatDetailSmoke() async throws {
        #if OPENTEAM_LIVE_SMOKE
        let store = MemorySessionStore()
        let client = APIClient(sessionStore: store)
        let environment = ProcessInfo.processInfo.environment
        guard let email = environment["OPENTEAM_APP_REVIEW_EMAIL"], !email.isEmpty,
              let code = environment["OPENTEAM_APP_REVIEW_CODE"], !code.isEmpty else {
            throw XCTSkip("Set OPENTEAM_APP_REVIEW_EMAIL and OPENTEAM_APP_REVIEW_CODE to run production API smoke tests.")
        }

        let health = try await client.loadHealth()
        XCTAssertTrue(health.status)

        let config = try await client.loadConfig()
        XCTAssertEqual(config.name, "openteam.ai")
        XCTAssertTrue(config.features.enableVoiceTranscription == true)

        let version = try await client.loadVersion()
        XCTAssertFalse(version.version.isEmpty)

        let catalog = try await client.loadOfficialAppsCatalog()
        XCTAssertGreaterThan(catalog.apps.count, 0)
        XCTAssertTrue(catalog.apps.contains { $0.supportsConnect })

        try await client.requestEmailCode(email: email)
        let session = try await client.verifyEmailCode(email: email, code: code)

        XCTAssertEqual(session.user.email, email)
        XCTAssertNotNil(store.currentToken())

        let team = try XCTUnwrap(
            session.teams.first { $0.name == "appreview-fcac0871" },
            "App Review login should expose the review team."
        )
        XCTAssertFalse(team.chatGatewayId.isEmpty)

        let chats = try await client.loadChats(gatewayId: team.chatGatewayId)
        let reviewChat = try XCTUnwrap(
            chats.first { $0.id == "2ed897ac-3c86-4516-8fcb-38ed4166c4c9" } ?? chats.first,
            "Gateway-scoped chat list should not be empty."
        )

        let detail = try await client.loadChat(id: reviewChat.id, gatewayId: team.chatGatewayId)
        XCTAssertEqual(detail.id, reviewChat.id)
        XCTAssertFalse(detail.title.isEmpty)
        XCTAssertGreaterThan(detail.messages.count, 0)
        XCTAssertTrue(detail.messages.contains { $0.role == "assistant" })

        let viewStatus = try await client.loadChatViewStatus(chatId: reviewChat.id, gatewayId: team.chatGatewayId)
        if viewStatus.available {
            XCTAssertNotNil(viewStatus.viewModel, "Native rendering requires view_model when a workspace view is available.")
        }
        #else
        throw XCTSkip("Build with OTHER_SWIFT_FLAGS='-D OPENTEAM_LIVE_SMOKE' to run production API smoke tests.")
        #endif
    }
}
