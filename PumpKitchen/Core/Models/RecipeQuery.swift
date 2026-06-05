import Foundation

struct RecipeQuery: Identifiable, Codable, Hashable {
    let id: UUID
    let ingredients: [String]
    let fitnessGoal: FitnessGoal?
    let targetProtein: Double?
    let servings: Int
    let createdAt: Date

    init(
        id: UUID = UUID(),
        ingredients: [String],
        fitnessGoal: FitnessGoal?,
        targetProtein: Double?,
        servings: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.ingredients = ingredients
        self.fitnessGoal = fitnessGoal
        self.targetProtein = targetProtein
        self.servings = servings
        self.createdAt = createdAt
    }
}

