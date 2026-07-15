import SwiftUI

struct AuthView: View {
    @ObservedObject var session: AuthSession
    @ObservedObject var settingsStore: UserDefaultsAppSettingsStore
    @State private var mode: Mode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var backendBaseURL: String
    @State private var heroZoom = false

    init(session: AuthSession, settingsStore: UserDefaultsAppSettingsStore) {
        self.session = session
        self.settingsStore = settingsStore
        _backendBaseURL = State(initialValue: settingsStore.backendBaseURL)
    }

    var body: some View {
        Color.black
            .overlay {
                backgroundImage
            }
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.12), location: 0),
                        .init(color: .black.opacity(0.22), location: 0.38),
                        .init(color: .black.opacity(0.72), location: 0.72),
                        .init(color: .black.opacity(0.9), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    authForm
                        .padding(16)
                        .containerRelativeFrame(.horizontal) { length, _ in
                            max(length - 28, 0)
                        }
                        .background(.black.opacity(0.48))
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.14), lineWidth: 0.75)
                        }
                        .shadow(color: .black.opacity(0.28), radius: 28, x: 0, y: 18)
                }
                .padding(.bottom, 12)
            }
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
            .onAppear {
                withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                    heroZoom = true
                }
            }
    }

    private var backgroundImage: some View {
        AsyncImage(
            url: URL(string: "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=1600"),
            transaction: Transaction(animation: .easeInOut(duration: 0.5))
        ) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            default:
                EditorialFoodArtView()
            }
        }
        .scaleEffect(heroZoom ? 1.06 : 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }

    private var authForm: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("PUMP KITCHEN")
                    .font(DSTypography.micro)
                    .foregroundStyle(DSColor.accent)
                    .tracking(1.4)

                Text("Cook Smarter")
                    .font(.system(size: 31, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)

            authField("Email", systemImage: "at", text: $email, contentType: .emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)

            passwordField

            #if DEBUG
            authField("Backend URL", systemImage: "link", text: $backendBaseURL, contentType: .URL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: backendBaseURL) { _, newValue in
                    settingsStore.backendBaseURL = newValue
                }
            #endif

            if let errorMessage = session.errorMessage {
                Text(LocalizedStringKey(errorMessage))
                    .font(DSTypography.caption)
                    .foregroundStyle(Color(hex: 0xFF7770))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .offset(y: -6)))
            }

            PrimaryButton(
                mode.buttonTitle,
                systemImage: "arrow.right",
                isLoading: session.isLoading
            ) {
                Task {
                    if mode == .login {
                        await session.login(email: email, password: password)
                    } else {
                        await session.register(email: email, password: password)
                    }
                }
            }
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.58)

            #if DEBUG
            Button {
                withAnimation(DSMotion.gentle) {
                    session.continueWithMock()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Demo Mode")
                        .font(DSTypography.body.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(.white.opacity(0.11))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.12), lineWidth: 0.75)
                }
            }
            .buttonStyle(.plain)
            .dsPressable(scale: 0.97)
            .accessibilityIdentifier("auth.demoModeButton")
            #endif

            Button {
                withAnimation(DSMotion.gentle) {
                    mode = mode == .login ? .register : .login
                }
            } label: {
                Text(LocalizedStringKey(mode.secondaryButtonTitle))
                    .font(DSTypography.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .dsPressable(scale: 0.97)
        }
        .animation(DSMotion.gentle, value: mode)
        .animation(DSMotion.gentle, value: session.errorMessage)
    }

    private var passwordField: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.58))
                .frame(width: 20)

            SecureField(
                text: $password,
                prompt: Text("Password").foregroundStyle(.white.opacity(0.58))
            ) {
                Text("Password")
            }
            .textContentType(mode == .login ? .password : .newPassword)
            .foregroundStyle(.white)
            .tint(DSColor.accent)
        }
        .authFieldBackground()
    }

    private var canSubmit: Bool {
        !email.isEmpty && password.count >= 6 && !session.isLoading
    }

    private func authField(
        _ placeholder: String,
        systemImage: String,
        text: Binding<String>,
        contentType: UITextContentType
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.58))
                .frame(width: 20)

            TextField(
                text: text,
                prompt: Text(LocalizedStringKey(placeholder)).foregroundStyle(.white.opacity(0.58))
            ) {
                Text(LocalizedStringKey(placeholder))
            }
            .textContentType(contentType)
            .foregroundStyle(.white)
            .tint(DSColor.accent)
        }
        .authFieldBackground()
    }
}

private enum Mode: String, CaseIterable, Identifiable {
    case login, register

    var id: String { rawValue }
    var buttonTitle: String { self == .login ? "Log In" : "Create Account" }
    var secondaryButtonTitle: String { self == .login ? "Create Account" : "Log In" }
}

private extension View {
    func authFieldBackground() -> some View {
        padding(.horizontal, 15)
            .frame(height: 52)
            .background(.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 0.75)
            }
    }
}
