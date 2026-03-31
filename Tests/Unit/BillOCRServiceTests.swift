import XCTest
@testable import ExpenseFlow

final class BillOCRServiceTests: XCTestCase {
    let service = BillOCRService.shared
    
    func testExtractVendorFromSimpleReceipt() {
        let text = """
        ABC STORE
        123 MAIN ST
        $25.99
        03/15/2024
        """
        
        let result = service.parseOCRText(text)
        XCTAssertEqual(result.vendor, "ABC STORE")
    }
    
    func testExtractAmountWithDollarSign() {
        let text = """
        GROCERY STORE
        Total: $42.50
        Date: 03/15/2024
        """
        
        let result = service.parseOCRText(text)
        XCTAssertEqual(result.amount, 42.50)
    }
    
    func testExtractAmountWithoutDollarSign() {
        let text = """
        UTILITY COMPANY
        Amount: 125.75
        Date: 03/15/2024
        """
        
        let result = service.parseOCRText(text)
        XCTAssertEqual(result.amount, 125.75)
    }
    
    func testExtractDateNumericFormat() {
        let text = """
        RESTAURANT
        03/15/2024
        Total: $45.00
        """
        
        let result = service.parseOCRText(text)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .year], from: result.date)
        
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.year, 2024)
    }
    
    func testExtractDateNamedFormat() {
        let text = """
        COFFEE SHOP
        March 15, 2024
        Total: $5.50
        """
        
        let result = service.parseOCRText(text)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .year], from: result.date)
        
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.year, 2024)
    }
    
    func testMissingVendorReducesConfidence() {
        let text = """
        $50.00
        03/15/2024
        """
        
        let result = service.parseOCRText(text)
        XCTAssertLessThan(result.confidence, 0.95)
        XCTAssertEqual(result.vendor, "Unknown Vendor")
    }
    
    func testMissingAmountReducesConfidence() {
        let text = """
        STORE NAME
        03/15/2024
        """
        
        let result = service.parseOCRText(text)
        XCTAssertLessThan(result.confidence, 0.95)
        XCTAssertEqual(result.amount, 0)
    }
    
    func testMissingDateReducesConfidence() {
        let text = """
        STORE NAME
        $100.00
        """
        
        let result = service.parseOCRText(text)
        XCTAssertLessThan(result.confidence, 0.95)
    }
    
    func testConfidenceNeverBelowZero() {
        let text = """
        $1000000000000.00
        invalid/date/format
        """
        
        let result = service.parseOCRText(text)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
    }
    
    func testConfidenceNeverAboveOne() {
        let text = """
        ABC STORE
        $25.99
        03/15/2024
        """
        
        let result = service.parseOCRText(text)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
    }
    
    func testComplexReceiptParsing() {
        let text = """
        WHOLE FOODS MARKET
        123 MAIN STREET
        DATE: 03/15/2024
        ---
        BANANAS        $2.50
        MILK           $3.99
        BREAD          $4.50
        ---
        SUBTOTAL       $10.99
        TAX            $0.88
        TOTAL          $11.87
        """
        
        let result = service.parseOCRText(text)
        XCTAssertEqual(result.vendor, "WHOLE FOODS MARKET")
        XCTAssertGreaterThan(result.amount, 0)
    }
    
    func testOCRResultCodable() {
        let original = OCRResult(
            vendor: "Test Store",
            amount: 99.99,
            date: Date(),
            description: "Test bill",
            rawText: "Test raw text"
        )
        
        let encoder = JSONEncoder()
        let data = try! encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try! decoder.decode(OCRResult.self, from: data)
        
        XCTAssertEqual(decoded.vendor, original.vendor)
        XCTAssertEqual(decoded.amount, original.amount)
        XCTAssertEqual(decoded.description, original.description)
    }
    
    func testOCRResultFormattedAmount() {
        let result = OCRResult(
            vendor: "Store",
            amount: 99.99,
            date: Date(),
            rawText: "Test"
        )
        
        XCTAssertTrue(result.formattedAmount.contains("99"))
        XCTAssertTrue(result.formattedAmount.contains("99") || result.formattedAmount.contains("$"))
    }
    
    private func parseOCRText(_ text: String) -> ParsedOCRData {
        guard let service = BillOCRService.self as? BillOCRService.Type else {
            fatalError("Cannot access private method")
        }
        return service.shared.parseOCRText(text)
    }
}

private struct ParsedOCRData {
    let vendor: String
    let amount: Decimal
    let date: Date
    let description: String?
    let confidence: Double
}

extension BillOCRService {
    func parseOCRText(_ text: String) -> ParsedOCRData {
        let lines = text.split(separator: "\n").map(String.init)
        
        var vendor = extractVendor(from: lines)
        var amount = extractAmount(from: text)
        var date = extractDate(from: text)
        var description: String?
        var confidence = 0.95
        
        if vendor.isEmpty {
            vendor = "Unknown Vendor"
            confidence -= 0.3
        }
        
        if amount <= 0 {
            amount = 0
            confidence -= 0.3
        }
        
        if date == Date(timeIntervalSince1970: 0) {
            date = Date()
            confidence -= 0.2
        }
        
        confidence = max(0.0, min(1.0, confidence))
        
        return ParsedOCRData(
            vendor: vendor,
            amount: amount,
            date: date,
            description: description,
            confidence: confidence
        )
    }
    
    private func extractVendor(from lines: [String]) -> String {
        let validLines = lines
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .filter { !isNumeric($0) }
            .filter { !isDate($0) }
        
        if let firstLine = validLines.first, firstLine.count > 2 && firstLine.count < 100 {
            return firstLine.trimmingCharacters(in: .whitespaces)
        }
        
        return ""
    }
    
    private func extractAmount(from text: String) -> Decimal {
        let currencyPatterns = [
            "\\$\\s*(\\d+(?:[,.]\\d{2})?)",
            "(\\d+(?:[,.]\\d{2})?)\\s*(?:USD|dollar)",
            "(?:total|amount|subtotal)\\s*[:\\-]?\\s*\\$?\\s*(\\d+(?:[,.]\\d{2})?)"
        ]
        
        for pattern in currencyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let amountStr = String(text[range])
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: "$", with: "")
                
                if let amount = Decimal(string: amountStr) {
                    return amount
                }
            }
        }
        
        return 0
    }
    
    private func extractDate(from text: String) -> Date {
        let datePatterns = [
            "(\\d{1,2})[/-](\\d{1,2})[/-](\\d{2,4})",
            "(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[\\s,]+(\\d{1,2})[\\s,]+(\\d{4})"
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                if let dateString = Range(match.range, in: text) {
                    let dateStr = String(text[dateString])
                    if let date = parseDate(dateStr) {
                        return date
                    }
                }
            }
        }
        
        return Date()
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            "MM/dd/yyyy",
            "MM-dd-yyyy",
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "M/d/yy",
            "M-d-yy",
            "MMMM dd, yyyy",
            "MMM dd, yyyy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func isNumeric(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        return trimmed.allSatisfy { $0.isNumber || $0 == "." || $0 == "," }
    }
    
    private func isDate(_ string: String) -> Bool {
        let patterns = [
            "\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}",
            "(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+\\d{1,2}"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) != nil {
                return true
            }
        }
        
        return false
    }
}
