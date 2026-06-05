import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var queries: [RecipeQuery] = []
    @Published var errorMessage: String?

    private let historyRepository: HistoryRepository

    init(historyRepository: HistoryRepository) {
        self.historyRepository = historyRepository
    }

    func loadHistory() async {
        do {
            queries = try await historyRepository.fetchHistory()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(query: RecipeQuery) async {
        do {
            try await historyRepository.deleteQuery(id: query.id)
            queries.removeAll { $0.id == query.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
