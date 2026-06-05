import Foundation

struct Recipe: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let cookingTimeMinutes: Int
    let ingredients: [Ingredient]
    let instructions: [String]
    let nutrition: NutritionInfo
    let tags: [String]

    init(
        id: UUID = UUID(),
        title: String,
        cookingTimeMinutes: Int,
        ingredients: [Ingredient],
        instructions: [String],
        nutrition: NutritionInfo,
        tags: [String]
    ) {
        self.id = id
        self.title = title
        self.cookingTimeMinutes = cookingTimeMinutes
        self.ingredients = ingredients
        self.instructions = instructions
        self.nutrition = nutrition
        self.tags = tags
    }
}

