import Foundation

enum RecurrenceFrequency: String, CaseIterable, Codable, Identifiable {
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
    
    var daysInterval: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .yearly: return 365
        }
    }
    
    func nextDate(after date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: daysInterval, to: date) ?? date
    }
}

struct RecurringExpense: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var category: ExpenseCategory
    var frequency: RecurrenceFrequency
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var notificationEnabled: Bool
    var notificationDaysBefore: Int
    var notes: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: ExpenseCategory,
        frequency: RecurrenceFrequency,
        startDate: Date,
        endDate: Date? = nil,
        isActive: Bool = true,
        notificationEnabled: Bool = true,
        notificationDaysBefore: Int = 1,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.notificationEnabled = notificationEnabled
        self.notificationDaysBefore = notificationDaysBefore
        self.notes = notes
        self.createdAt = createdAt
    }
    
    var yearlyAmount: Double {
        let daysPerYear = 365
        let occurrencesPerYear = Double(daysPerYear) / Double(frequency.daysInterval)
        return amount * occurrencesPerYear
    }
    
    func isDueToday() -> Bool {
        guard isActive else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextDueDate = nextDueDate()
        return calendar.isDate(nextDueDate, inSameDayAs: today)
    }
    
    func nextDueDate() -> Date {
        let today = Date()
        var currentDate = startDate
        
        while currentDate < today {
            currentDate = frequency.nextDate(after: currentDate)
        }
        
        if let endDate = endDate, currentDate > endDate {
            return endDate
        }
        
        return currentDate
    }
    
    func shouldGenerate(for date: Date) -> Bool {
        guard isActive else { return false }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if calendar.compare(startOfDay, to: startDate, toGranularity: .day) == .orderedAscending {
            return false
        }
        
        if let endDate = endDate, calendar.compare(date, to: endDate, toGranularity: .day) == .orderedDescending {
            return false
        }
        
        var currentDate = startDate
        while currentDate < date {
            let nextDate = frequency.nextDate(after: currentDate)
            if calendar.isDate(nextDate, inSameDayAs: date) {
                return true
            }
            currentDate = nextDate
        }
        
        return calendar.isDate(startDate, inSameDayAs: date)
    }
}
