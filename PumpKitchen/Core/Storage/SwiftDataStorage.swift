import SwiftData

enum SwiftDataStorage {
    static let schema = Schema([
        FavoriteRecipeEntity.self,
        SearchHistoryEntity.self
    ])
}

