import Foundation
import Combine

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var errorMessage: String?

    private let favoritesRepository: FavoritesRepository

    init(favoritesRepository: FavoritesRepository) {
        self.favoritesRepository = favoritesRepository
    }

    func loadFavorites() async {
        do {
            recipes = try await favoritesRepository.fetchFavorites()
        } catch {
            errorMessage = UserFacingErrorMessage.storage(error)
        }
    }

    func remove(recipe: Recipe) async {
        do {
            try await favoritesRepository.removeFromFavorites(recipeID: recipe.id)
            recipes.removeAll { $0.id == recipe.id }
        } catch {
            errorMessage = UserFacingErrorMessage.storage(error)
        }
    }
}
