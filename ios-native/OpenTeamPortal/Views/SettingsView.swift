import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var app: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var config: PortalConfig?
    var version: PortalVersion?
    var officialApps: [PortalOfficialApp]

    @State private var selectedTab = "General"
    @State private var theme = "System"
    @State private var includeImages = true

    private let tabs = ["General", "Account", "Appearance", "Team"]

    var body: some View {
        NavigationView {
            Form {
                Picker("Settings", selection: $selectedTab) {
                    ForEach(tabs, id: \.self) { tab in
                        Text(tab).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedTab {
                case "Account":
                    accountSection
                case "Appearance":
                    appearanceSection
                case "Team":
                    teamSection
                default:
                    generalSection
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var generalSection: some View {
        Group {
            Section("Chat") {
                Toggle("Include generated images", isOn: $includeImages)
                SettingsRow(title: "Timezone", value: TimeZone.current.identifier)
            }

            Section("Portal") {
                SettingsRow(title: "Version", value: version?.version ?? config?.version ?? "-")
                SettingsRow(title: "Voice", value: config?.features.enableVoiceTranscription == true ? "Enabled" : "Disabled")
                SettingsRow(title: "Official apps", value: "\(officialApps.count)")
            }
        }
    }

    private var accountSection: some View {
        Section {
            HStack(spacing: 12) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading) {
                    Text(app.session?.user.name ?? "OpenTeam user")
                    Text(app.session?.user.email ?? "")
                        .font(.caption)
                        .foregroundStyle(PortalTheme.secondaryText)
                }
            }

            Button(role: .destructive) {
                Task {
                    await app.signOut()
                    dismiss()
                }
            } label: {
                Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker("Theme", selection: $theme) {
                Text("System").tag("System")
                Text("Warm").tag("Warm")
                Text("Light").tag("Light")
                Text("Dark").tag("Dark")
            }
            .pickerStyle(.segmented)

            Text("OpenTeam keeps the brand warmth but uses native iOS navigation, sheets, keyboard behavior, and controls.")
                .font(.footnote)
                .foregroundStyle(PortalTheme.secondaryText)
        }
    }

    private var teamSection: some View {
        Section {
            ForEach(app.session?.teams ?? []) { team in
                HStack {
                    VStack(alignment: .leading) {
                        Text(team.name)
                        Text(team.role.capitalized)
                            .font(.caption)
                            .foregroundStyle(PortalTheme.secondaryText)
                    }
                    Spacer()
                    if app.selectedTeam?.id == team.id {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    app.select(team: team)
                }
            }
        }
    }
}

private struct SettingsRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(PortalTheme.secondaryText)
        }
    }
}
