import Foundation
import SwiftData

@Model
final class SearchHistoryEntity {
    @Attribute(.unique) var id: UUID
    var ingredients: [String]
    var fitnessGoalRawValue: String?
    var targetProtein: Double?
    var servings: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        ingredients: [String],
        fitnessGoalRawValue: String?,
        targetProtein: Double?,
        servings: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.ingredients = ingredients
        self.fitnessGoalRawValue = fitnessGoalRawValue
        self.targetProtein = targetProtein
        self.servings = servings
        self.createdAt = createdAt
    }
}

