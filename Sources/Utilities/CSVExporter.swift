import Foundation

enum CSVExporter {
    static func makeCSV(expenses: [Expense]) -> String {
        var csv = "Date,Title,Category,Amount,Notes\n"
        let sortedExpenses = expenses.sorted { $0.date > $1.date }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for expense in sortedExpenses {
            let dateString = dateFormatter.string(from: expense.date)
            let title = csvEscape(expense.title)
            let category = csvEscape(expense.displayCategoryLabel)
            let notes = csvEscape(expense.notes)
            let line = "\(dateString),\(title),\(category),\(expense.amount),\(notes)\n"
            csv.append(line)
        }

        return csv
    }

    private static func csvEscape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}
