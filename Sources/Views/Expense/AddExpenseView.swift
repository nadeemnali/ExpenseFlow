import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject private var expenseStore: ExpenseStore
    @EnvironmentObject private var premiumStore: PremiumFeatureStore

    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var errorMessage: String = ""
    @State private var showSavedAlert: Bool = false
    @State private var savedTitle: String = ""
    @State private var showBillScanner: Bool = false

    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
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

                    if premiumStore.isPremium {
                        Button(action: { showBillScanner = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.viewfinder")
                                Text("Scan Bill")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(AppTheme.cloud.opacity(0.8))
                            .foregroundStyle(AppTheme.ink)
                            .cornerRadius(8)
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
            Text(savedTitle.isEmpty ? "Your expense has been logged." : "\"\(savedTitle)\" was added.")
        }
        .sheet(isPresented: $showBillScanner) {
            if premiumStore.isPremium {
                BillScannerView(premiumStore: premiumStore)
            } else {
                PremiumLockedView(
                    premiumStore: premiumStore,
                    action: { showBillScanner = false },
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

        let expense = Expense(title: title, amount: amount, category: selectedCategory, date: date, notes: notes)
        expenseStore.addExpense(expense)

        savedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        showSavedAlert = true
        title = ""
        amountText = ""
        notes = ""
        date = Date()
        selectedCategory = .food
    }
}
