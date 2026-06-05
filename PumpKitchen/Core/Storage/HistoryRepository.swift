import Foundation
import SwiftData

@MainActor
protocol HistoryRepository {
    func fetchHistory() async throws -> [RecipeQuery]
    func saveQuery(_ query: RecipeQuery) async throws
    func deleteQuery(id: UUID) async throws
}

@MainActor
final class SwiftDataHistoryRepository: HistoryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchHistory() async throws -> [RecipeQuery] {
        let descriptor = FetchDescriptor<SearchHistoryEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        return try context.fetch(descriptor).map { entity in
            RecipeQuery(
                id: entity.id,
                ingredients: entity.ingredients,
                fitnessGoal: entity.fitnessGoalRawValue.flatMap(FitnessGoal.init(rawValue:)),
                targetProtein: entity.targetProtein,
                servings: entity.servings,
                createdAt: entity.createdAt
            )
        }
    }

    func saveQuery(_ query: RecipeQuery) async throws {
        context.insert(
            SearchHistoryEntity(
                id: query.id,
                ingredients: query.ingredients,
                fitnessGoalRawValue: query.fitnessGoal?.rawValue,
                targetProtein: query.targetProtein,
                servings: query.servings,
                createdAt: query.createdAt
            )
        )
        try context.save()
    }

    func deleteQuery(id: UUID) async throws {
        let descriptor = FetchDescriptor<SearchHistoryEntity>(
            predicate: #Predicate { $0.id == id }
        )
        for entity in try context.fetch(descriptor) {
            context.delete(entity)
        }
        try context.save()
    }
}

