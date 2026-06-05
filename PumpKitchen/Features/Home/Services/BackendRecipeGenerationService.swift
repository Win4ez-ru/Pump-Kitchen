import Foundation

final class BackendRecipeGenerationService: RecipeGenerationService {
    private let settingsStore: AppSettingsStore
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        settingsStore: AppSettingsStore,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.settingsStore = settingsStore
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    func generateRecipes(request: RecipeGenerationRequest) async throws -> [Recipe] {
        let baseURLString = settingsStore.backendBaseURL
        guard !baseURLString.isEmpty else {
            throw BackendRecipeGenerationError.missingBaseURL
        }

        guard let baseURL = URL(string: baseURLString) else {
            throw BackendRecipeGenerationError.invalidBaseURL
        }

        let endpointURL = baseURL.appending(path: "v1/recipes/generate")
        var urlRequest = URLRequest(url: endpointURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(RecipeGenerationRequestDTO(from: request, settingsStore: settingsStore))

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw BackendRecipeGenerationError.serverMessage(extractErrorMessage(from: data) ?? "Backend returned status \(httpResponse.statusCode).")
        }

        let responseDTO = try decoder.decode(RecipeGenerationResponseDTO.self, from: data)
        return responseDTO.recipes.map(Recipe.init(dto:))
    }

    private func extractErrorMessage(from data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = object["message"] as? String
        else {
            return nil
        }

        return message
    }
}

final class BackendFallbackRecipeGenerationService: RecipeGenerationService {
    private let backend: RecipeGenerationService
    private let fallback: RecipeGenerationService
    private let settingsStore: AppSettingsStore

    init(
        backend: RecipeGenerationService,
        fallback: RecipeGenerationService,
        settingsStore: AppSettingsStore
    ) {
        self.backend = backend
        self.fallback = fallback
        self.settingsStore = settingsStore
    }

    func generateRecipes(request: RecipeGenerationRequest) async throws -> [Recipe] {
        guard !settingsStore.useMockGeneration, !settingsStore.backendBaseURL.isEmpty else {
            return try await fallback.generateRecipes(request: request)
        }

        return try await backend.generateRecipes(request: request)
    }
}

enum BackendRecipeGenerationError: LocalizedError {
    case missingBaseURL
    case invalidBaseURL
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .missingBaseURL:
            "Backend URL is empty. Mock recipes are available until backend is configured."
        case .invalidBaseURL:
            "Backend URL is invalid."
        case .serverMessage(let message):
            message
        }
    }
}

private struct RecipeGenerationRequestDTO: Encodable {
    let ingredients: [String]
    let fitnessGoal: String?
    let profile: ProfileDTO

    init(from request: RecipeGenerationRequest, settingsStore: AppSettingsStore) {
        self.ingredients = request.ingredients
        self.fitnessGoal = request.fitnessGoal?.rawValue
        self.profile = ProfileDTO(
            heightCentimeters: settingsStore.heightCentimeters,
            weightKilograms: settingsStore.weightKilograms,
            activityLevel: settingsStore.activityLevel.rawValue,
            goal: settingsStore.defaultGoal.rawValue
        )
    }
}

private struct ProfileDTO: Encodable {
    let heightCentimeters: Double
    let weightKilograms: Double
    let activityLevel: String
    let goal: String
}

private struct RecipeGenerationResponseDTO: Decodable {
    let recipes: [RecipeDTO]
}

private struct RecipeDTO: Decodable {
    let id: UUID?
    let title: String
    let cookingTimeMinutes: Int
    let ingredients: [IngredientDTO]
    let instructions: [String]
    let nutrition: NutritionDTO
    let tags: [String]
}

private struct IngredientDTO: Decodable {
    let name: String
    let amount: String
}

private struct NutritionDTO: Decodable {
    let calories: Int
    let protein: Double
    let fats: Double
    let carbs: Double
}

private extension Recipe {
    init(dto: RecipeDTO) {
        self.init(
            id: dto.id ?? UUID(),
            title: dto.title,
            cookingTimeMinutes: dto.cookingTimeMinutes,
            ingredients: dto.ingredients.map { Ingredient(name: $0.name, amount: $0.amount) },
            instructions: dto.instructions,
            nutrition: NutritionInfo(
                calories: dto.nutrition.calories,
                protein: dto.nutrition.protein,
                fats: dto.nutrition.fats,
                carbs: dto.nutrition.carbs
            ),
            tags: dto.tags
        )
    }
}
