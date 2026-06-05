import Foundation

struct Ingredient: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let amount: String

    init(id: UUID = UUID(), name: String, amount: String) {
        self.id = id
        self.name = name
        self.amount = amount
    }
}

