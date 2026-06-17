import Foundation

struct Recipe: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String?
    let imageURL: URL?
    let cookingTimeMinutes: Int
    let difficulty: String?
    let ingredients: [Ingredient]
    let instructions: [String]
    let nutrition: NutritionInfo
    let tips: [String]
    let tags: [String]

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        imageURL: URL? = nil,
        cookingTimeMinutes: Int,
        difficulty: String? = nil,
        ingredients: [Ingredient],
        instructions: [String],
        nutrition: NutritionInfo,
        tips: [String] = [],
        tags: [String]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.cookingTimeMinutes = cookingTimeMinutes
        self.difficulty = difficulty
        self.ingredients = ingredients
        self.instructions = instructions
        self.nutrition = nutrition
        self.tips = tips
        self.tags = tags
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, description, imageURL, cookingTimeMinutes, difficulty
        case ingredients, instructions, nutrition, tips, tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        cookingTimeMinutes = try container.decode(Int.self, forKey: .cookingTimeMinutes)
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
        ingredients = try container.decode([Ingredient].self, forKey: .ingredients)
        instructions = try container.decode([String].self, forKey: .instructions)
        nutrition = try container.decode(NutritionInfo.self, forKey: .nutrition)
        tips = try container.decodeIfPresent([String].self, forKey: .tips) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}
