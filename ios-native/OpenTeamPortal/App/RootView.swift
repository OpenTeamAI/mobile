import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        Group {
            switch app.route {
            case .checking:
                SplashView()
            case .signedOut:
                AuthView()
            case .choosingTeam:
                TeamPickerView()
            case .portal:
                PortalShellView(app: app)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: app.route)
        .preferredColorScheme(app.preferredScheme)
    }
}

private struct SplashView: View {
    var body: some View {
        ZStack {
            PortalTheme.background.ignoresSafeArea()
            VStack(spacing: 18) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                ProgressView()
                Text("OpenTeam")
                    .font(.headline)
            }
            .foregroundStyle(PortalTheme.primaryText)
        }
    }
}
