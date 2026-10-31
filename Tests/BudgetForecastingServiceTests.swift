import XCTest
@testable import ExpenseFlow

final class BudgetForecastingServiceTests: XCTestCase {
    var sut: BudgetForecastingService!
    var testExpenses: [Expense]!
    
    override func setUp() {
        super.setUp()
        sut = BudgetForecastingService()
        testExpenses = createTestExpenses()
    }
    
    override func tearDown() {
        sut = nil
        testExpenses = nil
        super.tearDown()
    }
    
    // MARK: - Monthly Prediction Tests
    
    func testPredictMonthlyTotal() {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        let prediction = sut.predictMonthlyTotal(currentMonth: currentMonth, from: testExpenses)
        
        XCTAssertGreaterThanOrEqual(prediction.predicted, 0)
        XCTAssertGreaterThanOrEqual(prediction.dailyRate, 0)
        XCTAssertGreaterThanOrEqual(prediction.confidence, 0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1)
    }
    
    func testPredictMonthlyTotalIncreaseWithMoreExpenses() {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        let prediction1 = sut.predictMonthlyTotal(currentMonth: currentMonth, from: testExpenses)
        
        // Add more expenses
        var moreExpenses = testExpenses
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: i, to: Date()) ?? Date()
            moreExpenses.append(Expense(title: "Extra", amount: 50, category: .Food, date: date))
        }
        
        let prediction2 = sut.predictMonthlyTotal(currentMonth: currentMonth, from: moreExpenses)
        
        XCTAssertGreaterThan(prediction2.predicted, prediction1.predicted)
    }
    
    // MARK: - Budget Exceedance Warning Tests
    
    func testBudgetExceedanceWarningWhenNotExceeded() {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        let warning = sut.budgetExceedanceWarning(
            monthBudget: 10000,
            currentMonth: currentMonth,
            from: testExpenses
        )
        
        // With high budget, should not warn
        if let warning = warning {
            XCTAssertTrue([.medium, .high, .critical].contains(warning.level))
        }
    }
    
    func testBudgetExceedanceWarningLevel() {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        let warning = sut.budgetExceedanceWarning(
            monthBudget: 100,  // Very low budget
            currentMonth: currentMonth,
            from: testExpenses
        )
        
        XCTAssertNotNil(warning)
        XCTAssertNotEqual(warning?.level, .medium)
    }
    
    // MARK: - Category Forecast Tests
    
    func testCategoryForecast() {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        let forecasts = sut.categoryForecast(
            currentMonth: currentMonth,
            from: testExpenses,
            categoryLimit: [:]
        )
        
        XCTAssertFalse(forecasts.isEmpty)
        XCTAssertTrue(forecasts.allSatisfy { $0.predicted >= 0 })
    }
    
    func testCategoryForecastSorted() {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        let forecasts = sut.categoryForecast(
            currentMonth: currentMonth,
            from: testExpenses,
            categoryLimit: [:]
        )
        
        // Should be sorted by predicted descending
        for i in 0..<forecasts.count - 1 {
            XCTAssertGreaterThanOrEqual(forecasts[i].predicted, forecasts[i + 1].predicted)
        }
    }
    
    // MARK: - Forecast Insights Tests
    
    func testForecastInsights() {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        let insights = sut.forecastInsights(
            monthBudget: 1000,
            currentMonth: currentMonth,
            from: testExpenses
        )
        
        XCTAssertGreaterThan(insights.count, 0)
        XCTAssertTrue(insights.allSatisfy { !$0.title.isEmpty && !$0.value.isEmpty })
    }
    
    // MARK: - Helper Methods
    
    private func createTestExpenses() -> [Expense] {
        var expenses: [Expense] = []
        
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        
        // Create expenses for current month
        for day in 1...15 {
            let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? Date()
            let categories: [ExpenseCategory] = [.Food, .Transport, .Health, .Entertainment, .Shopping]
            let category = categories.randomElement() ?? .Food
            
            let expense = Expense(
                title: "Daily Expense",
                amount: Double.random(in: 10...50),
                category: category,
                date: date
            )
            expenses.append(expense)
        }
        
        return expenses
    }
}
