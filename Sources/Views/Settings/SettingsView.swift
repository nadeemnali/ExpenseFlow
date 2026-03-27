import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var expenseStore: ExpenseStore
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var onboardingStore: OnboardingStore

    private let currencyOptions = ["USD", "EUR", "GBP", "JPY", "AUD", "CAD", "INR"]

    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    SectionHeader(title: "Settings", subtitle: "Make ExpenseFlow yours")

                    accountCard
                    preferencesCard
                    dataCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabBarPadding()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var accountCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Account")
                    .font(AppTheme.title(18))

                HStack {
                    Text(authStore.currentEmail.isEmpty ? "Signed out" : authStore.currentEmail)
                        .font(AppTheme.body(14))
                        .foregroundStyle(AppTheme.ink.opacity(0.7))

                    Spacer()

                    Button("Log out") {
                        authStore.logOut()
                    }
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.coral)
                }
            }
        }
    }

    private var preferencesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Preferences")
                    .font(AppTheme.title(18))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Monthly budget")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))

                    TextField("Budget", value: $settingsStore.monthlyBudget, formatter: Formatters.number)
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .background(AppTheme.cloud.opacity(0.9))
                        .foregroundStyle(AppTheme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Currency")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))

                    Picker("Currency", selection: $settingsStore.currencyCode) {
                        ForEach(currencyOptions, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Start of week")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))

                    Picker("Week start", selection: $settingsStore.startOfWeek) {
                        ForEach(WeekStart.allCases) { day in
                            Text(day.label).tag(day)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))

                    Picker("Theme", selection: $settingsStore.colorScheme) {
                        ForEach(ColorSchemeOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle(isOn: $settingsStore.notificationsEnabled) {
                    Text("Notifications")
                        .font(AppTheme.body(14))
                }
                .tint(AppTheme.ocean)
            }
        }
    }

    private var dataCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Data")
                    .font(AppTheme.title(18))

                Text("Need a clean slate or demo data?")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.ink.opacity(0.6))

                HStack(spacing: 12) {
                    Button("Load sample") {
                        expenseStore.resetToSample()
                    }
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.ocean)

                    Button("Clear all") {
                        expenseStore.clearAll()
                    }
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.coral)
                }

                Button("Replay onboarding") {
                    onboardingStore.reset()
                }
                .font(AppTheme.body(13))
                .foregroundStyle(AppTheme.ink.opacity(0.7))
            }
        }
    }
}
