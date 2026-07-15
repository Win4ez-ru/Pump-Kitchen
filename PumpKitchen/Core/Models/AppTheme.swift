import SwiftUI

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .dark: "Dark"
        case .light: "Light"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system
    case english
    case russian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .english: "English"
        case .russian: "Russian"
        }
    }

    var locale: Locale {
        switch self {
        case .system: .autoupdatingCurrent
        case .english: Locale(identifier: "en")
        case .russian: Locale(identifier: "ru")
        }
    }

    var languageCode: String {
        switch self {
        case .system:
            Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
        case .english:
            "en"
        case .russian:
            "ru"
        }
    }
}
