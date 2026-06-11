import SwiftUI

@main
struct OpenTeamPortalApp: App {
    @StateObject private var appModel = AppViewModel.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
                .tint(PortalTheme.accent)
                .task {
                    await appModel.restoreSession()
                }
        }
    }
}

