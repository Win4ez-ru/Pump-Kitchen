import Foundation

protocol ProfileService {
    func updateProfile(goal: FitnessGoal, diet: DietaryPreference) async throws
}

final class BackendProfileService: ProfileService {
    private let settingsStore: AppSettingsStore
    private let tokenStore: AuthTokenStore
    private let session: URLSession

    init(settingsStore: AppSettingsStore, tokenStore: AuthTokenStore, session: URLSession = .shared) {
        self.settingsStore = settingsStore
        self.tokenStore = tokenStore
        self.session = session
    }

    func updateProfile(goal: FitnessGoal, diet: DietaryPreference) async throws {
        guard let baseURL = URL(string: settingsStore.backendBaseURL) else { throw ProfileServiceError.invalidURL }
        guard let token = tokenStore.accessToken else { throw ProfileServiceError.authenticationRequired }

        var request = URLRequest(url: baseURL.appending(path: "auth/me/profile"))
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.httpBody = try JSONEncoder().encode(ProfileUpdateRequest(goal: goal.backendValue, diet: diet.backendValue))

        let (_, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw ProfileServiceError.invalidResponse }
        guard (200...299).contains(response.statusCode) else { throw ProfileServiceError.serverStatus(response.statusCode) }
    }
}

private struct ProfileUpdateRequest: Encodable {
    let goal: String
    let diet: String
}

private enum ProfileServiceError: LocalizedError {
    case invalidURL, authenticationRequired, invalidResponse, serverStatus(Int)
    var errorDescription: String? {
        switch self {
        case .invalidURL: "Backend URL is invalid."
        case .authenticationRequired: "Login is required to update your backend profile."
        case .invalidResponse: "Backend returned an invalid response."
        case .serverStatus(let status): "Profile update failed with status \(status)."
        }
    }
}

extension FitnessGoal {
    var backendValue: String {
        switch self {
        case .fatLoss: "lose_weight"
        case .muscleGain: "gain_muscle"
        case .maintenance: "maintenance"
        }
    }
}

extension DietaryPreference {
    var backendValue: String {
        switch self {
        case .regular: "regular"
        case .healthy: "healthy"
        case .vegetarian: "vegetarian"
        case .vegan: "vegan"
        case .lactoseFree: "lactose_free"
        case .glutenFree: "gluten_free"
        }
    }
}
