import SwiftUI

@main
struct ExpenseFlowApp: App {
    @StateObject private var authStore = AuthStore()
    @StateObject private var expenseStore = ExpenseStore()
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var onboardingStore = OnboardingStore()
    @StateObject private var recurringExpenseStore = RecurringExpenseStore()
    @StateObject private var premiumStore = PremiumFeatureStore()
    @StateObject private var customCategoryStore = CustomCategoryStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(authStore)
                .environmentObject(expenseStore)
                .environmentObject(settingsStore)
                .environmentObject(onboardingStore)
                .environmentObject(recurringExpenseStore)
                .environmentObject(premiumStore)
                .environmentObject(customCategoryStore)
                .preferredColorScheme(settingsStore.preferredColorScheme)
        }
    }
}
