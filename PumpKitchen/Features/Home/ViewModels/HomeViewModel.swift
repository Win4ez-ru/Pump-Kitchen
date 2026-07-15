import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var ingredientInput = ""
    @Published var ingredients: [String]
    @Published var frequentIngredients: [String] = []
    @Published var state: LoadableState<[Recipe]> = .idle

    let popularIngredients = [
        "Chicken",
        "Eggs",
        "Pasta",
        "Rice",
        "Tomatoes",
        "Greek yogurt",
        "Cheese",
        "Tuna"
    ]

    private let recipeGenerationService: RecipeGenerationService
    private let historyRepository: HistoryRepository
    private let settingsStore: AppSettingsStore

    init(
        recipeGenerationService: RecipeGenerationService,
        historyRepository: HistoryRepository,
        settingsStore: AppSettingsStore,
        initialQuery: RecipeQuery? = nil
    ) {
        self.recipeGenerationService = recipeGenerationService
        self.historyRepository = historyRepository
        self.settingsStore = settingsStore
        self.ingredients = initialQuery?.ingredients ?? []
    }

    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }

    var canAddIngredient: Bool {
        !normalizedIngredientInput.isEmpty
    }

    var canGenerate: Bool {
        !ingredients.isEmpty && !isLoading
    }

    func isIngredientSelected(_ ingredient: String) -> Bool {
        ingredients.contains { $0.caseInsensitiveCompare(ingredient) == .orderedSame }
    }

    func loadFrequentIngredients() async {
        do {
            let history = try await historyRepository.fetchHistory()
            let countedIngredients = history
                .flatMap(\.ingredients)
                .map(normalizedIngredient)
                .filter { !$0.isEmpty }
                .reduce(into: [String: Int]()) { result, ingredient in
                    result[ingredient, default: 0] += 1
                }

            frequentIngredients = countedIngredients
                .sorted { lhs, rhs in
                    if lhs.value == rhs.value {
                        return lhs.key < rhs.key
                    }
                    return lhs.value > rhs.value
                }
                .map(\.key)
                .filter { ingredient in
                    !popularIngredients.contains { $0.caseInsensitiveCompare(ingredient) == .orderedSame }
                }
                .prefix(8)
                .map { $0 }
        } catch {
            frequentIngredients = []
        }
    }

    func addIngredient() {
        let parsedIngredients = Validation.parseIngredients(from: ingredientInput)
        addIngredients(parsedIngredients)
        ingredientInput = ""
    }

    func addQuickIngredient(_ ingredient: String) {
        addIngredients([ingredient])
    }

    func toggleQuickIngredient(_ ingredient: String) {
        if let selected = ingredients.first(where: { $0.caseInsensitiveCompare(ingredient) == .orderedSame }) {
            removeIngredient(selected)
        } else {
            addQuickIngredient(ingredient)
        }
    }

    func removeIngredient(_ ingredient: String) {
        ingredients.removeAll { $0.caseInsensitiveCompare(ingredient) == .orderedSame }
    }

    func generateRecipes() async {
        addIngredient()

        guard !ingredients.isEmpty else {
            state = .failed("Add at least one ingredient.")
            return
        }

        state = .loading

        // The backend only accepts English ingredient names, so user input is
        // translated locally before the request. History keeps the original text.
        let request = RecipeGenerationRequest(
            ingredients: ingredients.map(IngredientTranslator.searchTerm(for:)),
            fitnessGoal: settingsStore.defaultGoal,
            targetProtein: nil,
            servings: 1
        )

        do {
            let recipes = try await recipeGenerationService.generateRecipes(request: request)
            let query = RecipeQuery(
                ingredients: ingredients,
                fitnessGoal: settingsStore.defaultGoal,
                targetProtein: nil,
                servings: 1
            )
            try await historyRepository.saveQuery(query)
            await loadFrequentIngredients()
            state = .loaded(recipes)
        } catch {
            state = .failed(UserFacingErrorMessage.recipes(error))
        }
    }

    private var normalizedIngredientInput: String {
        normalizedIngredient(ingredientInput)
    }

    private func addIngredients(_ values: [String]) {
        let normalizedIngredients = values.map(normalizedIngredient)

        for ingredient in normalizedIngredients where !ingredient.isEmpty {
            guard !ingredients.contains(where: { $0.caseInsensitiveCompare(ingredient) == .orderedSame }) else {
                continue
            }
            ingredients.append(ingredient)
        }
    }

    private func normalizedIngredient(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
