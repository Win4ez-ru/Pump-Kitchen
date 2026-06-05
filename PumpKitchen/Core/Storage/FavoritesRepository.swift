import Foundation
import SwiftData

@MainActor
protocol FavoritesRepository {
    func fetchFavorites() async throws -> [Recipe]
    func addToFavorites(_ recipe: Recipe) async throws
    func removeFromFavorites(recipeID: UUID) async throws
    func isFavorite(recipeID: UUID) async throws -> Bool
}

@MainActor
final class SwiftDataFavoritesRepository: FavoritesRepository {
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(context: ModelContext) {
        self.context = context
    }

    func fetchFavorites() async throws -> [Recipe] {
        let descriptor = FetchDescriptor<FavoriteRecipeEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).compactMap { entity in
            try? decoder.decode(Recipe.self, from: entity.recipeData)
        }
    }

    func addToFavorites(_ recipe: Recipe) async throws {
        guard try await !isFavorite(recipeID: recipe.id) else { return }

        let data = try encoder.encode(recipe)
        context.insert(FavoriteRecipeEntity(recipeID: recipe.id, recipeData: data))
        try context.save()
    }

    func removeFromFavorites(recipeID: UUID) async throws {
        let descriptor = FetchDescriptor<FavoriteRecipeEntity>(
            predicate: #Predicate { $0.recipeID == recipeID }
        )
        for entity in try context.fetch(descriptor) {
            context.delete(entity)
        }
        try context.save()
    }

    func isFavorite(recipeID: UUID) async throws -> Bool {
        var descriptor = FetchDescriptor<FavoriteRecipeEntity>(
            predicate: #Predicate { $0.recipeID == recipeID }
        )
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }
}

