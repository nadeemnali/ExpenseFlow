import XCTest
@testable import ExpenseFlow

final class AdvancedAnalyticsServiceTests: XCTestCase {
    var sut: AdvancedAnalyticsService!
    var testExpenses: [Expense]!
    
    override func setUp() {
        super.setUp()
        sut = AdvancedAnalyticsService()
        testExpenses = createTestExpenses()
    }
    
    override func tearDown() {
        sut = nil
        testExpenses = nil
        super.tearDown()
    }
    
    // MARK: - Category Breakdown Tests
    
    func testCategoryBreakdown() {
        let result = sut.categoryBreakdown(for: 2024, from: testExpenses)
        
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { $0.percentage >= 0 && $0.percentage <= 100 })
        
        // Total percentages should sum to ~100%
        let totalPercentage = result.reduce(0) { $0 + $1.percentage }
        XCTAssertEqual(totalPercentage, 100, accuracy: 0.1)
    }
    
    func testCategoryBreakdownSorted() {
        let result = sut.categoryBreakdown(for: 2024, from: testExpenses)
        
        // Should be sorted by amount descending
        for i in 0..<result.count - 1 {
            XCTAssertGreaterThanOrEqual(result[i].amount, result[i + 1].amount)
        }
    }
    
    // MARK: - Monthly Breakdown Tests
    
    func testMonthlyBreakdown() {
        let result = sut.monthlyBreakdown(for: 2024, from: testExpenses)
        
        XCTAssertEqual(result.count, 12)
        XCTAssertTrue(result.allSatisfy { $0.total >= 0 })
    }
    
    func testMonthlyBreakdownLabels() {
        let result = sut.monthlyBreakdown(for: 2024, from: testExpenses)
        
        let expectedMonths = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                             "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let resultMonths = result.map { $0.month }
        
        XCTAssertEqual(resultMonths, expectedMonths)
    }
    
    // MARK: - Annual Summary Tests
    
    func testAnnualSummary() {
        let result = sut.annualSummary(from: testExpenses)
        
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { $0.value > 0 })
    }
    
    func testAnnualSummaryContains2024() {
        let result = sut.annualSummary(from: testExpenses)
        
        XCTAssertNotNil(result[2024])
        XCTAssertGreaterThan(result[2024] ?? 0, 0)
    }
    
    // MARK: - Month Comparison Tests
    
    func testMonthComparison() {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
        
        let result = sut.monthComparison(current: currentMonth, previous: previousMonth, from: testExpenses)
        
        XCTAssertGreaterThanOrEqual(result.current, 0)
        XCTAssertGreaterThanOrEqual(result.previous, 0)
    }
    
    // MARK: - Trending Categories Tests
    
    func testTrendingCategories() {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        let result = sut.trendingCategories(currentMonth: currentMonth, from: testExpenses)
        
        // All should have positive trends
        XCTAssertTrue(result.allSatisfy { $0.trend > 0 })
        
        // Should be sorted by trend descending
        for i in 0..<result.count - 1 {
            XCTAssertGreaterThanOrEqual(result[i].trend, result[i + 1].trend)
        }
    }
    
    // MARK: - Annual Report Tests
    
    func testAnnualReport() {
        let report = sut.annualReport(for: 2024, from: testExpenses)
        
        XCTAssertEqual(report.year, 2024)
        XCTAssertGreaterThan(report.totalSpent, 0)
        XCTAssertGreaterThan(report.averageMonthly, 0)
        XCTAssertFalse(report.topCategories.isEmpty)
        XCTAssertEqual(report.monthlyData.count, 12)
    }
    
    // MARK: - Helper Methods
    
    private func createTestExpenses() -> [Expense] {
        var expenses: [Expense] = []
        
        let calendar = Calendar.current
        for month in 1...12 {
            for day in 1...5 {
                let date = calendar.date(from: DateComponents(year: 2024, month: month, day: day)) ?? Date()
                let categories: [ExpenseCategory] = [.Food, .Transport, .Health, .Entertainment, .Shopping]
                let category = categories.randomElement() ?? .Food
                
                let expense = Expense(
                    title: "Test Expense",
                    amount: Double.random(in: 10...100),
                    category: category,
                    date: date
                )
                expenses.append(expense)
            }
        }
        
        return expenses
    }
}
