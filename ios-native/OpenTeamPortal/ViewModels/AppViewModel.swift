import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    enum Route {
        case checking
        case signedOut
        case choosingTeam
        case portal
    }

    @Published var route: Route = .checking
    @Published var session: PortalSession?
    @Published var selectedTeam: PortalTeam?
    @Published var errorMessage: String?
    @Published var preferredScheme: ColorScheme?

    let apiClient: PortalAPI
    let cache: PortalCache

    private let sessionStore: SessionStore
    private var configuredReviewEmail: String? {
        ProcessInfo.processInfo.environment["OPENTEAM_APP_REVIEW_EMAIL"]?.lowercased()
    }

    init(apiClient: PortalAPI, sessionStore: SessionStore, cache: PortalCache) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
        self.cache = cache
    }

    static func live() -> AppViewModel {
        let store = KeychainSessionStore()
        if ProcessInfo.processInfo.arguments.contains("--reset-session") {
            try? store.clear()
        }
        if ProcessInfo.processInfo.arguments.contains("--mock-data") ||
            ProcessInfo.processInfo.environment["OPENTEAM_MOCK_DATA"] == "1" {
            return AppViewModel(
                apiClient: MockAPIClient(),
                sessionStore: store,
                cache: PortalCache(inMemory: true)
            )
        }

        return AppViewModel(
            apiClient: APIClient(sessionStore: store),
            sessionStore: store,
            cache: PortalCache()
        )
    }

    func restoreSession() async {
        do {
            let restored = try await apiClient.restoreSession()
            completeLogin(restored)
        } catch PortalError.missingToken {
            route = .signedOut
        } catch {
            errorMessage = error.localizedDescription
            route = .signedOut
        }
    }

    func completeLogin(_ session: PortalSession) {
        self.session = session
        selectedTeam = defaultTeam(for: session)
        route = selectedTeam == nil ? .choosingTeam : .portal
    }

    func select(team: PortalTeam) {
        selectedTeam = team
        route = .portal
    }

    func signOut() async {
        do {
            try await apiClient.signOut()
        } catch {
            try? sessionStore.clear()
        }
        session = nil
        selectedTeam = nil
        route = .signedOut
    }

    private func defaultTeam(for session: PortalSession) -> PortalTeam? {
        if let reviewEmail = configuredReviewEmail,
           session.user.email.lowercased() == reviewEmail,
           let reviewTeam = session.teams.first(where: {
               $0.name == "appreview-fcac0871" || $0.id == "appreview-fcac0871"
           }) {
            return reviewTeam
        }

        return session.teams.first(where: { $0.isDefault == true }) ?? session.teams.first
    }
}
