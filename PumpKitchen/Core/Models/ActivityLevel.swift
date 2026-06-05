import Foundation

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case low
    case moderate
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:
            "Low"
        case .moderate:
            "Moderate"
        case .high:
            "High"
        }
    }
}
