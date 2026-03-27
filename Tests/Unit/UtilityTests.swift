import XCTest
@testable import ExpenseFlow

final class DateHelpersTests: XCTestCase {
    
    func testStartOfMonthCalculation() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2025, month: 3, day: 15))!
        
        let startOfMonth = date.startOfMonth
        let components = calendar.dateComponents([.year, .month, .day], from: startOfMonth)
        
        XCTAssertEqual(components.day, 1)
        XCTAssertEqual(components.month, 3)
    }
    
    func testStartOfMonthForFirstDay() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2025, month: 3, day: 1))!
        
        let startOfMonth = date.startOfMonth
        let components = calendar.dateComponents([.day], from: startOfMonth)
        
        XCTAssertEqual(components.day, 1)
    }
    
    func testStartOfMonthForLastDay() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2025, month: 3, day: 31))!
        
        let startOfMonth = date.startOfMonth
        let components = calendar.dateComponents([.day], from: startOfMonth)
        
        XCTAssertEqual(components.day, 1)
    }
}

final class FormattersTests: XCTestCase {
    
    func testCurrencyFormatterUSD() {
        let formatter = Formatters.currency(code: "USD")
        
        XCTAssertEqual(formatter.currencyCode, "USD")
        XCTAssertEqual(formatter.numberStyle, .currency)
    }
    
    func testCurrencyFormatterEUR() {
        let formatter = Formatters.currency(code: "EUR")
        
        XCTAssertEqual(formatter.currencyCode, "EUR")
        XCTAssertEqual(formatter.numberStyle, .currency)
    }
    
    func testNumberFormatterDecimal() {
        let formatter = Formatters.number
        
        XCTAssertEqual(formatter.numberStyle, .decimal)
        XCTAssertEqual(formatter.maximumFractionDigits, 2)
    }
    
    func testCurrencyFormatting() {
        let formatter = Formatters.currency(code: "USD")
        let amount = NSNumber(value: 1234.56)
        let formatted = formatter.string(from: amount)
        
        XCTAssertNotNil(formatted)
        XCTAssertTrue(formatted?.contains("1234") ?? false || formatted?.contains("234") ?? false)
    }
}
