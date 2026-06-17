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

        var urlRequest = URLRequest(url: baseURL.appending(path: "recipes/generate"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        urlRequest.httpBody = try JSONEncoder().encode(RecipeRequestDTO(ingredients: request.ingredients))

        let (data, response) = try await session.data(for: urlRequest)
        guard let response = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200...299).contains(response.statusCode) else {
            throw BackendRecipeGenerationError.serverMessage(Self.errorMessage(from: data) ?? "Backend returned status \(response.statusCode).")
        }
        return try JSONDecoder().decode([BackendRecipeDTO].self, from: data).map(Recipe.init(backendDTO:))
    }

    private static func errorMessage(from data: Data) -> String? {
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

private struct RecipeRequestDTO: Encodable { let ingredients: [String] }

struct BackendRecipeDTO: Decodable {
    let id: Int
    let title: String
    let description: String?
    let imageURL: URL?
    let cookTime: String?
    let difficulty: String?
    let ingredientsFull: [String]
    let steps: [String]
    let nutrition: [String: JSONValue]?
    let whyFitsGoal: String?
    let tips: [String]?

    enum CodingKeys: String, CodingKey {
        case id, title, description, difficulty, steps, nutrition, tips
        case imageURL = "image_url"
        case cookTime = "cook_time"
        case ingredientsFull = "ingredients_full"
        case whyFitsGoal = "why_fits_goal"
    }
}

extension Recipe {
    init(backendDTO dto: BackendRecipeDTO) {
        let parsedNutrition = BackendNutritionParser(values: dto.nutrition)
        self.init(
            id: Self.stableUUID(for: dto.id),
            title: dto.title,
            description: dto.description,
            imageURL: dto.imageURL,
            cookingTimeMinutes: Self.minutes(from: dto.cookTime),
            difficulty: dto.difficulty,
            ingredients: dto.ingredientsFull.map(Self.parseIngredient),
            instructions: dto.steps,
            nutrition: NutritionInfo(
                calories: parsedNutrition.calories,
                protein: parsedNutrition.protein,
                fats: parsedNutrition.fats,
                carbs: parsedNutrition.carbs
            ),
            tips: dto.tips ?? [dto.whyFitsGoal].compactMap { $0 }.filter { !$0.isEmpty },
            tags: [dto.difficulty].compactMap { $0 }.filter { !$0.isEmpty }
        )
    }

    static func stableUUID(for id: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id)) ?? UUID()
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

private struct BackendNutritionParser {
    let calories: Int
    let protein: Double
    let fats: Double
    let carbs: Double

    init(values: [String: JSONValue]?) {
        calories = Int(Self.number(in: values, keys: ["calories", "kcal", "калории"]))
        protein = Self.number(in: values, keys: ["protein", "proteins", "белки"])
        fats = Self.number(in: values, keys: ["fats", "fat", "жиры"])
        carbs = Self.number(in: values, keys: ["carbs", "carbohydrates", "углеводы"])
    }

    private static func number(in values: [String: JSONValue]?, keys: [String]) -> Double {
        guard let values else { return 0 }
        for (key, value) in values where keys.contains(key.lowercased()) {
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
