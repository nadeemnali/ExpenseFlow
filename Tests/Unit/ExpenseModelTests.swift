import XCTest
@testable import ExpenseFlow

final class ExpenseModelTests: XCTestCase {
    
    // MARK: - Expense Creation Tests
    
    func testExpenseCreation() {
        let date = Date()
        let expense = Expense(
            title: "Coffee",
            amount: 5.50,
            category: .food,
            date: date
        )
        
        XCTAssertEqual(expense.title, "Coffee")
        XCTAssertEqual(expense.amount, 5.50)
        XCTAssertEqual(expense.category, .food)
        XCTAssertEqual(expense.date, date)
    }
    
    // MARK: - Expense ID Tests
    
    func testExpenseHasUniqueID() {
        let expense1 = Expense(title: "Test", amount: 10, category: .food, date: Date())
        let expense2 = Expense(title: "Test", amount: 10, category: .food, date: Date())
        
        XCTAssertNotEqual(expense1.id, expense2.id)
    }
    
    // MARK: - Expense Codable Tests
    
    func testExpenseCanBeEncoded() throws {
        let expense = Expense(title: "Coffee", amount: 5.50, category: .food, date: Date())
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(expense)
        XCTAssertGreaterThan(data.count, 0)
    }
    
    func testExpenseCanBeDecoded() throws {
        let originalExpense = Expense(title: "Coffee", amount: 5.50, category: .food, date: Date())
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalExpense)
        
        let decoder = JSONDecoder()
        let decodedExpense = try decoder.decode(Expense.self, from: data)
        
        XCTAssertEqual(decodedExpense.title, originalExpense.title)
        XCTAssertEqual(decodedExpense.amount, originalExpense.amount)
        XCTAssertEqual(decodedExpense.category, originalExpense.category)
    }
    
    // MARK: - Expense Category Tests
    
    func testAllCategoriesAvailable() {
        let categories: [ExpenseCategory] = [
            .food, .transport, .health, .entertainment,
            .shopping, .utilities, .travel, .other
        ]
        
        for category in categories {
            let expense = Expense(title: "Test", amount: 10, category: category, date: Date())
            XCTAssertEqual(expense.category, category)
        }
    }
    
    func testCategoryIdentifiers() {
        XCTAssertEqual(ExpenseCategory.food.id, "food")
        XCTAssertEqual(ExpenseCategory.transport.id, "transport")
        XCTAssertEqual(ExpenseCategory.health.id, "health")
        XCTAssertEqual(ExpenseCategory.entertainment.id, "entertainment")
        XCTAssertEqual(ExpenseCategory.shopping.id, "shopping")
        XCTAssertEqual(ExpenseCategory.utilities.id, "utilities")
        XCTAssertEqual(ExpenseCategory.travel.id, "travel")
        XCTAssertEqual(ExpenseCategory.other.id, "other")
    }
}
