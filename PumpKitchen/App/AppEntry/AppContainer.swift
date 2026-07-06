import Foundation
import SwiftData

@MainActor
struct AppContainer {
    let modelContainer: ModelContainer
    let recipeGenerationService: RecipeGenerationService
    let recipeDetailsService: RecipeDetailsService
    let favoritesRepository: FavoritesRepository
    let historyRepository: HistoryRepository
    let settingsStore: UserDefaultsAppSettingsStore
    let authSession: AuthSession
    let profileService: ProfileService

    static func live() -> AppContainer {
        do {
            let modelContainer = try ModelContainer(
                for: FavoriteRecipeEntity.self,
                SearchHistoryEntity.self
            )
            let context = modelContainer.mainContext
            let settingsStore = UserDefaultsAppSettingsStore()
            let tokenStore = KeychainAuthTokenStore()
            let authSession = AuthSession(
                service: BackendAuthService(settingsStore: settingsStore),
                tokenStore: tokenStore,
                settingsStore: settingsStore
            )
            let backendService = BackendRecipeGenerationService(settingsStore: settingsStore, tokenStore: tokenStore)
            let backendDetailsService = BackendRecipeDetailsService(settingsStore: settingsStore, tokenStore: tokenStore)
            let localFavorites = SwiftDataFavoritesRepository(context: context)
            let favoritesRepository = ModeAwareFavoritesRepository(
                local: localFavorites,
                backend: BackendFavoritesRepository(settingsStore: settingsStore, tokenStore: tokenStore),
                settingsStore: settingsStore,
                tokenStore: tokenStore
            )
            let profileService = BackendProfileService(settingsStore: settingsStore, tokenStore: tokenStore)

            return AppContainer(
                modelContainer: modelContainer,
                recipeGenerationService: BackendFallbackRecipeGenerationService(
                    backend: backendService,
                    fallback: MockRecipeGenerationService(),
                    settingsStore: settingsStore
                ),
                recipeDetailsService: BackendFallbackRecipeDetailsService(
                    backend: backendDetailsService,
                    fallback: NoopRecipeDetailsService(),
                    settingsStore: settingsStore
                ),
                favoritesRepository: favoritesRepository,
                historyRepository: SwiftDataHistoryRepository(context: context),
                settingsStore: settingsStore,
                authSession: authSession,
                profileService: profileService
            )
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }
}
