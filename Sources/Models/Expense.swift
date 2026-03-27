import Foundation

struct Expense: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    var notes: String

    init(id: UUID = UUID(), title: String, amount: Double, category: ExpenseCategory, date: Date, notes: String = "") {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
    }
}
