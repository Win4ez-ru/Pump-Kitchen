import Foundation

enum FitnessGoal: String, Codable, CaseIterable, Identifiable {
    case muscleGain
    case fatLoss
    case maintenance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .muscleGain:
            "Mass Gain"
        case .fatLoss:
            "Fat Loss"
        case .maintenance:
            "Maintenance"
        }
    }
}

