import XCTest
@testable import ExpenseFlow

final class RecurringExpenseStoreTests: XCTestCase {
    var sut: RecurringExpenseStore!
    
    override func setUp() {
        super.setUp()
        sut = RecurringExpenseStore()
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.recurringExpenses")
    }
    
    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.recurringExpenses")
        sut = nil
    }
    
    // MARK: - Add Tests
    
    func testAddRecurringExpense() {
        let recurring = RecurringExpense(
            title: "Netflix",
            amount: 12,
            category: .entertainment,
            frequency: .monthly,
            startDate: Date()
        )
        
        sut.add(recurring)
        
        XCTAssertEqual(sut.recurringExpenses.count, 1)
        XCTAssertEqual(sut.recurringExpenses.first?.title, "Netflix")
    }
    
    func testAddMultipleRecurringExpenses() {
        let recurring1 = RecurringExpense(title: "Rent", amount: 1000, category: .utilities, frequency: .monthly, startDate: Date())
        let recurring2 = RecurringExpense(title: "Spotify", amount: 10, category: .entertainment, frequency: .monthly, startDate: Date())
        
        sut.add(recurring1)
        sut.add(recurring2)
        
        XCTAssertEqual(sut.recurringExpenses.count, 2)
    }
    
    // MARK: - Update Tests
    
    func testUpdateRecurringExpense() {
        var recurring = RecurringExpense(title: "Original", amount: 10, category: .food, frequency: .monthly, startDate: Date())
        sut.add(recurring)
        
        recurring.title = "Updated"
        sut.update(recurring)
        
        XCTAssertEqual(sut.recurringExpenses.first?.title, "Updated")
    }
    
    // MARK: - Delete Tests
    
    func testDeleteRecurringExpenseById() {
        let recurring = RecurringExpense(title: "Test", amount: 10, category: .food, frequency: .monthly, startDate: Date())
        sut.add(recurring)
        
        XCTAssertEqual(sut.recurringExpenses.count, 1)
        
        sut.delete(recurring.id)
        
        XCTAssertEqual(sut.recurringExpenses.count, 0)
    }
    
    func testDeleteRecurringExpenseObject() {
        let recurring = RecurringExpense(title: "Test", amount: 10, category: .food, frequency: .monthly, startDate: Date())
        sut.add(recurring)
        
        sut.delete(recurring)
        
        XCTAssertEqual(sut.recurringExpenses.count, 0)
    }
    
    // MARK: - Get Tests
    
    func testGetRecurringExpenseById() {
        let recurring = RecurringExpense(title: "Test", amount: 10, category: .food, frequency: .monthly, startDate: Date())
        sut.add(recurring)
        
        let retrieved = sut.get(recurring.id)
        
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, "Test")
    }
    
    func testGetNonexistentRecurringExpense() {
        let uuid = UUID()
        let retrieved = sut.get(uuid)
        
        XCTAssertNil(retrieved)
    }
    
    // MARK: - Filtering Tests
    
    func testActiveRecurringExpenses() {
        let active = RecurringExpense(title: "Active", amount: 10, category: .food, frequency: .monthly, startDate: Date(), isActive: true)
        let inactive = RecurringExpense(title: "Inactive", amount: 10, category: .food, frequency: .monthly, startDate: Date(), isActive: false)
        
        sut.add(active)
        sut.add(inactive)
        
        XCTAssertEqual(sut.activeRecurringExpenses.count, 1)
        XCTAssertEqual(sut.activeRecurringExpenses.first?.title, "Active")
    }
    
    func testSubscriptionsFiltering() {
        let subscription = RecurringExpense(title: "Netflix", amount: 12, category: .entertainment, frequency: .monthly, startDate: Date())
        let food = RecurringExpense(title: "Groceries", amount: 50, category: .food, frequency: .monthly, startDate: Date())
        
        sut.add(subscription)
        sut.add(food)
        
        XCTAssertEqual(sut.subscriptions.count, 1)
        XCTAssertEqual(sut.subscriptions.first?.title, "Netflix")
    }
    
    // MARK: - Amount Calculations Tests
    
    func testMonthlyRecurringAmount() {
        let recurring1 = RecurringExpense(title: "Netflix", amount: 12, category: .entertainment, frequency: .monthly, startDate: Date())
        let recurring2 = RecurringExpense(title: "Spotify", amount: 10, category: .entertainment, frequency: .monthly, startDate: Date())
        
        sut.add(recurring1)
        sut.add(recurring2)
        
        let monthlyAmount = sut.monthlyRecurringAmount
        XCTAssertTrue(monthlyAmount > 20)
    }
    
    func testTotalYearlyAmount() {
        let recurring = RecurringExpense(title: "Netflix", amount: 12, category: .entertainment, frequency: .monthly, startDate: Date())
        sut.add(recurring)
        
        let yearlyAmount = sut.totalYearlyAmount
        XCTAssertTrue(yearlyAmount > 140) // Approximately 144 for annual
    }
    
    // MARK: - Due Soon Tests
    
    func testDueSoonWithinOneWeek() {
        let calendar = Calendar.current
        let today = Date()
        let inThreeDays = calendar.date(byAdding: .day, value: 3, to: today)!
        
        let recurring = RecurringExpense(
            title: "Bill",
            amount: 50,
            category: .utilities,
            frequency: .monthly,
            startDate: inThreeDays,
            notificationEnabled: true
        )
        
        sut.add(recurring)
        let dueSoon = sut.dueSoon(days: 7)
        
        XCTAssertEqual(dueSoon.count, 1)
    }
    
    func testDueSoonNotificationsDisabled() {
        let calendar = Calendar.current
        let today = Date()
        let inThreeDays = calendar.date(byAdding: .day, value: 3, to: today)!
        
        let recurring = RecurringExpense(
            title: "Bill",
            amount: 50,
            category: .utilities,
            frequency: .monthly,
            startDate: inThreeDays,
            notificationEnabled: false
        )
        
        sut.add(recurring)
        let dueSoon = sut.dueSoon(days: 7)
        
        XCTAssertEqual(dueSoon.count, 0)
    }
    
    // MARK: - Persistence Tests
    
    func testPersistenceAfterReload() throws {
        let recurring = RecurringExpense(title: "Test", amount: 10, category: .food, frequency: .monthly, startDate: Date())
        sut.add(recurring)
        
        // Wait for auto-save
        let expectation = XCTestExpectation(description: "Persistence")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        
        // Create new instance to test reload
        let newStore = RecurringExpenseStore()
        
        XCTAssertEqual(newStore.recurringExpenses.count, 1)
        XCTAssertEqual(newStore.recurringExpenses.first?.title, "Test")
    }
}
