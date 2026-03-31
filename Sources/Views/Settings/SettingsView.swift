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

                    Menu {
                        Picker("Currency", selection: $settingsStore.currencyCode) {
                            ForEach(currencyOptions, id: \.self) { code in
                                Text(code).tag(code)
                            }
                        }
                    } label: {
                        HStack {
                            Text(settingsStore.currencyCode)
                                .font(AppTheme.body(14))
                                .foregroundStyle(AppTheme.ink)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.ink.opacity(0.6))
                        }
                        .padding(12)
                        .background(AppTheme.cloud.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
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

                Text("Export, manage, or reset your data")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.ink.opacity(0.6))

                VStack(spacing: 8) {
                    Button(action: { exportDataAsCSV() }) {
                        HStack {
                            Image(systemName: "arrow.up.doc")
                            Text("Export as CSV")
                        }
                        .font(AppTheme.body(13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(AppTheme.ocean)
                    }
                    
                    Button("Load sample") {
                        expenseStore.resetToSample()
                    }
                    .font(AppTheme.body(13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(AppTheme.ocean)

                    Button("Clear all") {
                        expenseStore.clearAll()
                    }
                    .font(AppTheme.body(13))
                    .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private func exportDataAsCSV() {
        let csvData = generateCSV()
        let filename = "ExpenseFlow_\(Date().formatted(date: .abbreviated, time: .omitted)).csv"
        
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = url.appendingPathComponent(filename)
        
        do {
            try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
            
            var urlsToShare = [fileURL]
            
            DispatchQueue.main.async {
                let activityViewController = UIActivityViewController(activityItems: urlsToShare, applicationActivities: nil)
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    rootViewController.present(activityViewController, animated: true)
                }
            }
        } catch {
            AppLogger.error("Failed to create CSV export", error: error, category: .storage)
        }
    }
    
    private func generateCSV() -> String {
        var csv = "Date,Title,Category,Amount,Notes\n"
        
        let sortedExpenses = expenseStore.expenses.sorted { $0.date > $1.date }
        
        for expense in sortedExpenses {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: expense.date)
            
            let escapedTitle = csvEscapeField(expense.title)
            let escapedCategory = expense.category.label
            let escapedNotes = csvEscapeField(expense.notes)
            
            let line = "\(dateString),\(escapedTitle),\(escapedCategory),\(expense.amount),\(escapedNotes)\n"
            csv.append(line)
        }
        
        return csv
    }
    
    private func csvEscapeField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}
