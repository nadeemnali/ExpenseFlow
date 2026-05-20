import UserNotifications
import SwiftUI
import os.log

final class BillReminderService {
    static let shared = BillReminderService()

    private let reminderHorizonDays = 180
    private let maxScheduledOccurrencesPerExpense = 8
    
    private init() {}
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                AppLogger.error("Failed to request notification permission", error: error, category: .general)
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleReminders(for recurringExpense: RecurringExpense) {
        guard recurringExpense.notificationEnabled else {
            removePendingReminders(for: recurringExpense.id)
            return
        }

        let now = Date()
        let horizonEnd = Calendar.current.date(byAdding: .day, value: reminderHorizonDays, to: now) ?? now
        let dueDates = recurringExpense
            .dueDates(from: now, through: horizonEnd)
            .prefix(maxScheduledOccurrencesPerExpense)

        let identifiersToReplace = dueDates.map { reminderIdentifier(for: recurringExpense.id, dueDate: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: identifiersToReplace + ["BillReminder_\(recurringExpense.id.uuidString)"]
        )

        for dueDate in dueDates {
            let reminderDate = Calendar.current.date(
                byAdding: .day,
                value: -recurringExpense.notificationDaysBefore,
                to: dueDate
            ) ?? dueDate

            guard reminderDate > now else { continue }

            scheduleNotification(
                for: recurringExpense,
                dueDate: dueDate,
                at: reminderDate
            )
        }
    }
    
    func scheduleAllReminders(from recurringExpenseStore: RecurringExpenseStore) {
        removeAllPendingReminders()
        
        for expense in recurringExpenseStore.activeRecurringExpenses where expense.notificationEnabled {
            scheduleReminders(for: expense)
        }
    }

    func syncReminders(isEnabled: Bool, from recurringExpenseStore: RecurringExpenseStore) {
        guard isEnabled else {
            removeAllPendingReminders()
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.scheduleAllRemindersOnMain(from: recurringExpenseStore)
            case .notDetermined:
                self.requestNotificationPermission { granted in
                    if granted {
                        self.scheduleAllRemindersOnMain(from: recurringExpenseStore)
                    } else {
                        self.removeAllPendingReminders()
                    }
                }
            case .denied:
                self.removeAllPendingReminders()
            @unknown default:
                self.removeAllPendingReminders()
            }
        }
    }

    private func scheduleAllRemindersOnMain(from recurringExpenseStore: RecurringExpenseStore) {
        DispatchQueue.main.async {
            self.scheduleAllReminders(from: recurringExpenseStore)
        }
    }
    
    private func scheduleNotification(for expense: RecurringExpense, dueDate: Date, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Bill Due Soon"
        content.body = "\(expense.title): \(Formatters.currencyString(expense.amount))"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        let userInfo: [AnyHashable: Any] = [
            "expenseId": expense.id.uuidString,
            "expenseTitle": expense.title
        ]
        content.userInfo = userInfo
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: reminderIdentifier(for: expense.id, dueDate: dueDate),
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                AppLogger.error("Failed to schedule notification", error: error, category: .general)
            } else {
                AppLogger.debug("Scheduled reminder for: \(expense.title)", category: .general)
            }
        }
    }
    
    func removePendingReminders(for expenseId: UUID) {
        let prefix = reminderPrefix(for: expenseId)

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) || $0 == "BillReminder_\(expenseId.uuidString)" }

            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    func removeAllPendingReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let billReminders = requests.filter { $0.identifier.hasPrefix("BillReminder_") }
            completion(billReminders)
        }
    }

    private func reminderPrefix(for expenseId: UUID) -> String {
        "BillReminder_\(expenseId.uuidString)_"
    }

    private func reminderIdentifier(for expenseId: UUID, dueDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd"
        return reminderPrefix(for: expenseId) + formatter.string(from: dueDate)
    }
}
