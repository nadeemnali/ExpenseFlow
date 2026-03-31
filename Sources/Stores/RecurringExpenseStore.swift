import SwiftUI
import Combine
import os.log

final class RecurringExpenseStore: ObservableObject {
    @Published var recurringExpenses: [RecurringExpense] = []
    @Published var saveError: String?
    
    private let storageKey = "ExpenseFlow.recurringExpenses"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        load()
        $recurringExpenses
            .dropFirst()
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - CRUD Operations
    
    func add(_ expense: RecurringExpense) {
        recurringExpenses.append(expense)
    }
    
    func update(_ expense: RecurringExpense) {
        if let index = recurringExpenses.firstIndex(where: { $0.id == expense.id }) {
            recurringExpenses[index] = expense
        }
    }
    
    func delete(_ id: UUID) {
        recurringExpenses.removeAll { $0.id == id }
    }
    
    func delete(_ expense: RecurringExpense) {
        delete(expense.id)
    }
    
    func get(_ id: UUID) -> RecurringExpense? {
        recurringExpenses.first { $0.id == id }
    }
    
    // MARK: - Filtering & Queries
    
    var activeRecurringExpenses: [RecurringExpense] {
        recurringExpenses.filter { $0.isActive }
    }
    
    var subscriptions: [RecurringExpense] {
        activeRecurringExpenses.filter { expense in
            let subscriptionCategories: [ExpenseCategory] = [.entertainment, .shopping, .other]
            return subscriptionCategories.contains(expense.category)
        }
    }
    
    var monthlyRecurringAmount: Double {
        activeRecurringExpenses.reduce(0) { total, expense in
            let occurrencesPerMonth = 30.0 / Double(expense.frequency.daysInterval)
            return total + (expense.amount * occurrencesPerMonth)
        }
    }
    
    var totalYearlyAmount: Double {
        activeRecurringExpenses.reduce(0) { $0 + $1.yearlyAmount }
    }
    
    func dueSoon(days: Int = 7) -> [RecurringExpense] {
        let calendar = Calendar.current
        let today = Date()
        let futureDate = calendar.date(byAdding: .day, value: days, to: today) ?? today
        
        return activeRecurringExpenses.filter { expense in
            let nextDue = expense.nextDueDate()
            return nextDue >= today && nextDue <= futureDate && expense.notificationEnabled
        }
    }
    
    // MARK: - Persistence
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            AppLogger.log("No saved recurring expenses found", category: .storage, level: .info)
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([RecurringExpense].self, from: data)
            
            recurringExpenses = decoded.filter { expense in
                expense.amount > 0
            }
            
            AppLogger.log("Recurring expenses loaded successfully (\(decoded.count) items)", category: .storage, level: .info)
        } catch {
            AppLogger.error("Failed to load recurring expenses", error: error, category: .storage)
            saveError = "Could not load recurring expenses. Starting fresh."
        }
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(recurringExpenses)
            UserDefaults.standard.set(data, forKey: storageKey)
            saveError = nil
            AppLogger.debug("Recurring expenses saved successfully (\(recurringExpenses.count) items)", category: .storage)
        } catch {
            AppLogger.error("Failed to save recurring expenses", error: error, category: .storage)
            saveError = "Could not save recurring expenses. Changes may be lost."
        }
    }
    
    enum SettingsError: LocalizedError {
        case invalidBudget
        
        var errorDescription: String? {
            switch self {
            case .invalidBudget:
                return "Amount must be greater than zero"
            }
        }
    }
}
