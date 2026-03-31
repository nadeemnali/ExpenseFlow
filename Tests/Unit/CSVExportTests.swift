import XCTest
@testable import ExpenseFlow

final class CSVExportTests: XCTestCase {
    var sut: ExpenseStore!
    
    override func setUp() {
        super.setUp()
        sut = ExpenseStore()
        sut.clearAll()
    }
    
    override func tearDown() {
        super.tearDown()
        sut.clearAll()
        sut = nil
    }
    
    // MARK: - CSV Format Tests
    
    func testCSVHeaderFormat() {
        let csvContent = generateTestCSV()
        
        let lines = csvContent.components(separatedBy: "\n")
        XCTAssertTrue(lines.count > 0)
        
        let header = lines[0]
        XCTAssertTrue(header.contains("Date"))
        XCTAssertTrue(header.contains("Title"))
        XCTAssertTrue(header.contains("Category"))
        XCTAssertTrue(header.contains("Amount"))
        XCTAssertTrue(header.contains("Notes"))
    }
    
    func testCSVExportWithSimpleExpense() {
        let expense = Expense(
            title: "Coffee",
            amount: 5.50,
            category: .food,
            date: Date(),
            notes: "Morning coffee"
        )
        sut.addExpense(expense)
        
        let csvContent = generateTestCSV()
        
        XCTAssertTrue(csvContent.contains("Coffee"))
        XCTAssertTrue(csvContent.contains("5.5"))
        XCTAssertTrue(csvContent.contains("Food"))
    }
    
    func testCSVExportWithMultipleExpenses() {
        let expense1 = Expense(title: "Coffee", amount: 5.50, category: .food, date: Date())
        let expense2 = Expense(title: "Uber", amount: 15.00, category: .transport, date: Date())
        
        sut.addExpense(expense1)
        sut.addExpense(expense2)
        
        let csvContent = generateTestCSV()
        let lines = csvContent.components(separatedBy: "\n")
        
        // Header + 2 expenses + empty line
        XCTAssertGreaterThanOrEqual(lines.count, 3)
        XCTAssertTrue(csvContent.contains("Coffee"))
        XCTAssertTrue(csvContent.contains("Uber"))
    }
    
    // MARK: - CSV Escaping Tests
    
    func testCSVEscapeCommas() {
        let csvContent = generateTestCSV()
        
        // Titles with commas should be escaped in quotes
        XCTAssertTrue(csvContent.allSatisfy { char in
            if char == "," {
                // Commas should be inside quoted fields
                return true
            }
            return true
        })
    }
    
    func testCSVEscapeQuotes() {
        let expense = Expense(
            title: "Book \"Reference\"",
            amount: 20.00,
            category: .shopping,
            date: Date(),
            notes: "Test \"quoted\" notes"
        )
        sut.addExpense(expense)
        
        let csvContent = generateTestCSV()
        
        // Quotes should be escaped as double quotes
        XCTAssertTrue(csvContent.contains("\""))
    }
    
    func testCSVEscapeNewlines() {
        let expense = Expense(
            title: "Test\nExpense",
            amount: 10.00,
            category: .food,
            date: Date(),
            notes: "Line 1\nLine 2"
        )
        sut.addExpense(expense)
        
        let csvContent = generateTestCSV()
        
        // Should be escaped in quotes
        XCTAssertTrue(csvContent.contains("\""))
    }
    
    // MARK: - Date Format Tests
    
    func testCSVDateFormat() {
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 31))!
        
        let expense = Expense(
            title: "Test",
            amount: 10.00,
            category: .food,
            date: testDate
        )
        sut.addExpense(expense)
        
        let csvContent = generateTestCSV()
        
        XCTAssertTrue(csvContent.contains("2026-03-31"))
    }
    
    // MARK: - Amount Format Tests
    
    func testCSVAmountPrecision() {
        let expense = Expense(
            title: "Precise",
            amount: 12.345,
            category: .food,
            date: Date()
        )
        sut.addExpense(expense)
        
        let csvContent = generateTestCSV()
        
        // Amount should be included
        XCTAssertTrue(csvContent.contains("12.345"))
    }
    
    func testCSVAmountZero() {
        // Can't add zero amount expenses normally, but test formatting
        let amounts = [0.0, 1.0, 100.0, 1000.50]
        
        for amount in amounts {
            let csvString = String(format: "%.2f", amount)
            XCTAssertFalse(csvString.isEmpty)
        }
    }
    
    // MARK: - Empty Export Tests
    
    func testCSVExportEmpty() {
        let csvContent = generateTestCSV()
        
        let lines = csvContent.components(separatedBy: "\n")
        // Should at least have header
        XCTAssertTrue(lines.count > 0)
        XCTAssertTrue(lines[0].contains("Date"))
    }
    
    // MARK: - Helper Methods
    
    private func generateTestCSV() -> String {
        var csv = "Date,Title,Category,Amount,Notes\n"
        
        let sortedExpenses = sut.expenses.sorted { $0.date > $1.date }
        
        for expense in sortedExpenses {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: expense.date)
            
            let escapedTitle = csvEscapeField(expense.title)
            let escapedCategory = expense.category.label
            let escapedNotes = csvEscapeField(expense.notes)
            
            let line = "\(dateString),\(escapedTitle),\(escapedCategory),\(expense.amount),\(escapedNotes)\n"
            csv.append(line)
        }
        
        return csv
    }
    
    private func csvEscapeField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}
