import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var expenseStore: ExpenseStore
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var onboardingStore: OnboardingStore
    @EnvironmentObject private var premiumStore: PremiumFeatureStore
    @EnvironmentObject private var recurringExpenseStore: RecurringExpenseStore
    @EnvironmentObject private var customCategoryStore: CustomCategoryStore

    @State private var csvDocument = CSVDocument(text: "")
    @State private var isExportingCSV = false
    @State private var backupDocument = BackupDocument(package: BackupPackage(createdAt: Date(), expenses: [], recurringExpenses: [], settings: AppSettings(monthlyBudget: 0, currencyCode: "USD", notificationsEnabled: true, budgetAlertsEnabled: true, startOfWeek: .monday, colorScheme: .system), customCategories: []))
    @State private var isExportingBackup = false
    @State private var isImportingBackup = false
    @State private var importMessage: String = ""
    @State private var showImportAlert = false

    private let currencyOptions = ["USD", "EUR", "GBP", "JPY", "AUD", "CAD", "INR"]

    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    SectionHeader(title: "Settings", subtitle: "Make ExpenseFlow yours")

                    accountCard
                    quickLinksCard
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
        .fileExporter(
            isPresented: $isExportingCSV,
            document: csvDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "ExpenseFlow-Expenses"
        ) { _ in }
        .fileExporter(
            isPresented: $isExportingBackup,
            document: backupDocument,
            contentType: .json,
            defaultFilename: "ExpenseFlow-Backup"
        ) { _ in }
        .fileImporter(
            isPresented: $isImportingBackup,
            allowedContentTypes: [.json]
        ) { result in
            handleBackupImport(result)
        }
        .alert("Backup", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importMessage)
        }
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

    private var quickLinksCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Links")
                    .font(AppTheme.title(18))

                NavigationLink {
                    PremiumFeaturesView()
                } label: {
                    settingsLinkRow(title: "Premium features", subtitle: premiumStore.isPremium ? "Unlocked" : "Bill scanner & more", systemImage: "crown.fill")
                }

                NavigationLink {
                    SubscriptionsVaultView()
                        .environmentObject(recurringExpenseStore)
                } label: {
                    settingsLinkRow(title: "Subscriptions vault", subtitle: "Track recurring subscriptions", systemImage: "sparkles")
                }

                NavigationLink {
                    CategoryManagerView()
                } label: {
                    settingsLinkRow(title: "Custom categories", subtitle: "Add your own labels", systemImage: "tag.fill")
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

                Toggle(isOn: $settingsStore.budgetAlertsEnabled) {
                    Text("Budget alerts")
                        .font(AppTheme.body(14))
                }
                .tint(AppTheme.ocean)
            }
        }
    }

    private var dataCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Data & Backup")
                    .font(AppTheme.title(18))

                Text("Export, import, or reset your data")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.ink.opacity(0.6))

                VStack(spacing: 8) {
                    Button(action: exportCSV) {
                        HStack {
                            Image(systemName: "arrow.up.doc")
                            Text("Export CSV")
                        }
                        .font(AppTheme.body(13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(AppTheme.ocean)
                    }

                    Button(action: exportBackup) {
                        HStack {
                            Image(systemName: "externaldrive.badge.icloud")
                            Text("Export Backup")
                        }
                        .font(AppTheme.body(13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(AppTheme.ocean)
                    }

                    Button(action: { isImportingBackup = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Backup")
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

    private func settingsLinkRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.ocean)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.body(14))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.ink.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.ink.opacity(0.4))
        }
    }

    private func exportCSV() {
        let csvString = CSVExporter.makeCSV(expenses: expenseStore.expenses)
        csvDocument = CSVDocument(text: csvString)
        isExportingCSV = true
    }

    private func exportBackup() {
        let package = BackupPackage(
            createdAt: Date(),
            expenses: expenseStore.expenses,
            recurringExpenses: recurringExpenseStore.recurringExpenses,
            settings: settingsStore.snapshot,
            customCategories: customCategoryStore.categories
        )
        backupDocument = BackupDocument(package: package)
        isExportingBackup = true
    }

    private func handleBackupImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode(BackupPackage.self, from: data)
                expenseStore.replaceAll(decoded.expenses)
                recurringExpenseStore.replaceAll(decoded.recurringExpenses)
                settingsStore.apply(decoded.settings)
                customCategoryStore.replaceAll(decoded.customCategories)
                importMessage = "Backup imported successfully."
            } catch {
                importMessage = "Failed to import backup: \(error.localizedDescription)"
            }
        case .failure(let error):
            importMessage = "Failed to import backup: \(error.localizedDescription)"
        }
        showImportAlert = true
    }
}
