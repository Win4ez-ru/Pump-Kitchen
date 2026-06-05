import Foundation
import SwiftData

@MainActor
struct AppContainer {
    let modelContainer: ModelContainer
    let recipeGenerationService: RecipeGenerationService
    let favoritesRepository: FavoritesRepository
    let historyRepository: HistoryRepository
    let settingsStore: AppSettingsStore

    static func live() -> AppContainer {
        do {
            let modelContainer = try ModelContainer(
                for: FavoriteRecipeEntity.self,
                SearchHistoryEntity.self
            )
            let context = modelContainer.mainContext
            let settingsStore = UserDefaultsAppSettingsStore()
            let backendService = BackendRecipeGenerationService(settingsStore: settingsStore)

            return AppContainer(
                modelContainer: modelContainer,
                recipeGenerationService: BackendFallbackRecipeGenerationService(
                    backend: backendService,
                    fallback: MockRecipeGenerationService(),
                    settingsStore: settingsStore
                ),
                favoritesRepository: SwiftDataFavoritesRepository(context: context),
                historyRepository: SwiftDataHistoryRepository(context: context),
                settingsStore: settingsStore
            )
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }
}
