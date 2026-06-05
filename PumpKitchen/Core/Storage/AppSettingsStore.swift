import Foundation

protocol AppSettingsStore: AnyObject {
    var defaultGoal: FitnessGoal { get set }
    var heightCentimeters: Double { get set }
    var weightKilograms: Double { get set }
    var activityLevel: ActivityLevel { get set }
    var backendBaseURL: String { get set }
    var useMockGeneration: Bool { get set }
    var hasCompletedOnboarding: Bool { get set }
}

final class UserDefaultsAppSettingsStore: AppSettingsStore {
    private enum Key {
        static let defaultGoal = "settings.defaultGoal"
        static let heightCentimeters = "settings.heightCentimeters"
        static let weightKilograms = "settings.weightKilograms"
        static let activityLevel = "settings.activityLevel"
        static let backendBaseURL = "settings.backendBaseURL"
        static let useMockGeneration = "settings.useMockGeneration"
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var defaultGoal: FitnessGoal {
        get {
            userDefaults.string(forKey: Key.defaultGoal)
                .flatMap(FitnessGoal.init(rawValue:)) ?? .maintenance
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Key.defaultGoal)
        }
    }

    var heightCentimeters: Double {
        get {
            let value = userDefaults.double(forKey: Key.heightCentimeters)
            return value == 0 ? 175 : value
        }
        set {
            userDefaults.set(newValue, forKey: Key.heightCentimeters)
        }
    }

    var weightKilograms: Double {
        get {
            let value = userDefaults.double(forKey: Key.weightKilograms)
            return value == 0 ? 75 : value
        }
        set {
            userDefaults.set(newValue, forKey: Key.weightKilograms)
        }
    }

    var activityLevel: ActivityLevel {
        get {
            userDefaults.string(forKey: Key.activityLevel)
                .flatMap(ActivityLevel.init(rawValue:)) ?? .moderate
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Key.activityLevel)
        }
    }

    var backendBaseURL: String {
        get {
            userDefaults.string(forKey: Key.backendBaseURL) ?? ""
        }
        set {
            userDefaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Key.backendBaseURL)
        }
    }

    var useMockGeneration: Bool {
        get {
            guard userDefaults.object(forKey: Key.useMockGeneration) != nil else {
                return true
            }
            return userDefaults.bool(forKey: Key.useMockGeneration)
        }
        set {
            userDefaults.set(newValue, forKey: Key.useMockGeneration)
        }
    }

    var hasCompletedOnboarding: Bool {
        get {
            userDefaults.bool(forKey: Key.hasCompletedOnboarding)
        }
        set {
            userDefaults.set(newValue, forKey: Key.hasCompletedOnboarding)
        }
    }
}
