import SwiftUI

struct AuthView: View {
    @ObservedObject var session: AuthSession
    @State private var mode: Mode = .login
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            DSColor.ricePaper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.xl) {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Pump Kitchen")
                            .font(DSTypography.largeTitle)
                            .foregroundStyle(DSColor.graphite)
                        Text("Your personal kitchen, powered by what you already have.")
                            .font(DSTypography.body)
                            .foregroundStyle(.secondary)
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            Picker("Mode", selection: $mode) {
                                ForEach(Mode.allCases) { mode in Text(mode.title).tag(mode) }
                            }
                            .pickerStyle(.segmented)

                            if mode == .register {
                                field("Name", text: $name, contentType: .name)
                            }
                            field("Email", text: $email, contentType: .emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                            SecureField("Password", text: $password)
                                .textContentType(mode == .login ? .password : .newPassword)
                                .padding(14)
                                .background(.background.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                            if let errorMessage = session.errorMessage {
                                Text(errorMessage)
                                    .font(DSTypography.caption)
                                    .foregroundStyle(.red)
                            }

                            PrimaryButton(mode.buttonTitle, isLoading: session.isLoading) {
                                Task {
                                    if mode == .login {
                                        await session.login(email: email, password: password)
                                    } else {
                                        await session.register(name: name, email: email, password: password)
                                    }
                                }
                            }
                            .disabled(email.isEmpty || password.count < 6 || session.isLoading)

                            Button("Continue with Mock Recipes") { session.continueWithMock() }
                                .font(DSTypography.body)
                                .foregroundStyle(DSColor.matcha)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    Label("Your AI key stays on the backend. Login token is stored securely in Keychain.", systemImage: "lock.shield.fill")
                        .font(DSTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(DSSpacing.lg)
            }
        }
    }

    private func field(_ placeholder: String, text: Binding<String>, contentType: UITextContentType) -> some View {
        TextField(placeholder, text: text)
            .textContentType(contentType)
            .padding(14)
            .background(.background.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private enum Mode: String, CaseIterable, Identifiable {
    case login, register
    var id: String { rawValue }
    var title: String { self == .login ? "Login" : "Register" }
    var buttonTitle: String { self == .login ? "Login" : "Create Account" }
}
