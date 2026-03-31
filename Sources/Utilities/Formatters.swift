import Foundation

enum Formatters {
    static func currency(code: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    static func currencyString(_ value: Double, code: String = "USD") -> String {
        let formatter = currency(code: code)
        return formatter.string(from: NSNumber(value: value)) ?? "$\(String(format: "%.2f", value))"
    }

    static let number: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
