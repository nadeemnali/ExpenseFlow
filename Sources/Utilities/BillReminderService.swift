import UserNotifications
import SwiftUI
import os.log

final class BillReminderService {
    static let shared = BillReminderService()
    
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
        
        let nextDueDate = recurringExpense.nextDueDate()
        let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -recurringExpense.notificationDaysBefore,
            to: nextDueDate
        ) ?? nextDueDate
        
        scheduleNotification(
            for: recurringExpense,
            at: reminderDate
        )
    }
    
    func scheduleAllReminders(from recurringExpenseStore: RecurringExpenseStore) {
        removeAllPendingReminders()
        
        for expense in recurringExpenseStore.activeRecurringExpenses where expense.notificationEnabled {
            scheduleReminders(for: expense)
        }
    }
    
    private func scheduleNotification(for expense: RecurringExpense, at date: Date) {
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
            identifier: "BillReminder_\(expense.id.uuidString)",
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
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["BillReminder_\(expenseId.uuidString)"]
        )
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
}
