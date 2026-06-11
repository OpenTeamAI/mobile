import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var app: AppViewModel
    @StateObject private var model = AuthViewModel()
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case code
    }

    var body: some View {
        ZStack {
            PortalTheme.background.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer(minLength: 36)

                VStack(spacing: 10) {
                    Image("LaunchLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text("OpenTeam")
                        .font(.title2.weight(.semibold))
                }

                PortalTheme.card {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(model.phase == .email ? "Sign in or sign up" : "Enter your code")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(PortalTheme.primaryText)

                        Text(model.phase == .email ? "Start work with OpenTeam." : "Use the code sent to your email.")
                            .font(.title3)
                            .foregroundStyle(PortalTheme.secondaryText)

                        if model.phase == .email {
                            TextField("you@example.com", text: $model.email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .submitLabel(.continue)
                                .onSubmit { Task { await model.submit(app: app) } }
                                .textFieldStyle(.roundedBorder)
                                .accessibilityIdentifier("auth-email-field")
                        } else {
                            TextField("Code", text: $model.code)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .focused($focusedField, equals: .code)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityIdentifier("auth-code-field")
                        }

                        if let error = model.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task { await model.submit(app: app) }
                        } label: {
                            HStack {
                                if model.isBusy {
                                    ProgressView()
                                }
                                Text(model.phase == .email ? "Continue" : "Sign in")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.isBusy || (model.phase == .email ? model.email.isEmpty : model.code.isEmpty))
                        .accessibilityIdentifier("auth-submit-button")

                        if model.phase == .code {
                            Button("Use a different email") {
                                model.phase = .email
                                model.code = ""
                            }
                            .font(.footnote)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                HStack(spacing: 28) {
                    Text("Privacy")
                    Text("Terms")
                }
                .font(.footnote)
                .foregroundStyle(PortalTheme.secondaryText)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            focusedField = .email
        }
    }
}
