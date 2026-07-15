import XCTest
@testable import Pump_Kitchen

@MainActor
final class RecipeScalingTests: XCTestCase {
    func testUpdatingIngredientAmountScalesRecipeAndNutrition() {
        let recipe = Recipe(
            id: UUID(),
            title: "Rice Bowl",
            cookingTimeMinutes: 20,
            ingredients: [
                Ingredient(id: UUID(), name: "Chicken", amount: "200g"),
                Ingredient(id: UUID(), name: "Rice", amount: "100g"),
                Ingredient(id: UUID(), name: "Salt", amount: "to taste")
            ],
            instructions: ["Cook."],
            nutrition: NutritionInfo(calories: 600, protein: 50, fats: 10, carbs: 70),
            tags: []
        )
        let viewModel = RecipeDetailsViewModel(
            recipe: recipe,
            favoritesRepository: InMemoryFavoritesRepository(),
            recipeDetailsService: NoopRecipeDetailsService()
        )

        viewModel.updateAmount("300g", for: recipe.ingredients[0])

        XCTAssertEqual(viewModel.scalingFactor, 1.5, accuracy: 0.001)
        XCTAssertEqual(viewModel.recipe.ingredients[0].amount, "300g")
        XCTAssertEqual(viewModel.recipe.ingredients[1].amount, "150g")
        XCTAssertEqual(viewModel.recipe.ingredients[2].amount, "to taste")
        XCTAssertEqual(viewModel.displayedNutrition.calories, 900)
        XCTAssertEqual(viewModel.displayedNutrition.protein, 75, accuracy: 0.001)
        XCTAssertEqual(viewModel.displayedNutrition.fats, 15, accuracy: 0.001)
        XCTAssertEqual(viewModel.displayedNutrition.carbs, 105, accuracy: 0.001)
    }

    func testFirstGramInputForToTasteIngredientJoinsScalingDraft() {
        let saltID = UUID()
        let recipe = Recipe(
            id: UUID(),
            title: "Soup",
            cookingTimeMinutes: 30,
            ingredients: [
                Ingredient(name: "Chicken", amount: "200g"),
                Ingredient(id: saltID, name: "Salt", amount: "to taste")
            ],
            instructions: [],
            nutrition: NutritionInfo(calories: 400, protein: 35, fats: 8, carbs: 40),
            tags: []
        )
        let viewModel = RecipeDetailsViewModel(
            recipe: recipe,
            favoritesRepository: InMemoryFavoritesRepository(),
            recipeDetailsService: NoopRecipeDetailsService()
        )

        viewModel.updateAmount("5g", for: recipe.ingredients[1])
        viewModel.updateAmount("10g", for: viewModel.recipe.ingredients.first { $0.id == saltID }!)

        XCTAssertEqual(viewModel.recipe.ingredients.first { $0.id == saltID }?.amount, "10g")
        XCTAssertEqual(viewModel.scalingFactor, 2, accuracy: 0.001)
        XCTAssertEqual(viewModel.displayedNutrition.calories, 800)
    }
}

@MainActor
private final class InMemoryFavoritesRepository: FavoritesRepository {
    private var recipes: [Recipe] = []

    func fetchFavorites() async throws -> [Recipe] { recipes }
    func addToFavorites(_ recipe: Recipe) async throws { recipes.append(recipe) }
    func removeFromFavorites(recipeID: UUID) async throws { recipes.removeAll { $0.id == recipeID } }
    func isFavorite(recipeID: UUID) async throws -> Bool { recipes.contains { $0.id == recipeID } }
}
