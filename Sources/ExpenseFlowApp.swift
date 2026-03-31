import SwiftUI
import UserNotifications
import StoreKit

@main
struct ExpenseFlowApp: App {
    @StateObject private var authStore = AuthStore()
    @StateObject private var expenseStore = ExpenseStore()
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var onboardingStore = OnboardingStore()
    @StateObject private var recurringExpenseStore = RecurringExpenseStore()
    @StateObject private var premiumStore = PremiumFeatureStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(authStore)
                .environmentObject(expenseStore)
                .environmentObject(settingsStore)
                .environmentObject(onboardingStore)
                .environmentObject(recurringExpenseStore)
                .environmentObject(premiumStore)
                .preferredColorScheme(settingsStore.preferredColorScheme)
                .onAppear {
                    setupNotifications()
                    autoGenerateRecurringExpenses()
                }
        }
    }
    
    private func setupNotifications() {
        BillReminderService.shared.requestNotificationPermission { granted in
            if granted {
                AppLogger.log("Notification permission granted", category: .general, level: .debug)
                BillReminderService.shared.scheduleAllReminders(from: recurringExpenseStore)
            }
        }
    }
    
    private func autoGenerateRecurringExpenses() {
        expenseStore.autoGenerateRecurringExpenses(from: recurringExpenseStore)
    }
}


