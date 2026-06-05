import Foundation
import SwiftData

@Model
final class FavoriteRecipeEntity {
    @Attribute(.unique) var recipeID: UUID
    var recipeData: Data
    var createdAt: Date

    init(recipeID: UUID, recipeData: Data, createdAt: Date = .now) {
        self.recipeID = recipeID
        self.recipeData = recipeData
        self.createdAt = createdAt
    }
}

