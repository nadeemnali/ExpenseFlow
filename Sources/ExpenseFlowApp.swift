import SwiftUI

@main
struct ExpenseFlowApp: App {
    @StateObject private var authStore = AuthStore()
    @StateObject private var expenseStore = ExpenseStore()
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var onboardingStore = OnboardingStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(authStore)
                .environmentObject(expenseStore)
                .environmentObject(settingsStore)
                .environmentObject(onboardingStore)
                .preferredColorScheme(settingsStore.preferredColorScheme)
        }
    }
}


