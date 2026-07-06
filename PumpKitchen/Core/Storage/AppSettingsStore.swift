import Combine
import Foundation

enum AppConfiguration {
    static var privacyPolicyURL: URL? {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "PrivacyPolicyURL") as? String,
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return URL(string: value)
    }
}

protocol AppSettingsStore: AnyObject {
    var defaultGoal: FitnessGoal { get set }
    var heightCentimeters: Double { get set }
    var weightKilograms: Double { get set }
    var activityLevel: ActivityLevel { get set }
    var dietaryPreference: DietaryPreference { get set }
    var userName: String { get set }
    var allergens: [String] { get set }
    var backendBaseURL: String { get set }
    var useMockGeneration: Bool { get set }
    var hasCompletedOnboarding: Bool { get set }
    var appTheme: AppTheme { get set }
    var appLanguage: AppLanguage { get set }
}

final class UserDefaultsAppSettingsStore: AppSettingsStore, ObservableObject {
    private enum Key {
        static let defaultGoal = "settings.defaultGoal"
        static let heightCentimeters = "settings.heightCentimeters"
        static let weightKilograms = "settings.weightKilograms"
        static let activityLevel = "settings.activityLevel"
        static let dietaryPreference = "settings.dietaryPreference"
        static let userName = "settings.userName"
        static let allergens = "settings.allergens"
        static let backendBaseURL = "settings.backendBaseURL"
        static let useMockGeneration = "settings.useMockGeneration"
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
        static let appTheme = "settings.appTheme"
        static let appLanguage = "settings.appLanguage"
    }
    private static let bundledBackendBaseURL = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String

    let objectWillChange = ObservableObjectPublisher()

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
            objectWillChange.send()
            userDefaults.set(newValue.rawValue, forKey: Key.defaultGoal)
        }
    }

    var heightCentimeters: Double {
        get {
            let value = userDefaults.double(forKey: Key.heightCentimeters)
            return value == 0 ? 175 : value
        }
        set {
            objectWillChange.send()
            userDefaults.set(newValue, forKey: Key.heightCentimeters)
        }
    }

    var weightKilograms: Double {
        get {
            let value = userDefaults.double(forKey: Key.weightKilograms)
            return value == 0 ? 75 : value
        }
        set {
            objectWillChange.send()
            userDefaults.set(newValue, forKey: Key.weightKilograms)
        }
    }

    var activityLevel: ActivityLevel {
        get {
            userDefaults.string(forKey: Key.activityLevel)
                .flatMap(ActivityLevel.init(rawValue:)) ?? .moderate
        }
        set {
            objectWillChange.send()
            userDefaults.set(newValue.rawValue, forKey: Key.activityLevel)
        }
    }

    var dietaryPreference: DietaryPreference {
        get { userDefaults.string(forKey: Key.dietaryPreference).flatMap(DietaryPreference.init(rawValue:)) ?? .regular }
        set {
            objectWillChange.send()
            userDefaults.set(newValue.rawValue, forKey: Key.dietaryPreference)
        }
    }

    var userName: String {
        get { userDefaults.string(forKey: Key.userName) ?? "" }
        set {
            objectWillChange.send()
            userDefaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Key.userName)
        }
    }

    var allergens: [String] {
        get { userDefaults.stringArray(forKey: Key.allergens) ?? [] }
        set {
            objectWillChange.send()
            userDefaults.set(
                newValue
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty },
                forKey: Key.allergens
            )
        }
    }

    var backendBaseURL: String {
        get {
            userDefaults.string(forKey: Key.backendBaseURL) ?? Self.bundledBackendBaseURL ?? ""
        }
        set {
            objectWillChange.send()
            userDefaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Key.backendBaseURL)
        }
    }

    var useMockGeneration: Bool {
        get {
            #if !DEBUG
            return false
            #else
            guard userDefaults.object(forKey: Key.useMockGeneration) != nil else {
                return false
            }
            return userDefaults.bool(forKey: Key.useMockGeneration)
            #endif
        }
        set {
            objectWillChange.send()
            #if DEBUG
            userDefaults.set(newValue, forKey: Key.useMockGeneration)
            #else
            userDefaults.set(false, forKey: Key.useMockGeneration)
            #endif
        }
    }

    var hasCompletedOnboarding: Bool {
        get {
            userDefaults.bool(forKey: Key.hasCompletedOnboarding)
        }
        set {
            objectWillChange.send()
            userDefaults.set(newValue, forKey: Key.hasCompletedOnboarding)
        }
    }

    var appTheme: AppTheme {
        get {
            userDefaults.string(forKey: Key.appTheme)
                .flatMap(AppTheme.init(rawValue:)) ?? .system
        }
        set {
            objectWillChange.send()
            userDefaults.set(newValue.rawValue, forKey: Key.appTheme)
        }
    }

    var appLanguage: AppLanguage {
        get {
            userDefaults.string(forKey: Key.appLanguage)
                .flatMap(AppLanguage.init(rawValue:)) ?? .system
        }
        set {
            objectWillChange.send()
            userDefaults.set(newValue.rawValue, forKey: Key.appLanguage)
        }
    }
}
