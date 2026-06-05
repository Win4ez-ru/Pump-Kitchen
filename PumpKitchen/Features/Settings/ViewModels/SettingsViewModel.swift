import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var useSystemTheme = true
    @Published var defaultGoal: FitnessGoal
    @Published var heightCentimeters: Double
    @Published var weightKilograms: Double
    @Published var activityLevel: ActivityLevel
    @Published var backendBaseURL: String
    @Published var useMockGeneration: Bool
    @Published var statusMessage: String?

    private let settingsStore: AppSettingsStore

    init(settingsStore: AppSettingsStore) {
        self.settingsStore = settingsStore
        self.defaultGoal = settingsStore.defaultGoal
        self.heightCentimeters = settingsStore.heightCentimeters
        self.weightKilograms = settingsStore.weightKilograms
        self.activityLevel = settingsStore.activityLevel
        self.backendBaseURL = settingsStore.backendBaseURL
        self.useMockGeneration = settingsStore.useMockGeneration
    }

    var isUsingMock: Bool {
        useMockGeneration || backendBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() {
        settingsStore.defaultGoal = defaultGoal
        settingsStore.heightCentimeters = heightCentimeters
        settingsStore.weightKilograms = weightKilograms
        settingsStore.activityLevel = activityLevel
        settingsStore.backendBaseURL = backendBaseURL
        settingsStore.useMockGeneration = useMockGeneration
        backendBaseURL = settingsStore.backendBaseURL
        statusMessage = "Profile saved."
    }
}
