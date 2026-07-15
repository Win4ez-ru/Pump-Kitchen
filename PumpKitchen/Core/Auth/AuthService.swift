import Foundation
import OSLog

protocol AuthService {
    func register(email: String, password: String, name: String?) async throws
    func login(email: String, password: String) async throws -> String
}

final class BackendAuthService: AuthService {
    private let settingsStore: AppSettingsStore
    private let session: URLSession

    init(settingsStore: AppSettingsStore, session: URLSession = .shared) {
        self.settingsStore = settingsStore
        self.session = session
    }

    func register(email: String, password: String, name: String?) async throws {
        let url = try endpoint("v1/auth/register")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RegisterRequest(email: email, password: password, name: name?.nilIfEmpty))
        _ = try await send(request)
    }

    func login(email: String, password: String) async throws -> String {
        let url = try endpoint("v1/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "username=\(email.formURLEncoded)&password=\(password.formURLEncoded)".data(using: .utf8)
        let data = try await send(request)
        return try JSONDecoder().decode(TokenResponse.self, from: data).accessToken
    }

    private func endpoint(_ path: String) throws -> URL {
        guard let baseURL = URL(string: settingsStore.backendBaseURL), !settingsStore.backendBaseURL.isEmpty else {
            throw AuthError.invalidBackendURL
        }
        return baseURL.appending(path: path)
    }

    private func send(_ request: URLRequest) async throws -> Data {
        var localizedRequest = request
        localizedRequest.setValue(settingsStore.appLanguage.languageCode, forHTTPHeaderField: "Accept-Language")
        let (data, response) = try await session.data(for: localizedRequest)
        guard let response = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        guard (200...299).contains(response.statusCode) else {
            let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data).detail)
                ?? (try? JSONDecoder().decode(MessageResponse.self, from: data).message)
                ?? "Backend returned an error."
            throw AuthError.server(message)
        }
        return data
    }
}

private struct RegisterRequest: Encodable { let email: String; let password: String; let name: String? }
private struct TokenResponse: Decodable { let accessToken: String; enum CodingKeys: String, CodingKey { case accessToken = "access_token" } }
private struct ErrorResponse: Decodable { let detail: String }
private struct MessageResponse: Decodable { let message: String }

@MainActor
final class AuthSession: ObservableObject {
    @Published private(set) var isAuthenticated: Bool
    @Published private(set) var useMockGeneration: Bool
    @Published private(set) var needsProfileSetup = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: AuthService
    private let tokenStore: AuthTokenStore
    private let settingsStore: AppSettingsStore

    init(service: AuthService, tokenStore: AuthTokenStore, settingsStore: AppSettingsStore) {
        self.service = service
        self.tokenStore = tokenStore
        self.settingsStore = settingsStore
        self.isAuthenticated = tokenStore.accessToken != nil
        self.useMockGeneration = settingsStore.useMockGeneration
    }

    var accessToken: String? { tokenStore.accessToken }

    func login(email: String, password: String) async {
        await perform {
            let token = try await service.login(email: email, password: password)
            try tokenStore.save(accessToken: token)
            settingsStore.useMockGeneration = false
            isAuthenticated = true
            useMockGeneration = false
        }
    }

    func register(name: String? = nil, email: String, password: String) async {
        await perform {
            try await service.register(email: email, password: password, name: name)
            let token = try await service.login(email: email, password: password)
            try tokenStore.save(accessToken: token)
            settingsStore.useMockGeneration = false
            isAuthenticated = true
            useMockGeneration = false
            needsProfileSetup = true
        }
    }

    func continueWithMock() {
        settingsStore.useMockGeneration = true
        isAuthenticated = true
        useMockGeneration = true
        needsProfileSetup = false
        errorMessage = nil
    }

    func useBackend() {
        settingsStore.useMockGeneration = false
        useMockGeneration = false
        isAuthenticated = tokenStore.accessToken != nil
    }

    func logout() {
        try? tokenStore.clear()
        settingsStore.useMockGeneration = false
        isAuthenticated = false
        useMockGeneration = false
        needsProfileSetup = false
    }

    func completeProfileSetup() {
        needsProfileSetup = false
    }

    private func perform(_ operation: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await operation()
        } catch {
            if let tokenStoreError = error as? AuthTokenStoreError {
                LoggerProvider.app.error("\(tokenStoreError.diagnosticsDescription, privacy: .public)")
            } else {
                LoggerProvider.app.error("Auth operation failed: \(error.localizedDescription, privacy: .public)")
            }
            errorMessage = UserFacingErrorMessage.auth(error)
        }
    }
}

enum AuthError: LocalizedError {
    case invalidBackendURL, invalidResponse, server(String)
    var errorDescription: String? {
        switch self {
        case .invalidBackendURL: "Backend URL is invalid."
        case .invalidResponse: "Backend returned an invalid response."
        case .server(let message): message
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
    var formURLEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? self
    }
}
