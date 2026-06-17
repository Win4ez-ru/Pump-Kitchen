import Foundation

enum DietaryPreference: String, Codable, CaseIterable, Identifiable {
    case regular
    case healthy
    case vegetarian
    case vegan
    case lactoseFree
    case glutenFree

    var id: String { rawValue }

    var title: String {
        switch self {
        case .regular: "Regular"
        case .healthy: "Healthy"
        case .vegetarian: "Vegetarian"
        case .vegan: "Vegan"
        case .lactoseFree: "Lactose Free"
        case .glutenFree: "Gluten Free"
        }
    }
}
