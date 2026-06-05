import Foundation
import Combine

@MainActor
final class RecipeDetailsViewModel: ObservableObject {
    let recipe: Recipe
    @Published var isFavorite = false
    @Published var errorMessage: String?
    @Published var selectedScalingIngredientID: UUID?
    @Published var fixedAmountText = ""

    private let favoritesRepository: FavoritesRepository

    init(recipe: Recipe, favoritesRepository: FavoritesRepository) {
        self.recipe = recipe
        self.favoritesRepository = favoritesRepository
        self.selectedScalingIngredientID = recipe.ingredients.first(where: { Self.gramValue(from: $0.amount) != nil })?.id
    }

    var selectedScalingIngredient: Ingredient? {
        recipe.ingredients.first { $0.id == selectedScalingIngredientID }
    }

    var scalableIngredients: [Ingredient] {
        recipe.ingredients.filter { Self.gramValue(from: $0.amount) != nil }
    }

    var scalingFactor: Double? {
        guard
            let selectedScalingIngredient,
            let originalAmount = Self.gramValue(from: selectedScalingIngredient.amount),
            let fixedAmount = Self.gramValue(from: fixedAmountText),
            originalAmount > 0,
            fixedAmount > 0
        else {
            return nil
        }

        return fixedAmount / originalAmount
    }

    var displayedNutrition: NutritionInfo {
        guard let scalingFactor else {
            return recipe.nutrition
        }

        return NutritionInfo(
            calories: Int((Double(recipe.nutrition.calories) * scalingFactor).rounded()),
            protein: recipe.nutrition.protein * scalingFactor,
            fats: recipe.nutrition.fats * scalingFactor,
            carbs: recipe.nutrition.carbs * scalingFactor
        )
    }

    var scalingHint: String {
        guard let selectedScalingIngredient else {
            return "Choose an ingredient with grams to preview scaling."
        }

        guard scalingFactor != nil else {
            return "Enter how many grams of \(selectedScalingIngredient.name.lowercased()) you have."
        }

        return "Preview only for MVP. Backend will later rebalance taste and macros more precisely."
    }

    func displayedAmount(for ingredient: Ingredient) -> String {
        guard
            let scalingFactor,
            let gramAmount = Self.gramValue(from: ingredient.amount)
        else {
            return ingredient.amount
        }

        return "\(Int((gramAmount * scalingFactor).rounded()))g"
    }

    func load() async {
        do {
            isFavorite = try await favoritesRepository.isFavorite(recipeID: recipe.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite() async {
        do {
            if isFavorite {
                try await favoritesRepository.removeFromFavorites(recipeID: recipe.id)
            } else {
                try await favoritesRepository.addToFavorites(recipe)
            }
            isFavorite.toggle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func gramValue(from value: String) -> Double? {
        let pattern = #"([0-9]+(?:[\.,][0-9]+)?)\s*(g|gram|grams|kg|ml|l)"#
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(value.startIndex..., in: value)
        guard let match = expression.firstMatch(in: value, range: range) else {
            return nil
        }

        guard
            let numberRange = Range(match.range(at: 1), in: value),
            let unitRange = Range(match.range(at: 2), in: value)
        else {
            return nil
        }

        let numberString = value[numberRange].replacingOccurrences(of: ",", with: ".")
        guard let number = Double(numberString) else {
            return nil
        }

        let unit = value[unitRange].lowercased()
        switch unit {
        case "kg", "l":
            return number * 1000
        default:
            return number
        }
    }
}
