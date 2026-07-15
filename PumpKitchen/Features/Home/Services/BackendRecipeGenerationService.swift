import Foundation

final class BackendRecipeGenerationService: RecipeGenerationService {
    private let settingsStore: AppSettingsStore
    private let tokenStore: AuthTokenStore
    private let session: URLSession

    init(settingsStore: AppSettingsStore, tokenStore: AuthTokenStore, session: URLSession = .shared) {
        self.settingsStore = settingsStore
        self.tokenStore = tokenStore
        self.session = session
    }

    func generateRecipes(request: RecipeGenerationRequest) async throws -> [Recipe] {
        guard let baseURL = URL(string: settingsStore.backendBaseURL), !settingsStore.backendBaseURL.isEmpty else {
            throw BackendRecipeGenerationError.invalidBaseURL
        }
        guard let token = tokenStore.accessToken else { throw BackendRecipeGenerationError.authenticationRequired }

        guard let url = Self.searchURL(baseURL: baseURL, request: request, settingsStore: settingsStore) else {
            throw BackendRecipeGenerationError.invalidBaseURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        urlRequest.setValue(settingsStore.appLanguage.languageCode, forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await session.data(for: urlRequest)
        guard let response = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200...299).contains(response.statusCode) else {
            throw BackendRecipeGenerationError.serverMessage(Self.errorMessage(from: data) ?? "Recipe generation failed.")
        }
        return try Self.decodeRecipes(from: data)
    }

    private static func searchURL(
        baseURL: URL,
        request: RecipeGenerationRequest,
        settingsStore: AppSettingsStore
    ) -> URL? {
        var components = URLComponents(
            url: baseURL.appending(path: "v1/recipes/search"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = request.ingredients.map {
            URLQueryItem(name: "ingredients", value: $0)
        } + [
            URLQueryItem(name: "goal", value: request.fitnessGoal?.backendValue),
            URLQueryItem(name: "diet", value: settingsStore.dietaryPreference.backendValue)
        ].compactMap { $0.value == nil ? nil : $0 }
        return components?.url
    }

    static func decodeRecipes(from data: Data) throws -> [Recipe] {
        let decoder = JSONDecoder()

        if let fullRecipeDTOs = decodeRecipeList(FullRecipeDTO.self, from: data, decoder: decoder),
           fullRecipeDTOs.contains(where: \.hasFullRecipeContent) {
            return fullRecipeDTOs.prefix(3).map(Recipe.init(fullRecipeDTO:))
        }

        if let searchResultDTOs = decodeRecipeList(RecipeSearchResultDTO.self, from: data, decoder: decoder) {
            return searchResultDTOs.prefix(3).map(Recipe.init(searchResultDTO:))
        }

        return try decoder.decode(BackendRecipeListResponse<FullRecipeDTO>.self, from: data).recipes.prefix(3).map(Recipe.init(fullRecipeDTO:))
    }

    private static func decodeRecipeList<DTO: Decodable>(
        _ type: DTO.Type,
        from data: Data,
        decoder: JSONDecoder
    ) -> [DTO]? {
        if let recipes = try? decoder.decode([DTO].self, from: data) {
            return recipes
        }
        if let response = try? decoder.decode(BackendRecipeListResponse<DTO>.self, from: data) {
            return response.recipes
        }
        return nil
    }

    static func errorMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return object["message"] as? String ?? object["detail"] as? String
    }
}

final class BackendFallbackRecipeGenerationService: RecipeGenerationService {
    private let backend: RecipeGenerationService
    private let fallback: RecipeGenerationService
    private let settingsStore: AppSettingsStore

    init(backend: RecipeGenerationService, fallback: RecipeGenerationService, settingsStore: AppSettingsStore) {
        self.backend = backend
        self.fallback = fallback
        self.settingsStore = settingsStore
    }

    func generateRecipes(request: RecipeGenerationRequest) async throws -> [Recipe] {
        if settingsStore.useMockGeneration { return try await fallback.generateRecipes(request: request) }
        return try await backend.generateRecipes(request: request)
    }
}

protocol RecipeDetailsService {
    func recipeDetails(for recipe: Recipe) async throws -> Recipe
}

final class NoopRecipeDetailsService: RecipeDetailsService {
    func recipeDetails(for recipe: Recipe) async throws -> Recipe {
        recipe
    }
}

final class BackendRecipeDetailsService: RecipeDetailsService {
    private let settingsStore: AppSettingsStore
    private let tokenStore: AuthTokenStore
    private let session: URLSession

    init(settingsStore: AppSettingsStore, tokenStore: AuthTokenStore, session: URLSession = .shared) {
        self.settingsStore = settingsStore
        self.tokenStore = tokenStore
        self.session = session
    }

    func recipeDetails(for recipe: Recipe) async throws -> Recipe {
        guard let baseURL = URL(string: settingsStore.backendBaseURL), !settingsStore.backendBaseURL.isEmpty else {
            throw BackendRecipeGenerationError.invalidBaseURL
        }
        guard let token = tokenStore.accessToken else {
            throw BackendRecipeGenerationError.authenticationRequired
        }
        guard let backendID = recipe.backendPathIdentifier else {
            return recipe
        }

        var request = URLRequest(url: baseURL.appending(path: "v1/recipes/\(backendID)"))
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.setValue(settingsStore.appLanguage.languageCode, forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200...299).contains(response.statusCode) else {
            throw BackendRecipeGenerationError.serverMessage(BackendRecipeGenerationService.errorMessage(from: data) ?? "Recipe details failed.")
        }
        return try Recipe(fullRecipeDTO: JSONDecoder().decode(FullRecipeDTO.self, from: data))
    }
}

final class BackendFallbackRecipeDetailsService: RecipeDetailsService {
    private let backend: RecipeDetailsService
    private let fallback: RecipeDetailsService
    private let settingsStore: AppSettingsStore

    init(backend: RecipeDetailsService, fallback: RecipeDetailsService, settingsStore: AppSettingsStore) {
        self.backend = backend
        self.fallback = fallback
        self.settingsStore = settingsStore
    }

    func recipeDetails(for recipe: Recipe) async throws -> Recipe {
        if settingsStore.useMockGeneration || recipe.backendPathIdentifier == nil {
            return try await fallback.recipeDetails(for: recipe)
        }
        return try await backend.recipeDetails(for: recipe)
    }
}

enum BackendRecipeGenerationError: LocalizedError {
    case invalidBaseURL, authenticationRequired, serverMessage(String)
    var errorDescription: String? {
        switch self {
        case .invalidBaseURL: "Backend URL is invalid."
        case .authenticationRequired: "Login is required to generate recipes."
        case .serverMessage(let message): message
        }
    }
}

private struct BackendRecipeListResponse<DTO: Decodable>: Decodable {
    let recipes: [DTO]

    enum CodingKeys: String, CodingKey {
        case recipes, results, items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recipes = try container.decodeIfPresent([DTO].self, forKey: .recipes)
            ?? container.decodeIfPresent([DTO].self, forKey: .results)
            ?? container.decodeIfPresent([DTO].self, forKey: .items)
            ?? []
    }
}

struct RecipeSearchResultDTO: Decodable {
    let id: BackendRecipeID?
    let spoonacularID: Int?
    let title: String
    let imageURL: URL?
    let usedIngredients: Int?
    let missedIngredients: Int?

    enum CodingKeys: String, CodingKey {
        case id, title
        case spoonacularID = "spoonacular_id"
        case imageURL = "image_url"
        case usedIngredients = "used_ingredients"
        case missedIngredients = "missed_ingredients"
    }
}

struct FullRecipeDTO: Decodable {
    let id: BackendRecipeID?
    let spoonacularID: Int?
    let title: String
    let description: String?
    let imageURL: URL?
    let cookingTimeMinutes: Int
    let difficulty: String?
    let ingredients: [Ingredient]
    let steps: [String]
    let nutrition: NutritionInfo
    let whyFitsGoal: String?
    let tips: [String]
    let tags: [String]
    var hasFullRecipeContent: Bool {
        !ingredients.isEmpty || !steps.isEmpty || nutrition.calories > 0 || nutrition.protein > 0 || nutrition.fats > 0 || nutrition.carbs > 0
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, difficulty, steps, nutrition, ingredients, tips, tags, servings
        case spoonacularID = "spoonacular_id"
        case imageURL = "image_url"
        case cookTime = "cook_time"
        case readyInMinutes = "ready_in_minutes"
        case cookingTimeMinutes
        case ingredientsFull = "ingredients_full"
        case originalIngredients = "original_ingredients"
        case modifiedIngredients = "modified_ingredients"
        case originalSteps = "original_steps"
        case modifiedSteps = "modified_steps"
        case instructions
        case originalNutrition = "original_nutrition"
        case modifiedNutrition = "modified_nutrition"
        case whyFitsGoal = "why_fits_goal"
        case glutenFree = "gluten_free"
        case dairyFree = "dairy_free"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(BackendRecipeID.self, forKey: .id)
        spoonacularID = try container.decodeIfPresent(Int.self, forKey: .spoonacularID)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
        whyFitsGoal = try container.decodeIfPresent(String.self, forKey: .whyFitsGoal)

        if let readyInMinutes = try container.decodeIfPresent(Int.self, forKey: .readyInMinutes) {
            cookingTimeMinutes = readyInMinutes
        } else if let minutes = try container.decodeIfPresent(Int.self, forKey: .cookingTimeMinutes) {
            cookingTimeMinutes = minutes
        } else {
            cookingTimeMinutes = Recipe.minutes(from: try container.decodeIfPresent(String.self, forKey: .cookTime))
        }

        if let ingredientsFull = try? container.decode([String].self, forKey: .ingredientsFull), !ingredientsFull.isEmpty {
            ingredients = ingredientsFull.map(Recipe.parseIngredient)
        } else if let ingredientStrings = try? container.decode([String].self, forKey: .ingredients), !ingredientStrings.isEmpty {
            ingredients = ingredientStrings.map(Recipe.parseIngredient)
        } else if let ingredientDTOs = try? container.decode([FullRecipeIngredientDTO].self, forKey: .ingredients), !ingredientDTOs.isEmpty {
            ingredients = ingredientDTOs.map(\.ingredient)
        } else if let ingredientDTOs = try? container.decode([FullRecipeIngredientDTO].self, forKey: .modifiedIngredients), !ingredientDTOs.isEmpty {
            ingredients = ingredientDTOs.map(\.ingredient)
        } else {
            ingredients = ((try? container.decode([FullRecipeIngredientDTO].self, forKey: .originalIngredients)) ?? []).map(\.ingredient)
        }

        if let flatSteps = try? container.decode([String].self, forKey: .steps), !flatSteps.isEmpty {
            steps = flatSteps
        } else if let flatSteps = try? container.decode([String].self, forKey: .instructions), !flatSteps.isEmpty {
            steps = flatSteps
        } else if let analyzedSteps = try? container.decode([AnalyzedInstructionDTO].self, forKey: .modifiedSteps), !analyzedSteps.isEmpty {
            steps = analyzedSteps.flatMap(\.stepTexts)
        } else {
            steps = ((try? container.decode([AnalyzedInstructionDTO].self, forKey: .originalSteps)) ?? []).flatMap(\.stepTexts)
        }

        let nutritionDTO = try container.decodeIfPresent(BackendNutritionDTO.self, forKey: .nutrition)
            ?? container.decodeIfPresent(BackendNutritionDTO.self, forKey: .modifiedNutrition)
            ?? container.decodeIfPresent(BackendNutritionDTO.self, forKey: .originalNutrition)
        nutrition = BackendNutritionParser(nutrition: nutritionDTO).nutrition

        var resolvedTips = try container.decodeIfPresent([String].self, forKey: .tips) ?? []
        if let whyFitsGoal, !whyFitsGoal.isEmpty {
            resolvedTips.append(whyFitsGoal)
        }
        tips = resolvedTips

        var resolvedTags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        if let difficulty, !difficulty.isEmpty {
            resolvedTags.append(difficulty.capitalized)
        }
        if try container.decodeIfPresent(Bool.self, forKey: .glutenFree) == true {
            resolvedTags.append("Gluten Free")
        }
        if try container.decodeIfPresent(Bool.self, forKey: .dairyFree) == true {
            resolvedTags.append("Dairy Free")
        }
        if let servings = try container.decodeIfPresent(Int.self, forKey: .servings), servings > 0 {
            resolvedTags.append("\(servings) servings")
        }
        tags = Array(Set(resolvedTags)).sorted()
    }
}

enum BackendRecipeID: Decodable {
    case int(Int)
    case uuid(UUID)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
            return
        }
        let stringValue = try container.decode(String.self)
        if let uuid = UUID(uuidString: stringValue) {
            self = .uuid(uuid)
        } else {
            self = .string(stringValue)
        }
    }

    var recipeID: UUID {
        switch self {
        case .int(let value):
            return Recipe.stableUUID(for: value)
        case .uuid(let value):
            return value
        case .string(let value):
            if let intValue = Int(value) {
                return Recipe.stableUUID(for: intValue)
            }
            return UUID(uuidString: value) ?? Recipe.stableUUID(for: value)
        }
    }

    var endpointValue: String {
        switch self {
        case .int(let value):
            return "\(value)"
        case .uuid(let value):
            return value.uuidString
        case .string(let value):
            return value
        }
    }
}

extension Recipe {
    init(searchResultDTO dto: RecipeSearchResultDTO) {
        var tags: [String] = []
        if let usedIngredients = dto.usedIngredients {
            tags.append("\(usedIngredients) used")
        }
        if let missedIngredients = dto.missedIngredients, missedIngredients > 0 {
            tags.append("\(missedIngredients) missing")
        }

        self.init(
            id: dto.id?.recipeID ?? dto.spoonacularID.map(Self.stableUUID(for:)) ?? UUID(),
            title: dto.title,
            description: nil,
            imageURL: dto.imageURL,
            cookingTimeMinutes: 0,
            difficulty: nil,
            ingredients: [],
            instructions: [],
            nutrition: NutritionInfo(calories: 0, protein: 0, fats: 0, carbs: 0),
            tags: tags,
            backendIdentifier: dto.id?.endpointValue ?? dto.spoonacularID.map(String.init)
        )
    }

    init(fullRecipeDTO dto: FullRecipeDTO) {
        self.init(
            id: dto.id?.recipeID ?? dto.spoonacularID.map(Self.stableUUID(for:)) ?? UUID(),
            title: dto.title,
            description: dto.description,
            imageURL: dto.imageURL,
            cookingTimeMinutes: dto.cookingTimeMinutes,
            difficulty: dto.difficulty,
            ingredients: dto.ingredients,
            instructions: dto.steps,
            nutrition: dto.nutrition,
            tips: dto.tips,
            tags: dto.tags,
            backendIdentifier: dto.id?.endpointValue ?? dto.spoonacularID.map(String.init)
        )
    }

    static func stableUUID(for id: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id)) ?? UUID()
    }

    static func stableUUID(for value: String) -> UUID {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return UUID(uuidString: String(format: "00000000-0000-0000-0000-%012llx", hash & 0x0000ffffffffffff)) ?? UUID()
    }

    var backendPathIdentifier: String? {
        backendIdentifier ?? backendID.map(String.init)
    }

    var backendID: Int? {
        guard uuidStringPrefix else { return nil }
        return Int(id.uuidString.suffix(12))
    }

    private var uuidStringPrefix: Bool {
        id.uuidString.hasPrefix("00000000-0000-0000-0000-")
    }

    static func minutes(from value: String?) -> Int {
        guard let value else { return 0 }
        return Int(value.split(whereSeparator: { !$0.isNumber }).first ?? "0") ?? 0
    }

    static func parseIngredient(_ value: String) -> Ingredient {
        let separators = [":", " - ", " – "]
        for separator in separators where value.contains(separator) {
            let parts = value.components(separatedBy: separator)
            return Ingredient(name: parts.first?.trimmingCharacters(in: .whitespaces) ?? value, amount: parts.dropFirst().joined(separator: separator).trimmingCharacters(in: .whitespaces))
        }
        return Ingredient(name: value, amount: "")
    }
}

private struct FullRecipeIngredientDTO: Decodable {
    let name: String
    let original: String?
    let originalName: String?
    let amount: JSONValue?
    let unit: String?

    enum CodingKeys: String, CodingKey {
        case name, original, amount, unit
        case originalName
    }

    var ingredient: Ingredient {
        if let original, !original.isEmpty {
            return Recipe.parseIngredient(original)
        }

        let amountText: String
        if let amount {
            let formattedAmount: String
            switch amount {
            case .int(let value):
                formattedAmount = "\(value)"
            case .double(let value):
                formattedAmount = value.rounded() == value ? String(Int(value)) : String(value)
            case .string(let value):
                formattedAmount = value
            default:
                formattedAmount = ""
            }
            if formattedAmount.isEmpty {
                amountText = unit ?? ""
            } else if let unit, !unit.isEmpty, !formattedAmount.localizedCaseInsensitiveContains(unit) {
                amountText = "\(formattedAmount) \(unit)"
            } else {
                amountText = formattedAmount
            }
        } else {
            amountText = unit ?? ""
        }

        return Ingredient(name: originalName?.nonEmpty ?? name, amount: amountText)
    }
}

private struct AnalyzedInstructionDTO: Decodable {
    let steps: [InstructionStepDTO]

    var stepTexts: [String] {
        steps.map(\.step).filter { !$0.isEmpty }
    }
}

private struct InstructionStepDTO: Decodable {
    let step: String
}

private struct BackendNutritionDTO: Decodable {
    let values: [String: JSONValue]?
    let nutrients: [BackendNutrientDTO]

    enum CodingKeys: String, CodingKey {
        case nutrients
    }

    init(from decoder: Decoder) throws {
        values = try? [String: JSONValue](from: decoder)
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        nutrients = (try? container?.decode([BackendNutrientDTO].self, forKey: .nutrients)) ?? []
    }
}

private struct BackendNutrientDTO: Decodable {
    let name: String
    let amount: Double
}

private struct BackendNutritionParser {
    let calories: Int
    let protein: Double
    let fats: Double
    let carbs: Double

    init(nutrition: BackendNutritionDTO?) {
        calories = Int(Self.number(in: nutrition, keys: ["calories", "kcal", "калории"]))
        protein = Self.number(in: nutrition, keys: ["protein", "proteins", "белки"])
        fats = Self.number(in: nutrition, keys: ["fats", "fat", "жиры"])
        carbs = Self.number(in: nutrition, keys: ["carbs", "carbohydrates", "углеводы"])
    }

    var nutrition: NutritionInfo {
        NutritionInfo(calories: calories, protein: protein, fats: fats, carbs: carbs)
    }

    private static func number(in nutrition: BackendNutritionDTO?, keys: [String]) -> Double {
        guard let nutrition else { return 0 }
        if let nutrient = nutrition.nutrients.first(where: { keys.contains($0.name.lowercased()) }) {
            return nutrient.amount
        }

        guard let values = nutrition.values else { return 0 }
        for (key, value) in values where keys.contains(key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) {
            switch value {
            case .int(let number): return Double(number)
            case .double(let number): return number
            case .string(let string): return Double(string.split(whereSeparator: { !$0.isNumber && $0 != "." }).first ?? "0") ?? 0
            default: continue
            }
        }
        return 0
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
