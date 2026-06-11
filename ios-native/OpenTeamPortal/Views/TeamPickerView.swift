import SwiftUI

struct TeamPickerView: View {
    @EnvironmentObject private var app: AppViewModel
    @Environment(\.dismiss) private var dismiss
    var dismissesOnSelection = false
    var showsDoneButton = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(app.session?.teams ?? []) { team in
                        Button {
                            app.select(team: team)
                            if dismissesOnSelection {
                                dismiss()
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(team.name)
                                        .font(.headline)
                                    Text(team.role.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(PortalTheme.secondaryText)
                                }
                                Spacer()
                                if app.selectedTeam?.id == team.id {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                        }
                    }
                } header: {
                    Text("Choose a team")
                }
            }
            .navigationTitle("OpenTeam")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .opacity(showsDoneButton ? 1 : 0)
                    .disabled(!showsDoneButton)
                    .accessibilityHidden(!showsDoneButton)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign out") {
                        Task { await app.signOut() }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
