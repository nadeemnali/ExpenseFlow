import Foundation
import Combine
import os.log

final class ExpenseStore: ObservableObject {
    @Published private(set) var expenses: [Expense] = []
    @Published var saveError: String?

    private let fileName = "expenses.json"
    private let lastAutoGenerateKey = "ExpenseFlow.lastAutoGenerate"
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        $expenses
            .dropFirst()
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)
    }
    
    func autoGenerateRecurringExpenses(from recurringExpenseStore: RecurringExpenseStore) {
        let today = Date()
        let calendar = Calendar.current
        let lastGenerate = UserDefaults.standard.object(forKey: lastAutoGenerateKey) as? Date
        
        // Generate once per day maximum
        if let lastGenerate = lastGenerate,
           calendar.isDateInToday(lastGenerate) {
            return
        }
        
        for recurring in recurringExpenseStore.activeRecurringExpenses {
            if recurring.shouldGenerate(for: today) {
                let expense = Expense(
                    title: recurring.title,
                    amount: recurring.amount,
                    category: recurring.category,
                    date: today,
                    notes: "From: \(recurring.frequency.label) recurring expense"
                )
                addExpense(expense)
            }
        }
        
        UserDefaults.standard.set(today, forKey: lastAutoGenerateKey)
        AppLogger.log("Auto-generated recurring expenses", category: .storage, level: .debug)
    }

    func addExpense(_ expense: Expense) {
        guard expense.amount > 0 else {
            AppLogger.log("Failed to add expense: amount must be positive", category: .storage, level: .default)
            return
        }
        expenses.insert(expense, at: 0)
    }

    func deleteExpense(id: UUID) {
        expenses.removeAll { $0.id == id }
    }

    func updateExpense(_ updated: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == updated.id }) else {
            AppLogger.log("Failed to update expense: not found", category: .storage, level: .default)
            return
        }
        expenses[index] = updated
    }

    func dailyTotal(for date: Date) -> Double {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? date
        return expenses
            .filter { $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.amount }
    }

    func monthlyTotal(for date: Date) -> Double {
        let start = date.startOfMonth
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? date
        return expenses
            .filter { $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.amount }
    }

    func totalsByMonth(last count: Int) -> [(month: Date, total: Double)] {
        let calendar = Calendar.current
        let current = Date().startOfMonth
        return (0..<count).reversed().map { offset in
            let month = calendar.date(byAdding: .month, value: -offset, to: current) ?? current
            let total = monthlyTotal(for: month)
            return (month, total)
        }
    }

    func totalsByCategory(forMonth date: Date) -> [(category: ExpenseCategory, total: Double)] {
        let start = date.startOfMonth
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? date
        let filtered = expenses.filter { $0.date >= start && $0.date < end }
        return ExpenseCategory.allCases.map { category in
            let total = filtered
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.amount }
            return (category, total)
        }.filter { $0.total > 0 }
    }

    func recentExpenses(limit: Int = 6) -> [Expense] {
        Array(expenses.prefix(limit))
    }

    func resetToSample() {
        expenses = ExpenseStore.sample
        AppLogger.log("Reset expenses to sample data", category: .storage, level: .info)
    }

    func clearAll() {
        expenses = []
        AppLogger.log("Cleared all expenses", category: .storage, level: .info)
    }

    func replaceAll(_ expenses: [Expense]) {
        self.expenses = expenses.sorted(by: { $0.date > $1.date })
        AppLogger.log("Replaced expenses from backup", category: .storage, level: .info)
    }

    private func load() {
        let url = fileURL
        
        // If file doesn't exist yet, use sample data
        if !FileManager.default.fileExists(atPath: url.path) {
            AppLogger.log("Expenses file not found, using sample data", category: .storage, level: .info)
            expenses = ExpenseStore.sample
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Expense].self, from: data)
            expenses = decoded.sorted(by: { $0.date > $1.date })
            AppLogger.log("Successfully loaded \(expenses.count) expenses from storage", category: .storage, level: .info)
        } catch {
            AppLogger.error("Failed to load expenses", error: error, category: .storage)
            saveError = "Could not load expenses. Using sample data."
            expenses = ExpenseStore.sample
        }
    }

    private func save() {
        let url = fileURL
        
        do {
            let data = try JSONEncoder().encode(expenses)
            try data.write(to: url, options: .atomic)
            saveError = nil
            AppLogger.debug("Expenses saved successfully", category: .storage)
        } catch {
            AppLogger.error("Failed to save expenses", error: error, category: .storage)
            saveError = "Could not save expenses. Changes may be lost."
        }
    }

    private var fileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return (directory ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent(fileName)
    }

    static let sample: [Expense] = [
        Expense(title: "Matcha latte", amount: 6.5, category: .food, date: Date().addingTimeInterval(-3600 * 5)),
        Expense(title: "Metro pass", amount: 22, category: .transport, date: Date().addingTimeInterval(-3600 * 20)),
        Expense(title: "Yoga class", amount: 18, category: .health, date: Date().addingTimeInterval(-3600 * 26)),
        Expense(title: "Streaming", amount: 12, category: .entertainment, date: Date().addingTimeInterval(-3600 * 48)),
        Expense(title: "Groceries", amount: 54, category: .food, date: Date().addingTimeInterval(-3600 * 72)),
        Expense(title: "Sneakers", amount: 88, category: .shopping, date: Date().addingTimeInterval(-3600 * 96)),
        Expense(title: "Electric bill", amount: 64, category: .utilities, date: Date().addingTimeInterval(-3600 * 120)),
        Expense(title: "Weekend trip", amount: 190, category: .travel, date: Date().addingTimeInterval(-3600 * 240))
    ]
}
