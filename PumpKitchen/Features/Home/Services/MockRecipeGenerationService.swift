import Foundation

final class MockRecipeGenerationService: RecipeGenerationService {
    func generateRecipes(request: RecipeGenerationRequest) async throws -> [Recipe] {
        try await Task.sleep(for: .milliseconds(650))

        let parsedIngredients = request.ingredients.prefix(5).map(parseIngredient)
        let goalTag = request.fitnessGoal?.title ?? "Flexible"
        let highProteinIngredient = parsedIngredients.first?.name ?? "Chicken"

        return [
            Recipe(
                title: "Tokyo Protein Bowl",
                description: "A clean, savory protein bowl balanced around the ingredients you already have.",
                imageURL: URL(string: "https://images.unsplash.com/photo-1547592180-85f173990554?w=1200"),
                cookingTimeMinutes: 24,
                difficulty: "easy",
                ingredients: parsedIngredients + [
                    Ingredient(name: "Olive oil", amount: "10g"),
                    Ingredient(name: "Soy sauce", amount: "8g"),
                    Ingredient(name: "Sesame", amount: "5g")
                ],
                instructions: [
                    "Prep all ingredients and keep the fixed amount ingredient separate.",
                    "Cook the protein first until golden and juicy.",
                    "Add the remaining ingredients and season lightly.",
                    "Plate in a large bowl and finish with sesame and sauce."
                ],
                nutrition: NutritionInfo(
                    calories: request.fitnessGoal == .fatLoss ? 430 : 620,
                    protein: request.fitnessGoal == .muscleGain ? 48 : 36,
                    fats: 18,
                    carbs: request.fitnessGoal == .fatLoss ? 42 : 68
                ),
                tips: ["Slice ingredients evenly so everything cooks at the same speed.", "Keep the sauce light, then adjust after tasting."],
                tags: ["High Protein", goalTag, "Mock"]
            ),
            Recipe(
                title: "Yuzu Skillet Omelette",
                description: "A soft high-protein omelette for a fast breakfast or light dinner.",
                imageURL: URL(string: "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=1200"),
                cookingTimeMinutes: 16,
                difficulty: "easy",
                ingredients: [
                    Ingredient(name: "Eggs", amount: "150g"),
                    Ingredient(name: highProteinIngredient, amount: "120g"),
                    Ingredient(name: "Greek yogurt", amount: "40g"),
                    Ingredient(name: "Cheese", amount: "20g")
                ],
                instructions: [
                    "Whisk eggs with Greek yogurt until smooth.",
                    "Fold in the main ingredient and cook on low heat.",
                    "Add cheese near the end so it melts gently.",
                    "Rest for two minutes before slicing."
                ],
                nutrition: NutritionInfo(
                    calories: request.fitnessGoal == .muscleGain ? 540 : 390,
                    protein: request.fitnessGoal == .muscleGain ? 44 : 33,
                    fats: 22,
                    carbs: 24
                ),
                tips: ["Cook on low heat for a soft texture.", "Rest the omelette before slicing."],
                tags: ["Fast", "Breakfast", "Mock"]
            ),
            Recipe(
                title: "Minimal Matcha Pasta",
                description: "Comforting pasta with a protein-forward balance and a glossy tomato finish.",
                imageURL: URL(string: "https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=1200"),
                cookingTimeMinutes: 20,
                difficulty: "medium",
                ingredients: [
                    Ingredient(name: "Pasta", amount: request.fitnessGoal == .fatLoss ? "70g" : "100g"),
                    Ingredient(name: highProteinIngredient, amount: "160g"),
                    Ingredient(name: "Tomatoes", amount: "120g"),
                    Ingredient(name: "Olive oil", amount: "8g")
                ],
                instructions: [
                    "Boil pasta until al dente and save a little cooking water.",
                    "Sear the protein and tomatoes in a wide pan.",
                    "Toss pasta with the sauce and loosen with cooking water.",
                    "Serve glossy, clean, and not overcomplicated."
                ],
                nutrition: NutritionInfo(
                    calories: request.fitnessGoal == .fatLoss ? 510 : 710,
                    protein: 42,
                    fats: 16,
                    carbs: request.fitnessGoal == .fatLoss ? 58 : 88
                ),
                tips: ["Save pasta water before draining.", "Finish the pasta in the pan for a glossy sauce."],
                tags: ["Comfort", goalTag, "Mock"]
            )
        ]
    }

    private func parseIngredient(_ rawValue: String) -> Ingredient {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let amountExpression = Self.amountExpression,
            let match = amountExpression.firstMatch(
                in: trimmedValue,
                range: NSRange(trimmedValue.startIndex..., in: trimmedValue)
            )
        else {
            return Ingredient(name: trimmedValue.capitalized, amount: "to taste")
        }

        let amountRange = Range(match.range, in: trimmedValue)
        let amount = amountRange.map { String(trimmedValue[$0]) } ?? "to taste"
        let name = amountRange.map { range in
            trimmedValue.replacingCharacters(in: range, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        } ?? trimmedValue

        return Ingredient(name: name.isEmpty ? trimmedValue.capitalized : name.capitalized, amount: amount.lowercased())
    }

    private static let amountExpression = try? NSRegularExpression(
        pattern: #"\d+(?:[\.,]\d+)?\s*(?:g|gram|grams|kg|ml|l|pcs|piece|pieces)"#,
        options: [.caseInsensitive]
    )
}
