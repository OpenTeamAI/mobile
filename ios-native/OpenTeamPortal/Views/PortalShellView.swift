import SwiftUI

struct PortalShellView: View {
    @EnvironmentObject private var app: AppViewModel
    @StateObject private var model: PortalViewModel

    init(app: AppViewModel) {
        _model = StateObject(wrappedValue: PortalViewModel(api: app.apiClient, cache: app.cache))
    }

    var body: some View {
        NavigationView {
            PortalHomeView(model: model)
                .environmentObject(app)
        }
        .navigationViewStyle(.stack)
        .task {
            await model.loadMetadata()
        }
        .task(id: app.selectedTeam?.chatGatewayId) {
            await model.load(gatewayId: app.selectedTeam?.chatGatewayId)
        }
        .sheet(isPresented: $model.showsSettings) {
            SettingsView(
                config: model.config,
                version: model.version,
                officialApps: model.officialApps
            )
                .environmentObject(app)
        }
    }
}

private struct PortalHomeView: View {
    @ObservedObject var model: PortalViewModel
    @EnvironmentObject private var app: AppViewModel
    @State private var showsSearch = false
    @State private var showsChat = false
    @State private var showsTeamPicker = false
    @State private var newTaskText = ""

    var body: some View {
        ZStack {
            PortalTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.selectedTeam?.name ?? "OpenTeam")
                                    .font(.headline)
                                    .foregroundStyle(PortalTheme.primaryText)
                                Text("Recent")
                                    .font(.subheadline)
                                    .foregroundStyle(PortalTheme.primaryText)
                            }

                            Spacer()

                            Button { showsTeamPicker = true } label: {
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(PortalTheme.primaryText)
                                    .frame(width: 28, height: 28)
                            }
                            .accessibilityLabel("Switch team")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        VStack(spacing: 12) {
                            ForEach(model.filteredChats) { chat in
                                NavigationLink(
                                    destination: ChatHostView(
                                        summary: chat,
                                        gatewayId: app.selectedTeam?.chatGatewayId,
                                        app: app
                                    )
                                ) {
                                    ChatHomeCard(chat: chat)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("chat-card-\(chat.id)")
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 180)
                }

                Spacer(minLength: 0)
            }

            VStack {
                Spacer()
                HomeComposer(
                    text: $newTaskText,
                    officialApps: model.officialApps,
                    isLoadingMetadata: model.isLoadingMetadata,
                    isBusy: model.isLoading,
                    onSubmit: {
                        Task {
                            if !newTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                await model.createChat(
                                    title: newTaskText,
                                    gatewayId: app.selectedTeam?.chatGatewayId
                                )
                                newTaskText = ""
                                showsChat = model.selectedChat != nil
                            }
                        }
                    }
                )
            }

            NavigationLink(
                destination: selectedChatDestination,
                isActive: $showsChat
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarHidden(true)
        .accessibilityIdentifier("portal-home")
        .sheet(isPresented: $showsSearch) {
            SearchSheet(model: model) {
                showsSearch = false
                showsChat = true
            }
        }
        .sheet(isPresented: $showsTeamPicker) {
            TeamPickerView(dismissesOnSelection: true, showsDoneButton: true)
                .environmentObject(app)
        }
        .overlay {
            if model.isLoading && model.chats.isEmpty {
                ProgressView("Loading chats")
            } else if let error = model.errorMessage, model.chats.isEmpty {
                ContentUnavailableView(title: "Could not load Portal", message: error)
            }
        }
        .onChange(of: model.selectedChat?.id) { _ in
            if Self.shouldAutoOpenChat, model.selectedChat != nil {
                showsChat = true
            }
        }
        .onAppear {
            if Self.shouldAutoOpenChat, model.selectedChat != nil {
                showsChat = true
            }
        }
    }

    private static var shouldAutoOpenChat: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-open-chat")
    }

    private var header: some View {
        HStack(spacing: 12) {
            Spacer()
            CircleIconButton(systemName: "sun.max") {
                app.preferredScheme = app.preferredScheme == .dark ? nil : .dark
            }
            CircleIconButton(systemName: "magnifyingglass") {
                showsSearch = true
            }
            CircleIconButton(systemName: "gearshape") {
                model.showsSettings = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var selectedChatDestination: some View {
        if let selectedChat = model.selectedChat {
            ChatHostView(summary: selectedChat, gatewayId: app.selectedTeam?.chatGatewayId, app: app)
        } else {
            EmptyChatView()
        }
    }
}

private struct CircleIconButton: View {
    var systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PortalTheme.primaryText)
                .frame(width: 42, height: 42)
                .background(PortalTheme.surface.opacity(0.78))
                .clipShape(Circle())
                .overlay(Circle().stroke(PortalTheme.border.opacity(0.7), lineWidth: 1))
        }
    }
}

private struct ChatHomeCard: View {
    var chat: PortalChatSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(PortalTheme.primaryText)
                        .lineLimit(2)
                    Text(chat.lastMessagePreview.isEmpty ? "No messages yet" : chat.lastMessagePreview)
                        .font(.subheadline)
                        .foregroundStyle(PortalTheme.secondaryText)
                        .lineLimit(2)
                }
                Spacer()
                if chat.isRunning {
                    ProgressView()
                }
            }

            Image(systemName: "envelope.badge")
                .font(.title3)
                .foregroundStyle(Color(red: 0.80, green: 0.18, blue: 0.14))
                .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background(PortalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PortalTheme.border, lineWidth: 1)
        )
    }
}

private struct HomeComposer: View {
    @Binding var text: String
    var officialApps: [PortalOfficialApp]
    var isLoadingMetadata: Bool
    var isBusy: Bool
    var onSubmit: () -> Void
    @State private var showsApps = false
    @State private var showsSkills = false
    @State private var selectedAppIds: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("New task", text: $text)
                .font(.body)
                .submitLabel(.send)
                .onSubmit(onSubmit)

            HStack(spacing: 16) {
                Button { showsApps = true } label: { Image(systemName: "square.grid.2x2") }
                    .accessibilityLabel("Connected apps")
                Button { showsSkills = true } label: { Image(systemName: "wrench.and.screwdriver") }
                    .accessibilityLabel("Skills")
                Button {} label: { Image(systemName: "paperclip") }
                    .accessibilityLabel("Attach")

                Spacer()

                Pill(title: "Standard")

                Button(action: onSubmit) {
                    ZStack {
                        Circle()
                            .fill(PortalTheme.primaryText)
                            .frame(width: 46, height: 46)
                        if isBusy {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "mic.fill" : "arrow.up")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .accessibilityLabel(text.isEmpty ? "Voice" : "Send")
            }
            .font(.title3)
            .foregroundStyle(PortalTheme.primaryText)
        }
        .padding(16)
        .background(PortalTheme.surface.opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .sheet(isPresented: $showsApps) {
            OfficialAppsSheet(
                title: "Connected apps",
                apps: officialApps.filter(\.supportsConnect),
                isLoading: isLoadingMetadata,
                selectedAppIds: $selectedAppIds
            )
        }
        .sheet(isPresented: $showsSkills) {
            OfficialAppsSheet(
                title: "Skills",
                apps: officialApps.filter(\.supportsSkills),
                isLoading: isLoadingMetadata,
                selectedAppIds: $selectedAppIds
            )
        }
    }
}

private struct OfficialAppsSheet: View {
    var title: String
    var apps: [PortalOfficialApp]
    var isLoading: Bool
    @Binding var selectedAppIds: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                if isLoading && apps.isEmpty {
                    ProgressView()
                } else if apps.isEmpty {
                    Text("No apps available")
                        .foregroundStyle(PortalTheme.secondaryText)
                } else {
                    ForEach(apps) { app in
                        Button {
                            toggle(app.id)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                AppIconText(app: app)
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack(spacing: 8) {
                                        Text(app.displayName)
                                            .font(.headline)
                                            .foregroundStyle(PortalTheme.primaryText)
                                        if let category = app.category {
                                            Text(category)
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(PortalTheme.secondaryText)
                                        }
                                    }
                                    Text(app.description)
                                        .font(.subheadline)
                                        .foregroundStyle(PortalTheme.secondaryText)
                                        .lineLimit(3)
                                    HStack(spacing: 10) {
                                        Text("v\(app.version)")
                                        if let count = app.skillCount, count > 0 {
                                            Text("\(count) skills")
                                        }
                                        if app.capabilities?.requiresBrowser == true {
                                            Text("Browser")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(PortalTheme.secondaryText)
                                }
                                Spacer()
                                if selectedAppIds.contains(app.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(PortalTheme.primaryText)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggle(_ id: String) {
        if selectedAppIds.contains(id) {
            selectedAppIds.remove(id)
        } else {
            selectedAppIds.insert(id)
        }
    }
}

private struct AppIconText: View {
    var app: PortalOfficialApp

    var body: some View {
        Text(initials)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(PortalTheme.primaryText)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var initials: String {
        let words = app.displayName.split(separator: " ")
        let letters = words.prefix(2).compactMap(\.first)
        let value = String(letters).uppercased()
        return value.isEmpty ? String(app.id.prefix(2)).uppercased() : value
    }
}

private struct SearchSheet: View {
    @ObservedObject var model: PortalViewModel
    var onSelect: () -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(model.filteredChats) { chat in
                    Button {
                        model.selectedChat = chat
                        onSelect()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chat.title)
                                .font(.headline)
                            Text(chat.lastMessagePreview)
                                .font(.subheadline)
                                .foregroundStyle(PortalTheme.secondaryText)
                        }
                    }
                }
            }
            .searchable(text: $model.query, prompt: "Search")
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ChatHostView: View {
    @StateObject private var model: ChatViewModel

    init(summary: PortalChatSummary, gatewayId: String?, app: AppViewModel) {
        _model = StateObject(
            wrappedValue: ChatViewModel(
                summary: summary,
                gatewayId: gatewayId,
                api: app.apiClient,
                cache: app.cache
            )
        )
    }

    var body: some View {
        ChatDetailView(model: model)
            .id(model.summary.id)
            .task {
                await model.load()
            }
    }
}

private struct EmptyChatView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle)
            Text("Choose or create a chat")
                .font(.headline)
        }
        .foregroundStyle(PortalTheme.secondaryText)
    }
}

private struct ContentUnavailableView: View {
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(PortalTheme.secondaryText)
        }
        .padding(24)
    }
}
