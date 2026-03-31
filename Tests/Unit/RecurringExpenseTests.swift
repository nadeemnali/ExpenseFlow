import XCTest
@testable import ExpenseFlow

final class RecurringExpenseTests: XCTestCase {
    
    // MARK: - Next Due Date Tests
    
    func testNextDueDateFromStartDate() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let recurring = RecurringExpense(
            title: "Rent",
            amount: 1000,
            category: .utilities,
            frequency: .monthly,
            startDate: startDate
        )
        
        let nextDue = recurring.nextDueDate()
        let calendar = Calendar.current
        
        XCTAssertTrue(calendar.isDate(nextDue, inSameDayAs: startDate))
    }
    
    func testNextDueDateAfterMultipleOccurrences() {
        let startDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let today = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        
        let recurring = RecurringExpense(
            title: "Subscription",
            amount: 10,
            category: .entertainment,
            frequency: .monthly,
            startDate: startDate
        )
        
        // Simulating current date for next due calculation
        let nextDue = recurring.nextDueDate()
        XCTAssertGreater(nextDue, today)
    }
    
    // MARK: - Yearly Amount Tests
    
    func testYearlyAmountCalculationMonthly() {
        let recurring = RecurringExpense(
            title: "Netflix",
            amount: 12,
            category: .entertainment,
            frequency: .monthly,
            startDate: Date()
        )
        
        let yearlyAmount = recurring.yearlyAmount
        // 12 * 12 = 144 (approximately, accounting for 30-day intervals)
        XCTAssertGreater(yearlyAmount, 130)
        XCTAssertLess(yearlyAmount, 150)
    }
    
    func testYearlyAmountCalculationWeekly() {
        let recurring = RecurringExpense(
            title: "Gas",
            amount: 50,
            category: .transport,
            frequency: .weekly,
            startDate: Date()
        )
        
        let yearlyAmount = recurring.yearlyAmount
        // ~52 weeks per year
        let expected = 50 * Double(365) / 7.0
        XCTAssertEqual(yearlyAmount, expected, accuracy: 1)
    }
    
    // MARK: - Status Tests
    
    func testIsDueToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let recurring = RecurringExpense(
            title: "Test",
            amount: 10,
            category: .food,
            frequency: .daily,
            startDate: today,
            isActive: true
        )
        
        XCTAssertTrue(recurring.isDueToday())
    }
    
    func testIsDueTodayInactive() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let recurring = RecurringExpense(
            title: "Test",
            amount: 10,
            category: .food,
            frequency: .daily,
            startDate: today,
            isActive: false
        )
        
        XCTAssertFalse(recurring.isDueToday())
    }
    
    // MARK: - Should Generate Tests
    
    func testShouldGenerateOnStartDate() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        
        let recurring = RecurringExpense(
            title: "Test",
            amount: 10,
            category: .food,
            frequency: .monthly,
            startDate: startDate,
            isActive: true
        )
        
        let shouldGenerate = recurring.shouldGenerate(for: startDate)
        XCTAssertTrue(shouldGenerate)
    }
    
    func testShouldGenerateBeforeStartDate() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let beforeStart = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14))!
        
        let recurring = RecurringExpense(
            title: "Test",
            amount: 10,
            category: .food,
            frequency: .monthly,
            startDate: startDate,
            isActive: true
        )
        
        let shouldGenerate = recurring.shouldGenerate(for: beforeStart)
        XCTAssertFalse(shouldGenerate)
    }
    
    func testShouldGenerateAfterEndDate() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 31))!
        let afterEnd = calendar.date(from: DateComponents(year: 2026, month: 4, day: 15))!
        
        let recurring = RecurringExpense(
            title: "Test",
            amount: 10,
            category: .food,
            frequency: .monthly,
            startDate: startDate,
            endDate: endDate,
            isActive: true
        )
        
        let shouldGenerate = recurring.shouldGenerate(for: afterEnd)
        XCTAssertFalse(shouldGenerate)
    }
    
    // MARK: - Codable Tests
    
    func testRecurringExpenseEncodingDecoding() throws {
        let recurring = RecurringExpense(
            title: "Test Expense",
            amount: 50.00,
            category: .food,
            frequency: .monthly,
            startDate: Date(),
            notificationEnabled: true,
            notes: "Test notes"
        )
        
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(recurring)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RecurringExpense.self, from: encoded)
        
        XCTAssertEqual(decoded.title, recurring.title)
        XCTAssertEqual(decoded.amount, recurring.amount)
        XCTAssertEqual(decoded.category, recurring.category)
        XCTAssertEqual(decoded.frequency, recurring.frequency)
    }
}
