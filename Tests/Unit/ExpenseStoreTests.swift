import XCTest
@testable import ExpenseFlow

final class ExpenseStoreTests: XCTestCase {
    var sut: ExpenseStore!
    
    override func setUp() {
        super.setUp()
        sut = ExpenseStore()
    }
    
    override func tearDown() {
        super.tearDown()
        sut.clearAll()
        sut = nil
    }
    
    // MARK: - Add Expense Tests
    
    func testAddExpenseWithValidAmount() {
        let expense = Expense(title: "Coffee", amount: 5.50, category: .food, date: Date())
        sut.addExpense(expense)
        
        XCTAssertTrue(sut.expenses.contains(expense))
    }
    
    func testAddExpenseWithZeroAmountFails() {
        let expense = Expense(title: "Invalid", amount: 0, category: .food, date: Date())
        sut.addExpense(expense)
        
        XCTAssertFalse(sut.expenses.contains(expense))
    }
    
    func testAddExpenseWithNegativeAmountFails() {
        let expense = Expense(title: "Invalid", amount: -10, category: .food, date: Date())
        sut.addExpense(expense)
        
        XCTAssertFalse(sut.expenses.contains(expense))
    }
    
    func testAddExpenseAppearsAtTop() {
        let expense1 = Expense(title: "First", amount: 10, category: .food, date: Date())
        let expense2 = Expense(title: "Second", amount: 20, category: .food, date: Date())
        
        sut.addExpense(expense1)
        sut.addExpense(expense2)
        
        XCTAssertEqual(sut.expenses.first?.title, "Second")
    }
    
    // MARK: - Delete Expense Tests
    
    func testDeleteExpense() {
        let expense = Expense(title: "Coffee", amount: 5, category: .food, date: Date())
        sut.addExpense(expense)
        XCTAssertTrue(sut.expenses.contains(expense))
        
        sut.deleteExpense(id: expense.id)
        XCTAssertFalse(sut.expenses.contains(expense))
    }
    
    func testDeleteNonexistentExpense() {
        let initialCount = sut.expenses.count
        sut.deleteExpense(id: UUID())
        
        XCTAssertEqual(sut.expenses.count, initialCount)
    }
    
    // MARK: - Daily Total Tests
    
    func testDailyTotalForSingleDay() {
        let today = Date()
        let expense1 = Expense(title: "Coffee", amount: 5.50, category: .food, date: today)
        let expense2 = Expense(title: "Lunch", amount: 15.00, category: .food, date: today)
        
        sut.addExpense(expense1)
        sut.addExpense(expense2)
        
        let total = sut.dailyTotal(for: today)
        XCTAssertEqual(total, 20.50, accuracy: 0.01)
    }
    
    func testDailyTotalExcludesPreviousDay() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let todayExpense = Expense(title: "Coffee", amount: 5, category: .food, date: today)
        let yesterdayExpense = Expense(title: "Lunch", amount: 15, category: .food, date: yesterday)
        
        sut.addExpense(todayExpense)
        sut.addExpense(yesterdayExpense)
        
        let todayTotal = sut.dailyTotal(for: today)
        XCTAssertEqual(todayTotal, 5, accuracy: 0.01)
    }
    
    func testDailyTotalForEmptyDay() {
        let total = sut.dailyTotal(for: Date())
        XCTAssertEqual(total, 0)
    }
    
    // MARK: - Monthly Total Tests
    
    func testMonthlyTotalForCurrentMonth() {
        let today = Date()
        let expense1 = Expense(title: "Coffee", amount: 5, category: .food, date: today)
        let expense2 = Expense(title: "Lunch", amount: 15, category: .food, date: today)
        
        sut.addExpense(expense1)
        sut.addExpense(expense2)
        
        let total = sut.monthlyTotal(for: today)
        XCTAssertEqual(total, 20, accuracy: 0.01)
    }
    
    func testMonthlyTotalExcludesOtherMonths() {
        let today = Date()
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: today)!
        
        let currentExpense = Expense(title: "Coffee", amount: 5, category: .food, date: today)
        let lastMonthExpense = Expense(title: "Lunch", amount: 15, category: .food, date: lastMonth)
        
        sut.addExpense(currentExpense)
        sut.addExpense(lastMonthExpense)
        
        let currentTotal = sut.monthlyTotal(for: today)
        XCTAssertEqual(currentTotal, 5, accuracy: 0.01)
    }
    
    // MARK: - Total by Category Tests
    
    func testTotalByCategoryForCurrentMonth() {
        let today = Date()
        let foodExpense = Expense(title: "Coffee", amount: 5, category: .food, date: today)
        let transportExpense = Expense(title: "Bus", amount: 2, category: .transport, date: today)
        let anotherFoodExpense = Expense(title: "Lunch", amount: 15, category: .food, date: today)
        
        sut.addExpense(foodExpense)
        sut.addExpense(transportExpense)
        sut.addExpense(anotherFoodExpense)
        
        let totals = sut.totalsByCategory(forMonth: today)
        
        let foodTotal = totals.first { $0.category == .food }?.total ?? 0
        let transportTotal = totals.first { $0.category == .transport }?.total ?? 0
        
        XCTAssertEqual(foodTotal, 20, accuracy: 0.01)
        XCTAssertEqual(transportTotal, 2, accuracy: 0.01)
    }
    
    func testTotalByCategoryExcludesZeroAmounts() {
        let today = Date()
        let expense = Expense(title: "Coffee", amount: 5, category: .food, date: today)
        sut.addExpense(expense)
        
        let totals = sut.totalsByCategory(forMonth: today)
        
        // Should only include .food category, not others
        XCTAssertTrue(totals.allSatisfy { $0.total > 0 })
    }
    
    // MARK: - Recent Expenses Tests
    
    func testRecentExpensesLimitedToDefault() {
        for i in 0..<10 {
            let expense = Expense(title: "Expense \(i)", amount: Double(i), category: .food, date: Date())
            sut.addExpense(expense)
        }
        
        let recent = sut.recentExpenses()
        XCTAssertEqual(recent.count, 6) // Default limit is 6
    }
    
    func testRecentExpensesCustomLimit() {
        for i in 0..<5 {
            let expense = Expense(title: "Expense \(i)", amount: Double(i), category: .food, date: Date())
            sut.addExpense(expense)
        }
        
        let recent = sut.recentExpenses(limit: 3)
        XCTAssertEqual(recent.count, 3)
    }
    
    // MARK: - Data Reset Tests
    
    func testResetToSample() {
        let expense = Expense(title: "Custom", amount: 100, category: .food, date: Date())
        sut.addExpense(expense)
        
        sut.resetToSample()
        
        XCTAssertGreaterThan(sut.expenses.count, 1)
        XCTAssertFalse(sut.expenses.contains(expense))
    }
    
    func testClearAll() {
        let expense = Expense(title: "Test", amount: 10, category: .food, date: Date())
        sut.addExpense(expense)
        XCTAssertGreaterThan(sut.expenses.count, 0)
        
        sut.clearAll()
        
        XCTAssertEqual(sut.expenses.count, 0)
    }
}
