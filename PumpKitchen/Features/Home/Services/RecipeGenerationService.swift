import Foundation

protocol RecipeGenerationService {
    func generateRecipes(request: RecipeGenerationRequest) async throws -> [Recipe]
}

