import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var onboardingStore: OnboardingStore
    @EnvironmentObject private var expenseStore: ExpenseStore
    @EnvironmentObject private var recurringExpenseStore: RecurringExpenseStore
    @EnvironmentObject private var settingsStore: SettingsStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if onboardingStore.hasSeenOnboarding {
                AuthRootView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: onboardingStore.hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.35), value: showSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation {
                    showSplash = false
                }
            }

            synchronizeRecurringFeatures()
            synchronizeBudgetAlerts()
        }
        .onChange(of: recurringExpenseStore.recurringExpenses) { _ in
            synchronizeRecurringFeatures()
        }
        .onChange(of: settingsStore.notificationsEnabled) { _ in
            synchronizeReminderSchedule()
        }
        .onChange(of: settingsStore.budgetAlertsEnabled) { newValue in
            if newValue {
                synchronizeBudgetAlerts()
            } else {
                BudgetAlertService.shared.clearBudgetAlerts()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else { return }
            synchronizeRecurringFeatures()
            synchronizeBudgetAlerts()
        }
    }

    private func synchronizeRecurringFeatures() {
        expenseStore.autoGenerateRecurringExpenses(from: recurringExpenseStore)
        synchronizeReminderSchedule()
    }

    private func synchronizeReminderSchedule() {
        BillReminderService.shared.syncReminders(
            isEnabled: settingsStore.notificationsEnabled,
            from: recurringExpenseStore,
            currencyCode: settingsStore.currencyCode
        )
    }
    
    private func synchronizeBudgetAlerts() {
        guard settingsStore.budgetAlertsEnabled else {
            BudgetAlertService.shared.clearBudgetAlerts()
            return
        }
        
        let currentMonthlySpending = expenseStore.monthlyTotal(for: Date())
        BudgetAlertService.shared.checkAndScheduleBudgetAlert(
            currentMonthlySpending: currentMonthlySpending,
            monthlyBudget: settingsStore.monthlyBudget,
            currencyCode: settingsStore.currencyCode
        )
    }
}
