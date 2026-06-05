import Foundation

struct RecipeGenerationRequest: Codable, Hashable {
    let ingredients: [String]
    let fitnessGoal: FitnessGoal?
    let targetProtein: Double?
    let servings: Int
}

