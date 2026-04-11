import Foundation

struct Expense: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var category: ExpenseCategory
    var customCategoryName: String?
    var customCategoryColorHex: String?
    var date: Date
    var notes: String

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: ExpenseCategory,
        customCategoryName: String? = nil,
        customCategoryColorHex: String? = nil,
        date: Date,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.customCategoryName = customCategoryName
        self.customCategoryColorHex = customCategoryColorHex
        self.date = date
        self.notes = notes
    }
}
