import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var useSystemTheme = true
    @Published var defaultGoal: FitnessGoal
    @Published var heightCentimeters: Double
    @Published var weightKilograms: Double
    @Published var activityLevel: ActivityLevel
    @Published var dietaryPreference: DietaryPreference
    @Published var backendBaseURL: String
    @Published var useMockGeneration: Bool
    @Published var statusMessage: String?

    private let settingsStore: AppSettingsStore
    let authSession: AuthSession
    private let profileService: ProfileService

    init(settingsStore: AppSettingsStore, authSession: AuthSession, profileService: ProfileService) {
        self.settingsStore = settingsStore
        self.authSession = authSession
        self.profileService = profileService
        self.defaultGoal = settingsStore.defaultGoal
        self.heightCentimeters = settingsStore.heightCentimeters
        self.weightKilograms = settingsStore.weightKilograms
        self.activityLevel = settingsStore.activityLevel
        self.dietaryPreference = settingsStore.dietaryPreference
        self.backendBaseURL = settingsStore.backendBaseURL
        self.useMockGeneration = settingsStore.useMockGeneration
    }

    var isUsingMock: Bool {
        useMockGeneration || backendBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() async {
        settingsStore.defaultGoal = defaultGoal
        settingsStore.heightCentimeters = heightCentimeters
        settingsStore.weightKilograms = weightKilograms
        settingsStore.activityLevel = activityLevel
        settingsStore.dietaryPreference = dietaryPreference
        settingsStore.backendBaseURL = backendBaseURL
        settingsStore.useMockGeneration = useMockGeneration
        if useMockGeneration { authSession.continueWithMock() } else { authSession.useBackend() }
        backendBaseURL = settingsStore.backendBaseURL
        if !useMockGeneration && authSession.isAuthenticated {
            do {
                try await profileService.updateProfile(goal: defaultGoal, diet: dietaryPreference)
                statusMessage = "Profile saved locally and synced with backend."
            } catch {
                statusMessage = "Saved locally. Backend sync failed: \(error.localizedDescription)"
            }
        } else {
            statusMessage = "Profile saved locally."
        }
    }
}
