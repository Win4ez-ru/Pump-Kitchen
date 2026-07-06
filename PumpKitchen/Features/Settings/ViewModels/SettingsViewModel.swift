import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var appTheme: AppTheme
    @Published var appLanguage: AppLanguage
    @Published var defaultGoal: FitnessGoal
    @Published var heightCentimeters: Double
    @Published var weightKilograms: Double
    @Published var activityLevel: ActivityLevel
    @Published var dietaryPreference: DietaryPreference
    @Published var displayName: String
    @Published var allergens: [String]
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
        self.appTheme = settingsStore.appTheme
        self.appLanguage = settingsStore.appLanguage
        self.defaultGoal = settingsStore.defaultGoal
        self.heightCentimeters = settingsStore.heightCentimeters
        self.weightKilograms = settingsStore.weightKilograms
        self.activityLevel = settingsStore.activityLevel
        self.dietaryPreference = settingsStore.dietaryPreference
        self.displayName = settingsStore.userName
        self.allergens = settingsStore.allergens
        self.backendBaseURL = settingsStore.backendBaseURL
        self.useMockGeneration = settingsStore.useMockGeneration
    }

    var isUsingMock: Bool {
        useMockGeneration || backendBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var authStateTitle: String {
        if useMockGeneration {
            return "Mock session"
        }

        return authSession.isAuthenticated ? "Backend authenticated" : "Signed out"
    }

    var connectionModeID: String {
        get { useMockGeneration ? "mock" : "backend" }
        set { useMockGeneration = newValue == "mock" }
    }

    func setTheme(_ theme: AppTheme) {
        appTheme = theme
        settingsStore.appTheme = theme
    }

    func setLanguage(_ language: AppLanguage) {
        appLanguage = language
        settingsStore.appLanguage = language
    }

    func setDiet(_ diet: DietaryPreference) async {
        dietaryPreference = diet
        settingsStore.dietaryPreference = diet

        guard !useMockGeneration, authSession.isAuthenticated else { return }
        try? await profileService.updateProfile(goal: defaultGoal, diet: diet, name: displayName, allergens: allergens)
    }

    func addAllergen(_ value: String) {
        let allergen = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !allergen.isEmpty else { return }
        guard !allergens.contains(where: { $0.caseInsensitiveCompare(allergen) == .orderedSame }) else { return }
        allergens.append(allergen)
    }

    func removeAllergen(_ value: String) {
        allergens.removeAll { $0 == value }
    }

    func save() async {
        settingsStore.appTheme = appTheme
        settingsStore.appLanguage = appLanguage
        settingsStore.defaultGoal = defaultGoal
        settingsStore.heightCentimeters = heightCentimeters
        settingsStore.weightKilograms = weightKilograms
        settingsStore.activityLevel = activityLevel
        settingsStore.dietaryPreference = dietaryPreference
        settingsStore.userName = displayName
        settingsStore.allergens = allergens
        settingsStore.backendBaseURL = backendBaseURL
        settingsStore.useMockGeneration = useMockGeneration
        if useMockGeneration { authSession.continueWithMock() } else { authSession.useBackend() }
        backendBaseURL = settingsStore.backendBaseURL
        if useMockGeneration {
            statusMessage = "Settings saved. Demo mode active."
        } else if authSession.isAuthenticated {
            do {
                try await profileService.updateProfile(
                    goal: defaultGoal,
                    diet: dietaryPreference,
                    name: displayName,
                    allergens: allergens
                )
                statusMessage = "Profile saved locally and synced with backend."
            } catch {
                statusMessage = UserFacingErrorMessage.profileSync(error)
            }
        } else {
            statusMessage = "Settings saved. Sign in to sync with backend."
        }
    }

    func logout() {
        authSession.useBackend()
        authSession.logout()
        useMockGeneration = false
        settingsStore.useMockGeneration = false
        statusMessage = "Signed out"
    }
}
