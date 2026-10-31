import XCTest
@testable import ExpenseFlow

final class SmartCategorizationServiceTests: XCTestCase {
    var sut: SmartCategorizationService!
    var testExpenses: [Expense]!
    
    override func setUp() {
        super.setUp()
        sut = SmartCategorizationService()
        testExpenses = createTestExpenses()
    }
    
    override func tearDown() {
        sut = nil
        testExpenses = nil
        super.tearDown()
    }
    
    // MARK: - Keyword Matching Tests
    
    func testSuggestCategoryForRestaurant() {
        let result = sut.suggestCategory(
            for: "Starbucks Coffee",
            from: testExpenses,
            availableCategories: ExpenseCategory.allCases
        )
        
        XCTAssertEqual(result.category, .Food)
        XCTAssertGreaterThan(result.confidence, 0.8)
    }
    
    func testSuggestCategoryForUber() {
        let result = sut.suggestCategory(
            for: "Uber Trip Downtown",
            from: testExpenses,
            availableCategories: ExpenseCategory.allCases
        )
        
        XCTAssertEqual(result.category, .Transport)
        XCTAssertGreaterThan(result.confidence, 0.8)
    }
    
    func testSuggestCategoryForGym() {
        let result = sut.suggestCategory(
            for: "Planet Fitness Monthly",
            from: testExpenses,
            availableCategories: ExpenseCategory.allCases
        )
        
        XCTAssertEqual(result.category, .Health)
    }
    
    func testSuggestCategoryForMovieTicket() {
        let result = sut.suggestCategory(
            for: "AMC Movie Theaters",
            from: testExpenses,
            availableCategories: ExpenseCategory.allCases
        )
        
        XCTAssertEqual(result.category, .Entertainment)
    }
    
    // MARK: - Ranked Suggestions Tests
    
    func testRankedSuggestions() {
        let suggestions = sut.rankedCategorySuggestions(
            for: "Pizza Hut Dinner",
            from: testExpenses,
            availableCategories: ExpenseCategory.allCases
        )
        
        XCTAssertFalse(suggestions.isEmpty)
        
        // First suggestion should have highest confidence
        for i in 0..<suggestions.count - 1 {
            XCTAssertGreaterThanOrEqual(suggestions[i].confidence, suggestions[i + 1].confidence)
        }
    }
    
    func testRankedSuggestionsAllValidated() {
        let suggestions = sut.rankedCategorySuggestions(
            for: "Random Expense",
            from: testExpenses,
            availableCategories: ExpenseCategory.allCases
        )
        
        XCTAssertTrue(suggestions.allSatisfy { $0.confidence >= 0 && $0.confidence <= 1 })
        XCTAssertTrue(suggestions.allSatisfy { !$0.reason.isEmpty })
    }
    
    // MARK: - Similarity Matching Tests
    
    func testSimilarExpenseMatching() {
        // Add a known expense
        var expensesWithKnown = testExpenses
        expensesWithKnown.insert(
            Expense(title: "McDonald's Lunch", amount: 12, category: .Food, date: Date()),
            at: 0
        )
        
        let result = sut.suggestCategory(
            for: "McDonald's Dinner",
            from: expensesWithKnown,
            availableCategories: ExpenseCategory.allCases
        )
        
        // Should match Food category from similar title
        XCTAssertEqual(result.category, .Food)
    }
    
    // MARK: - Confidence Scoring Tests
    
    func testConfidenceScoring() {
        let result = sut.suggestCategory(
            for: "Exact Restaurant Match",
            from: testExpenses,
            availableCategories: ExpenseCategory.allCases
        )
        
        XCTAssertGreaterThan(result.confidence, 0)
        XCTAssertLessThanOrEqual(result.confidence, 1)
    }
    
    // MARK: - Learning Tests
    
    func testLearnFromUserChoice() {
        var store: [String: ExpenseCategory] = [:]
        
        sut.learnFromUserChoice(
            title: "Amazon Prime Video Subscription",
            chosenCategory: .Entertainment,
            store: &store
        )
        
        XCTAssertFalse(store.isEmpty)
        // Keywords from the title should be stored
        XCTAssertNotNil(store["amazon"] ?? store["prime"] ?? store["video"])
    }
    
    // MARK: - Edge Cases Tests
    
    func testSuggestCategoryForEmptyTitle() {
        let result = sut.suggestCategory(
            for: "",
            from: testExpenses,
            availableCategories: ExpenseCategory.allCases
        )
        
        // Should return default with low confidence
        XCTAssertEqual(result.category, .Food)
        XCTAssertLessThan(result.confidence, 0.7)
    }
    
    func testSuggestCategoryForVeryShortTitle() {
        let result = sut.suggestCategory(
            for: "Gas",
            from: testExpenses,
            availableCategories: ExpenseCategory.allCases
        )
        
        XCTAssertEqual(result.category, .Transport)
    }
    
    func testCategoryPercentageCalculation() {
        let suggestions = sut.rankedCategorySuggestions(
            for: "Whole Foods Groceries",
            from: testExpenses,
            availableCategories: ExpenseCategory.allCases
        )
        
        let firstSuggestion = suggestions.first
        if let suggestion = firstSuggestion {
            XCTAssertGreaterThan(suggestion.confidencePercentage, 0)
            XCTAssertLessThanOrEqual(suggestion.confidencePercentage, 100)
            XCTAssertEqual(suggestion.confidencePercentage, Int(suggestion.confidence * 100))
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestExpenses() -> [Expense] {
        var expenses: [Expense] = []
        
        let testData: [(String, ExpenseCategory)] = [
            ("Starbucks", .Food),
            ("Chipotle", .Food),
            ("Whole Foods", .Groceries),
            ("Uber", .Transport),
            ("Shell Gas Station", .Transport),
            ("Planet Fitness", .Health),
            ("CVS Pharmacy", .Health),
            ("Netflix", .Entertainment),
            ("Amazon", .Shopping),
            ("Target", .Shopping),
            ("Electric Bill", .Utilities),
        ]
        
        let calendar = Calendar.current
        var dateOffset = 0
        
        for (title, category) in testData {
            let date = calendar.date(byAdding: .day, value: dateOffset, to: Date()) ?? Date()
            expenses.append(
                Expense(
                    title: title,
                    amount: Double.random(in: 10...100),
                    category: category,
                    date: date
                )
            )
            dateOffset -= 1
        }
        
        return expenses
    }
}
