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


@MainActor
final class BackendFavoritesRepository: FavoritesRepository {
    private let settingsStore: AppSettingsStore
    private let tokenStore: AuthTokenStore
    private let session: URLSession

    init(settingsStore: AppSettingsStore, tokenStore: AuthTokenStore, session: URLSession = .shared) {
        self.settingsStore = settingsStore
        self.tokenStore = tokenStore
        self.session = session
    }

    func fetchFavorites() async throws -> [Recipe] {
        let data = try await send(path: "recipes/saved", method: "GET")
        return try JSONDecoder().decode([BackendRecipeDTO].self, from: data).map(Recipe.init(backendDTO:))
    }

    func addToFavorites(_ recipe: Recipe) async throws {
        guard let backendID = recipe.backendID else { throw BackendFavoritesError.missingBackendID }
        _ = try await send(path: "recipes/\(backendID)/save", method: "POST")
    }

    func removeFromFavorites(recipeID: UUID) async throws {
        guard let backendID = Recipe(id: recipeID, title: "", cookingTimeMinutes: 0, ingredients: [], instructions: [], nutrition: .init(calories: 0, protein: 0, fats: 0, carbs: 0), tags: []).backendID else {
            throw BackendFavoritesError.missingBackendID
        }
        _ = try await send(path: "recipes/\(backendID)/save", method: "DELETE")
    }

    func isFavorite(recipeID: UUID) async throws -> Bool {
        try await fetchFavorites().contains { $0.id == recipeID }
    }

    private func send(path: String, method: String) async throws -> Data {
        guard let baseURL = URL(string: settingsStore.backendBaseURL) else { throw BackendFavoritesError.invalidURL }
        guard let token = tokenStore.accessToken else { throw BackendFavoritesError.authenticationRequired }
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw BackendFavoritesError.invalidResponse }
        guard (200...299).contains(response.statusCode) else { throw BackendFavoritesError.serverStatus(response.statusCode) }
        return data
    }
}

@MainActor
final class ModeAwareFavoritesRepository: FavoritesRepository {
    private let local: FavoritesRepository
    private let backend: FavoritesRepository
    private let settingsStore: AppSettingsStore
    private let tokenStore: AuthTokenStore

    init(local: FavoritesRepository, backend: FavoritesRepository, settingsStore: AppSettingsStore, tokenStore: AuthTokenStore) {
        self.local = local
        self.backend = backend
        self.settingsStore = settingsStore
        self.tokenStore = tokenStore
    }

    private var active: FavoritesRepository {
        settingsStore.useMockGeneration || tokenStore.accessToken == nil ? local : backend
    }

    func fetchFavorites() async throws -> [Recipe] { try await active.fetchFavorites() }
    func addToFavorites(_ recipe: Recipe) async throws { try await active.addToFavorites(recipe) }
    func removeFromFavorites(recipeID: UUID) async throws { try await active.removeFromFavorites(recipeID: recipeID) }
    func isFavorite(recipeID: UUID) async throws -> Bool { try await active.isFavorite(recipeID: recipeID) }
}

private enum BackendFavoritesError: LocalizedError {
    case invalidURL, authenticationRequired, missingBackendID, invalidResponse, serverStatus(Int)
    var errorDescription: String? {
        switch self {
        case .invalidURL: "Backend URL is invalid."
        case .authenticationRequired: "Login is required to use backend favorites."
        case .missingBackendID: "This recipe is not stored on the backend."
        case .invalidResponse: "Backend returned an invalid response."
        case .serverStatus(let status): "Favorites request failed with status \(status)."
        }
    }
}
