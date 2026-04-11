import SwiftUI

struct EditExpenseView: View {
    @EnvironmentObject private var expenseStore: ExpenseStore
    @EnvironmentObject private var customCategoryStore: CustomCategoryStore
    @Environment(\.dismiss) private var dismiss

    let expense: Expense

    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var selectedCustomCategory: CustomCategory?
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var errorMessage: String = ""

    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(title: "Edit expense", subtitle: "Update your entry")

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

                    Button("Save changes") {
                        updateExpense()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Delete expense") {
                        expenseStore.deleteExpense(id: expense.id)
                        dismiss()
                    }
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.coral)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabBarPadding()
        }
        .navigationTitle("Edit Expense")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadExpense)
    }

    private func loadExpense() {
        title = expense.title
        amountText = String(format: "%.2f", expense.amount)
        selectedCategory = expense.category
        date = expense.date
        notes = expense.notes
        if let customName = expense.customCategoryName,
           let match = customCategoryStore.category(named: customName) {
            selectedCustomCategory = match
        } else {
            selectedCustomCategory = nil
        }
    }

    private func updateExpense() {
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

        let updated = Expense(
            id: expense.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            category: selectedCategory,
            customCategoryName: selectedCustomCategory?.name,
            customCategoryColorHex: selectedCustomCategory?.colorHex,
            date: date,
            notes: notes
        )
        expenseStore.updateExpense(updated)
        dismiss()
    }
}

#Preview {
    EditExpenseView(expense: Expense(title: "Coffee", amount: 5, category: .food, date: Date()))
        .environmentObject(ExpenseStore())
        .environmentObject(CustomCategoryStore())
}
