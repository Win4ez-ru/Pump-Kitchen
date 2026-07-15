import Foundation
import Combine

@MainActor
final class RecipeDetailsViewModel: ObservableObject {
    @Published private(set) var recipe: Recipe
    @Published var isFavorite = false
    @Published var isLoadingDetails = false
    @Published var errorMessage: String?
    @Published private(set) var selectedScalingIngredientID: UUID?
    @Published private(set) var scalingFactor: Double = 1
    @Published private(set) var removedIngredientName: String?

    private let favoritesRepository: FavoritesRepository
    private let recipeDetailsService: RecipeDetailsService
    private var originalRecipe: Recipe
    private var editedAmountsByIngredientID: [UUID: String] = [:]
    private var lastRemovalSnapshot: IngredientRemovalSnapshot?

    init(recipe: Recipe, favoritesRepository: FavoritesRepository, recipeDetailsService: RecipeDetailsService) {
        self.recipe = recipe
        self.originalRecipe = recipe
        self.favoritesRepository = favoritesRepository
        self.recipeDetailsService = recipeDetailsService
        self.selectedScalingIngredientID = recipe.ingredients.first(where: { Self.gramValue(from: $0.amount) != nil })?.id
    }

    var selectedScalingIngredient: Ingredient? {
        originalRecipe.ingredients.first { $0.id == selectedScalingIngredientID }
    }

    var scalableIngredients: [Ingredient] {
        originalRecipe.ingredients.filter { Self.gramValue(from: $0.amount) != nil }
    }

    var displayedNutrition: NutritionInfo {
        recipe.nutrition
    }

    func displayedAmount(for ingredient: Ingredient) -> String {
        ingredient.amount
    }

    func amountText(for ingredient: Ingredient) -> String {
        displayedAmount(for: ingredient)
    }

    func updateAmount(_ value: String, for ingredient: Ingredient) {
        editedAmountsByIngredientID[ingredient.id] = value

        guard let originalIngredient = originalRecipe.ingredients.first(where: { $0.id == ingredient.id }) else {
            recipe = recipe.replacingAmount(value, for: ingredient.id)
            return
        }

        if Self.gramValue(from: originalIngredient.amount) == nil, Self.gramValue(from: value) != nil {
            let activeScalingFactor = scalingFactor > 0 ? scalingFactor : 1
            let baselineAmount: String
            if let parts = Self.amountParts(from: value) {
                baselineAmount = Self.formatAmount(parts.number / activeScalingFactor, suffix: parts.suffix)
            } else {
                baselineAmount = value
            }

            originalRecipe = originalRecipe.replacingAmount(baselineAmount, for: ingredient.id)
            selectedScalingIngredientID = ingredient.id
            scalingFactor = activeScalingFactor
            recipe = originalRecipe.scaled(
                by: activeScalingFactor,
                selectedIngredientID: ingredient.id,
                selectedAmountText: value
            )
            return
        }

        guard
            let originalGramAmount = Self.gramValue(from: originalIngredient.amount),
            let editedGramAmount = Self.gramValue(from: value),
            originalGramAmount > 0,
            editedGramAmount >= 0
        else {
            recipe = recipe.replacingAmount(value, for: ingredient.id)
            return
        }

        selectedScalingIngredientID = ingredient.id
        scalingFactor = editedGramAmount / originalGramAmount
        recipe = originalRecipe.scaled(
            by: scalingFactor,
            selectedIngredientID: ingredient.id,
            selectedAmountText: value
        )
    }

    func incrementAmount(for ingredient: Ingredient) {
        adjustAmount(for: ingredient, direction: 1)
    }

    func decrementAmount(for ingredient: Ingredient) {
        adjustAmount(for: ingredient, direction: -1)
    }

    func replaceIngredient(_ ingredient: Ingredient, with substitutionName: String) {
        let cleanedName = substitutionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else { return }

        recipe = recipe.replacingIngredientName(cleanedName, for: ingredient.id)
        originalRecipe = originalRecipe.replacingIngredientName(cleanedName, for: ingredient.id)
    }

    func removeIngredient(_ ingredient: Ingredient) {
        guard recipe.ingredients.contains(where: { $0.id == ingredient.id }) else { return }

        lastRemovalSnapshot = IngredientRemovalSnapshot(
            recipe: recipe,
            originalRecipe: originalRecipe,
            editedAmountsByIngredientID: editedAmountsByIngredientID,
            selectedScalingIngredientID: selectedScalingIngredientID,
            scalingFactor: scalingFactor
        )
        removedIngredientName = ingredient.name

        recipe = recipe.removingIngredient(withID: ingredient.id, recalculatingNutrition: true)
        originalRecipe = originalRecipe.removingIngredient(withID: ingredient.id, recalculatingNutrition: true)
        editedAmountsByIngredientID.removeValue(forKey: ingredient.id)

        if selectedScalingIngredientID == ingredient.id {
            selectedScalingIngredientID = originalRecipe.ingredients.first(where: { Self.gramValue(from: $0.amount) != nil })?.id
            scalingFactor = 1
        }
    }

    func undoLastIngredientRemoval() {
        guard let snapshot = lastRemovalSnapshot else { return }

        recipe = snapshot.recipe
        originalRecipe = snapshot.originalRecipe
        editedAmountsByIngredientID = snapshot.editedAmountsByIngredientID
        selectedScalingIngredientID = snapshot.selectedScalingIngredientID
        scalingFactor = snapshot.scalingFactor
        lastRemovalSnapshot = nil
        removedIngredientName = nil
    }

    func dismissIngredientRemovalUndo() {
        lastRemovalSnapshot = nil
        removedIngredientName = nil
    }

    func load() async {
        do {
            isFavorite = try await favoritesRepository.isFavorite(recipeID: recipe.id)
        } catch {
            errorMessage = UserFacingErrorMessage.storage(error)
        }

        await loadDetailsIfNeeded()
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
            errorMessage = UserFacingErrorMessage.storage(error)
        }
    }

    private func adjustAmount(for ingredient: Ingredient, direction: Double) {
        let currentText = amountText(for: ingredient)
        guard let amount = Self.amountParts(from: currentText) else {
            updateAmount(direction > 0 ? "1" : "0", for: ingredient)
            return
        }

        let step = Self.stepSize(for: amount.suffix)
        let nextValue = max(0, amount.number + step * direction)
        updateAmount(Self.formatAmount(nextValue, suffix: amount.suffix), for: ingredient)
    }

    private func loadDetailsIfNeeded() async {
        guard recipe.needsBackendDetails else { return }
        isLoadingDetails = true
        defer { isLoadingDetails = false }

        do {
            let detailedRecipe = try await recipeDetailsService.recipeDetails(for: recipe)
            applyNewOriginalRecipe(detailedRecipe)
        } catch {
            errorMessage = UserFacingErrorMessage.recipes(error)
        }
    }

    private func applyNewOriginalRecipe(_ newRecipe: Recipe) {
        originalRecipe = newRecipe
        recipe = newRecipe
        editedAmountsByIngredientID = [:]
        lastRemovalSnapshot = nil
        removedIngredientName = nil
        scalingFactor = 1
        selectedScalingIngredientID = newRecipe.ingredients.first(where: { Self.gramValue(from: $0.amount) != nil })?.id
    }

    nonisolated fileprivate static func amountParts(from value: String) -> (number: Double, suffix: String)? {
        let pattern = #"^\s*([0-9]+(?:[\.,][0-9]+)?)(.*)$"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(value.startIndex..., in: value)
        guard let match = expression.firstMatch(in: value, range: range) else {
            return nil
        }

        guard
            let numberRange = Range(match.range(at: 1), in: value),
            let suffixRange = Range(match.range(at: 2), in: value)
        else {
            return nil
        }

        let numberString = value[numberRange].replacingOccurrences(of: ",", with: ".")
        guard let number = Double(numberString) else {
            return nil
        }

        return (number, String(value[suffixRange]))
    }

    nonisolated private static func stepSize(for suffix: String) -> Double {
        let normalizedSuffix = suffix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalizedSuffix.contains("kg") || normalizedSuffix == "l" {
            return 0.1
        }

        if normalizedSuffix.contains("g") || normalizedSuffix.contains("ml") {
            return 10
        }

        if normalizedSuffix.contains("cup") || normalizedSuffix.contains("tbsp") || normalizedSuffix.contains("tsp") {
            return 0.25
        }

        return 1
    }

    nonisolated fileprivate static func formatAmount(_ number: Double, suffix: String) -> String {
        let formattedNumber: String
        if number.rounded() == number {
            formattedNumber = String(Int(number))
        } else {
            formattedNumber = String(format: "%.2f", number)
                .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
        }

        return "\(formattedNumber)\(suffix)"
    }

    nonisolated fileprivate static func gramValue(from value: String) -> Double? {
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

private struct IngredientRemovalSnapshot {
    let recipe: Recipe
    let originalRecipe: Recipe
    let editedAmountsByIngredientID: [UUID: String]
    let selectedScalingIngredientID: UUID?
    let scalingFactor: Double
}

private extension Recipe {
    func scaled(by factor: Double, selectedIngredientID: UUID, selectedAmountText: String) -> Recipe {
        Recipe(
            id: id,
            title: title,
            description: description,
            imageURL: imageURL,
            cookingTimeMinutes: cookingTimeMinutes,
            difficulty: difficulty,
            ingredients: ingredients.map { ingredient in
                let amount: String
                if ingredient.id == selectedIngredientID {
                    amount = selectedAmountText
                } else if let parts = RecipeDetailsViewModel.amountParts(from: ingredient.amount) {
                    amount = RecipeDetailsViewModel.formatAmount(parts.number * factor, suffix: parts.suffix)
                } else {
                    amount = ingredient.amount
                }

                return Ingredient(id: ingredient.id, name: ingredient.name, amount: amount)
            },
            instructions: instructions,
            nutrition: NutritionInfo(
                calories: Int((Double(nutrition.calories) * factor).rounded()),
                protein: nutrition.protein * factor,
                fats: nutrition.fats * factor,
                carbs: nutrition.carbs * factor
            ),
            tips: tips,
            tags: tags
        )
    }

    func removingIngredient(withID ingredientID: UUID, recalculatingNutrition: Bool) -> Recipe {
        let remainingIngredients = ingredients.filter { $0.id != ingredientID }
        let updatedNutrition = recalculatingNutrition
            ? nutrition.scaled(by: remainingIngredientMassRatio(afterRemoving: ingredientID))
            : nutrition

        return Recipe(
            id: id,
            title: title,
            description: description,
            imageURL: imageURL,
            cookingTimeMinutes: cookingTimeMinutes,
            difficulty: difficulty,
            ingredients: remainingIngredients,
            instructions: instructions,
            nutrition: updatedNutrition,
            tips: tips,
            tags: tags
        )
    }

    func replacingAmount(_ amount: String, for ingredientID: UUID) -> Recipe {
        Recipe(
            id: id,
            title: title,
            description: description,
            imageURL: imageURL,
            cookingTimeMinutes: cookingTimeMinutes,
            difficulty: difficulty,
            ingredients: ingredients.map { ingredient in
                guard ingredient.id == ingredientID else { return ingredient }
                return Ingredient(id: ingredient.id, name: ingredient.name, amount: amount)
            },
            instructions: instructions,
            nutrition: nutrition,
            tips: tips,
            tags: tags
        )
    }

    func replacingIngredientName(_ name: String, for ingredientID: UUID) -> Recipe {
        Recipe(
            id: id,
            title: title,
            description: description,
            imageURL: imageURL,
            cookingTimeMinutes: cookingTimeMinutes,
            difficulty: difficulty,
            ingredients: ingredients.map { ingredient in
                guard ingredient.id == ingredientID else { return ingredient }
                return Ingredient(id: ingredient.id, name: name, amount: ingredient.amount)
            },
            instructions: instructions,
            nutrition: nutrition,
            tips: tips,
            tags: tags
        )
    }

    private func remainingIngredientMassRatio(afterRemoving ingredientID: UUID) -> Double {
        let masses = ingredients.compactMap { ingredient -> (id: UUID, grams: Double)? in
            guard let grams = RecipeDetailsViewModel.gramValue(from: ingredient.amount) else {
                return nil
            }

            return (ingredient.id, grams)
        }

        let totalMass = masses.reduce(0) { $0 + $1.grams }
        guard totalMass > 0 else { return 1 }

        let removedMass = masses.first(where: { $0.id == ingredientID })?.grams ?? 0
        return max(0, (totalMass - removedMass) / totalMass)
    }
}

private extension NutritionInfo {
    func scaled(by factor: Double) -> NutritionInfo {
        NutritionInfo(
            calories: Int((Double(calories) * factor).rounded()),
            protein: protein * factor,
            fats: fats * factor,
            carbs: carbs * factor
        )
    }
}

private extension Recipe {
    var needsBackendDetails: Bool {
        backendPathIdentifier != nil && (instructions.isEmpty || nutrition.calories == 0)
    }
}
