import SwiftUI

struct ComposerView: View {
    @ObservedObject var model: ChatViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Reply...", text: $model.draft)
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit { Task { await model.send() } }
                .accessibilityIdentifier("reply-composer-field")

            HStack(spacing: 16) {
                Button {} label: {
                    Image(systemName: "envelope.badge")
                        .foregroundStyle(Color(red: 0.80, green: 0.18, blue: 0.14))
                }
                .accessibilityLabel("Gmail")

                Button {} label: {
                    Image(systemName: "wrench.and.screwdriver")
                }
                .accessibilityLabel("Skills")

                Button {} label: {
                    Image(systemName: "paperclip")
                }
                .accessibilityLabel("Attach")

                Spacer()

                Menu {
                    Picker("Model", selection: $model.selectedModel) {
                        Text("Standard").tag("Standard")
                        Text("Expert").tag("Expert")
                    }
                    Picker("Speed", selection: $model.selectedSpeed) {
                        Text("Standard").tag("Standard")
                        Text("Fast").tag("Fast")
                    }
                } label: {
                    Pill(title: model.selectedModel)
                }

                Button {
                    Task { await model.send() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(PortalTheme.primaryText)
                            .frame(width: 44, height: 44)
                        Image(systemName: model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "mic.fill" : "arrow.up")
                            .foregroundStyle(.white)
                    }
                }
                .disabled(model.isStreaming)
                .accessibilityLabel(model.draft.isEmpty ? "Voice" : "Send")
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
    }
}
