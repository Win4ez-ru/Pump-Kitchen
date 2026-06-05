import Foundation
import Combine

@MainActor
final class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []

    func openRecipe(_ recipe: Recipe) {
        path.append(.recipeDetails(recipe))
    }

    func repeatQuery(_ query: RecipeQuery) {
        path.append(.repeatQuery(query))
    }

    func popToRoot() {
        path.removeAll()
    }
}
