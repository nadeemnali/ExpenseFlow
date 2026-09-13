import Foundation
import UserNotifications
import os.log

final class BudgetAlertService {
    static let shared = BudgetAlertService()
    
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
    
    func checkAndScheduleBudgetAlert(
        currentMonthlySpending: Double,
        monthlyBudget: Double,
        currencyCode: String = "USD"
    ) {
        guard monthlyBudget > 0, currentMonthlySpending > 0 else {
            return
        }
        
        let percentageUsed = (currentMonthlySpending / monthlyBudget) * 100
        
        // Schedule alerts at 50%, 75%, 90%, and 100% of budget
        let thresholds: [(percentage: Double, title: String)] = [
            (100, "Budget Limit Reached"),
            (90, "Budget Warning"),
            (75, "Budget Alert"),
            (50, "Budget Milestone")
        ]
        
        for (threshold, title) in thresholds {
            if percentageUsed >= threshold && !hasAlertBeenShown(for: threshold, month: Date()) {
                scheduleAlert(
                    title: title,
                    currentSpending: currentMonthlySpending,
                    budget: monthlyBudget,
                    percentage: percentageUsed,
                    currencyCode: currencyCode,
                    threshold: threshold
                )
            }
        }
    }
    
    private func scheduleAlert(
        title: String,
        currentSpending: Double,
        budget: Double,
        percentage: Double,
        currencyCode: String,
        threshold: Double
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = currencyCode
        
        let spendingStr = currencyFormatter.string(from: NSNumber(value: currentSpending)) ?? "$\(currentSpending)"
        let budgetStr = currencyFormatter.string(from: NSNumber(value: budget)) ?? "$\(budget)"
        
        content.body = "You've spent \(spendingStr) of \(budgetStr) (\(String(format: "%.0f", percentage))%)"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        let userInfo: [AnyHashable: Any] = [
            "type": "budget_alert",
            "threshold": threshold,
            "spending": currentSpending,
            "budget": budget
        ]
        content.userInfo = userInfo
        
        // Schedule notification to be delivered immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: budgetAlertIdentifier(for: threshold),
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                AppLogger.error("Failed to schedule budget alert", error: error, category: .general)
            } else {
                AppLogger.log("Scheduled budget alert at \(threshold)%", category: .general, level: .debug)
                self.markAlertAsShown(for: threshold, month: Date())
            }
        }
    }
    
    func clearBudgetAlerts() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                budgetAlertIdentifier(for: 50),
                budgetAlertIdentifier(for: 75),
                budgetAlertIdentifier(for: 90),
                budgetAlertIdentifier(for: 100)
            ]
        )
        
        // Clear alert tracking for new month
        let calendar = Calendar.current
        let startOfMonth = calendar.startOfDay(for: Date()).startOfMonth
        UserDefaults.standard.removeObject(forKey: budgetAlertTrackerKey(for: startOfMonth))
    }
    
    private func hasAlertBeenShown(for threshold: Double, month: Date) -> Bool {
        let key = budgetAlertTrackerKey(for: month)
        let shownAlerts = UserDefaults.standard.stringArray(forKey: key) ?? []
        return shownAlerts.contains(String(Int(threshold)))
    }
    
    private func markAlertAsShown(for threshold: Double, month: Date) {
        let key = budgetAlertTrackerKey(for: month)
        var shownAlerts = UserDefaults.standard.stringArray(forKey: key) ?? []
        shownAlerts.append(String(Int(threshold)))
        UserDefaults.standard.set(shownAlerts, forKey: key)
    }
    
    private func budgetAlertIdentifier(for threshold: Double) -> String {
        "BudgetAlert_\(Int(threshold))"
    }
    
    private func budgetAlertTrackerKey(for month: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return "ExpenseFlow.budgetAlertShown.\(formatter.string(from: month))"
    }
}
