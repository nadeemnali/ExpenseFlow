import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject private var expenseStore: ExpenseStore
    @EnvironmentObject private var premiumStore: PremiumFeatureStore
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var customCategoryStore: CustomCategoryStore

    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var selectedCustomCategory: CustomCategory?
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var errorMessage: String = ""
    @State private var showSavedAlert: Bool = false
    @State private var savedMessage: String = ""
    @State private var showBillScanner: Bool = false

    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    scanCard
                    SectionHeader(title: "Log expense", subtitle: "Capture your daily spending")

                    GlassCard {
                        VStack(spacing: 16) {
                            TextField("Title", text: $title)
                                .padding(12)
                                .background(AppTheme.cloud.opacity(0.9))
                                .foregroundStyle(AppTheme.ink)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            TextField("Amount", text: $amountText)
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(AppTheme.cloud.opacity(0.9))
                                .foregroundStyle(AppTheme.ink)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Category")
                                    .font(AppTheme.body(12))
                                    .foregroundStyle(AppTheme.ink.opacity(0.6))

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(ExpenseCategory.allCases) { category in
                                            Button {
                                                selectedCategory = category
                                                selectedCustomCategory = nil
                                            } label: {
                                                CategoryPill(category: category)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                                            .stroke(category == selectedCategory ? category.color : .clear, lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                }
                            }

                            if !customCategoryStore.categories.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Custom categories")
                                        .font(AppTheme.body(12))
                                        .foregroundStyle(AppTheme.ink.opacity(0.6))

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(customCategoryStore.categories) { category in
                                                let color = Color(hex: category.colorHex)
                                                Button {
                                                    selectedCustomCategory = category
                                                    selectedCategory = .other
                                                } label: {
                                                    CategoryPill(label: category.name, systemImage: "tag.fill", color: color)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                                                .stroke(selectedCustomCategory?.id == category.id ? color : .clear, lineWidth: 1)
                                                        )
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.compact)

                            TextField("Notes (optional)", text: $notes, axis: .vertical)
                                .lineLimit(2...4)
                                .padding(12)
                                .background(AppTheme.cloud.opacity(0.9))
                                .foregroundStyle(AppTheme.ink)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(AppTheme.body(12))
                            .foregroundStyle(AppTheme.coral)
                    }

                    Button("Save expense") {
                        saveExpense()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabBarPadding()
        }
        .navigationTitle("Add Expense")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Expense saved", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(savedMessage.isEmpty ? "Your expense has been logged." : savedMessage)
        }
        .sheet(isPresented: $showBillScanner) {
            if premiumStore.isPremium {
                BillScannerView(premiumStore: premiumStore) { result in
                    applyOCR(result)
                }
            } else {
                PremiumLockedView(
                    premiumStore: premiumStore,
                    action: {},
                    featureName: "Bill Scanner"
                )
            }
        }
    }

    private func saveExpense() {
        errorMessage = ""
        let cleanAmount = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleanAmount), amount > 0 else {
            errorMessage = "Enter a valid amount."
            return
        }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Add a title for this expense."
            return
        }

        let expense = Expense(
            title: title,
            amount: amount,
            category: selectedCategory,
            customCategoryName: selectedCustomCategory?.name,
            customCategoryColorHex: selectedCustomCategory?.colorHex,
            date: date,
            notes: notes
        )
        expenseStore.addExpense(expense)
        
        // Trigger budget alert notification if enabled
        if settingsStore.budgetAlertsEnabled {
            let currentMonthlySpending = expenseStore.monthlyTotal(for: expense.date)
            BudgetAlertService.shared.checkAndScheduleBudgetAlert(
                currentMonthlySpending: currentMonthlySpending,
                monthlyBudget: settingsStore.monthlyBudget,
                currencyCode: settingsStore.currencyCode
            )
        }

        savedMessage = saveMessage(for: expense)
        showSavedAlert = true
        title = ""
        amountText = ""
        notes = ""
        date = Date()
        selectedCategory = .food
        selectedCustomCategory = nil
    }

    private var scanCard: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.ocean)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan bill")
                        .font(AppTheme.title(16))
                        .foregroundStyle(AppTheme.ink)
                    Text("Auto-fill vendor, amount, and date")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                }

                Spacer()

                Button(premiumStore.isPremium ? "Open" : "Unlock") {
                    showBillScanner = true
                }
                .font(AppTheme.body(13))
                .foregroundStyle(AppTheme.ocean)
                .accessibilityLabel("Scan bill")
            }
        }
    }

    private func applyOCR(_ result: OCRResult) {
        title = result.vendor
        amountText = NSDecimalNumber(decimal: result.amount).stringValue
        date = result.date
        notes = result.description ?? ""
    }

    private func saveMessage(for expense: Expense) -> String {
        let total = expenseStore.monthlyTotal(for: expense.date)
        let remaining = settingsStore.monthlyBudget - total
        if settingsStore.budgetAlertsEnabled && remaining < 0 {
            let over = Formatters.currency(code: settingsStore.currencyCode).string(from: NSNumber(value: abs(remaining))) ?? ""
            return "\"\(expense.title)\" added. You are \(over) over budget this month."
        }
        return "\"\(expense.title)\" was added."
    }
}
