import SwiftData
import XCTest
@testable import Pump_Kitchen

@MainActor
final class RepositoryTests: XCTestCase {
    func testFavoritesRepositoryAddsFetchesAndRemovesRecipes() async throws {
        let container = try makeContainer()
        let repository = SwiftDataFavoritesRepository(context: container.mainContext)
        let recipe = makeRecipe(title: "Favorite Bowl")

        try await repository.addToFavorites(recipe)
        try await repository.addToFavorites(recipe)

        let isFavorite = try await repository.isFavorite(recipeID: recipe.id)
        let favoriteTitles = try await repository.fetchFavorites().map(\.title)
        XCTAssertTrue(isFavorite)
        XCTAssertEqual(favoriteTitles, ["Favorite Bowl"])

        try await repository.removeFromFavorites(recipeID: recipe.id)

        let isFavoriteAfterRemoval = try await repository.isFavorite(recipeID: recipe.id)
        let favoritesAfterRemoval = try await repository.fetchFavorites()
        XCTAssertFalse(isFavoriteAfterRemoval)
        XCTAssertEqual(favoritesAfterRemoval, [])
    }

    func testHistoryRepositorySavesFetchesAndDeletesQueries() async throws {
        let container = try makeContainer()
        let repository = SwiftDataHistoryRepository(context: container.mainContext)
        let query = RecipeQuery(
            id: UUID(),
            ingredients: ["chicken", "rice"],
            fitnessGoal: .muscleGain,
            targetProtein: 45,
            servings: 2,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        try await repository.saveQuery(query)

        let savedQueries = try await repository.fetchHistory()
        XCTAssertEqual(savedQueries.count, 1)
        XCTAssertEqual(savedQueries[0].id, query.id)
        XCTAssertEqual(savedQueries[0].ingredients, ["chicken", "rice"])
        XCTAssertEqual(savedQueries[0].fitnessGoal, .muscleGain)
        XCTAssertEqual(savedQueries[0].targetProtein, 45)
        XCTAssertEqual(savedQueries[0].servings, 2)

        try await repository.deleteQuery(id: query.id)

        let historyAfterDeletion = try await repository.fetchHistory()
        XCTAssertEqual(historyAfterDeletion, [])
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: FavoriteRecipeEntity.self,
            SearchHistoryEntity.self,
            configurations: configuration
        )
    }

    private func makeRecipe(title: String) -> Recipe {
        Recipe(
            id: UUID(),
            title: title,
            cookingTimeMinutes: 20,
            ingredients: [Ingredient(name: "Chicken", amount: "200g")],
            instructions: ["Cook."],
            nutrition: NutritionInfo(calories: 500, protein: 45, fats: 12, carbs: 50),
            tags: ["High Protein"]
        )
    }
}
