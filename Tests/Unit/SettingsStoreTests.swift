import XCTest
@testable import ExpenseFlow

final class SettingsStoreTests: XCTestCase {
    var sut: SettingsStore!
    
    override func setUp() {
        super.setUp()
        // Clear any previous test settings
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.settings")
        sut = SettingsStore()
    }
    
    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.settings")
        sut = nil
    }
    
    // MARK: - Default Values Tests
    
    func testDefaultBudgetValue() {
        XCTAssertEqual(sut.monthlyBudget, 1200)
    }
    
    func testDefaultCurrencyCode() {
        let expectedCurrency = Locale.current.currency?.identifier ?? "USD"
        XCTAssertEqual(sut.currencyCode, expectedCurrency)
    }
    
    func testDefaultNotificationsEnabled() {
        XCTAssertTrue(sut.notificationsEnabled)
    }
    
    func testDefaultWeekStart() {
        XCTAssertEqual(sut.startOfWeek, .monday)
    }
    
    func testDefaultColorScheme() {
        XCTAssertEqual(sut.colorScheme, .system)
    }
    
    // MARK: - Budget Tests
    
    func testBudgetCanBeUpdated() {
        sut.monthlyBudget = 1500
        XCTAssertEqual(sut.monthlyBudget, 1500)
    }
    
    func testBudgetCanBeSetToZero() {
        sut.monthlyBudget = 0
        XCTAssertEqual(sut.monthlyBudget, 0)
    }
    
    func testBudgetCanBeNegative() {
        sut.monthlyBudget = -100
        XCTAssertEqual(sut.monthlyBudget, -100)
    }
    
    func testLargeBudgetValue() {
        sut.monthlyBudget = 1_000_000
        XCTAssertEqual(sut.monthlyBudget, 1_000_000)
    }
    
    // MARK: - Currency Code Tests
    
    func testCurrencyCodeCanBeUpdated() {
        sut.currencyCode = "EUR"
        XCTAssertEqual(sut.currencyCode, "EUR")
    }
    
    func testValidCurrencyCodes() {
        let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD"]
        for currency in currencies {
            sut.currencyCode = currency
            XCTAssertEqual(sut.currencyCode, currency)
        }
    }
    
    // MARK: - Notifications Tests
    
    func testNotificationsCanBeToggled() {
        sut.notificationsEnabled = false
        XCTAssertFalse(sut.notificationsEnabled)
        
        sut.notificationsEnabled = true
        XCTAssertTrue(sut.notificationsEnabled)
    }
    
    // MARK: - Week Start Tests
    
    func testWeekStartCanBeSwitched() {
        sut.startOfWeek = .sunday
        XCTAssertEqual(sut.startOfWeek, .sunday)
        
        sut.startOfWeek = .monday
        XCTAssertEqual(sut.startOfWeek, .monday)
    }
    
    // MARK: - Color Scheme Tests
    
    func testColorSchemeCanBeChanged() {
        sut.colorScheme = .light
        XCTAssertEqual(sut.colorScheme, .light)
        
        sut.colorScheme = .dark
        XCTAssertEqual(sut.colorScheme, .dark)
        
        sut.colorScheme = .system
        XCTAssertEqual(sut.colorScheme, .system)
    }
    
    func testPreferredColorSchemeMapping() {
        sut.colorScheme = .system
        XCTAssertNil(sut.preferredColorScheme)
        
        sut.colorScheme = .light
        XCTAssertEqual(sut.preferredColorScheme, .light)
        
        sut.colorScheme = .dark
        XCTAssertEqual(sut.preferredColorScheme, .dark)
    }
    
    // MARK: - Persistence Tests
    
    func testSettingsAreSavedToUserDefaults() {
        sut.monthlyBudget = 2000
        sut.currencyCode = "EUR"
        sut.notificationsEnabled = false
        
        // Create new instance to test persistence
        let newStore = SettingsStore()
        
        XCTAssertEqual(newStore.monthlyBudget, 2000)
        XCTAssertEqual(newStore.currencyCode, "EUR")
        XCTAssertFalse(newStore.notificationsEnabled)
    }
    
    func testMultipleSettingsChangedSimultaneously() {
        sut.monthlyBudget = 3000
        sut.currencyCode = "GBP"
        sut.startOfWeek = .sunday
        sut.notificationsEnabled = false
        sut.colorScheme = .dark
        
        let newStore = SettingsStore()
        
        XCTAssertEqual(newStore.monthlyBudget, 3000)
        XCTAssertEqual(newStore.currencyCode, "GBP")
        XCTAssertEqual(newStore.startOfWeek, .sunday)
        XCTAssertFalse(newStore.notificationsEnabled)
        XCTAssertEqual(newStore.colorScheme, .dark)
    }
}
