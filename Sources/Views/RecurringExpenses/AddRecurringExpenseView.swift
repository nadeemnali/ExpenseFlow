import SwiftUI

struct AddRecurringExpenseView: View {
    @EnvironmentObject private var recurringExpenseStore: RecurringExpenseStore
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    @State private var amount: Double = 0
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var selectedFrequency: RecurrenceFrequency = .monthly
    @State private var startDate: Date = Date()
    @State private var notificationEnabled: Bool = true
    @State private var notes: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            BackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                FormFieldLabel(text: "Title")
                                TextField("Enter title", text: $title)
                                    .keyboardType(.default)
                                    .padding(12)
                                    .background(AppTheme.cloud.opacity(0.9))
                                    .foregroundStyle(AppTheme.ink)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                
                                FormFieldLabel(text: "Amount")
                                TextField("0.00", value: $amount, formatter: Formatters.number)
                                    .keyboardType(.decimalPad)
                                    .padding(12)
                                    .background(AppTheme.cloud.opacity(0.9))
                                    .foregroundStyle(AppTheme.ink)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                
                                FormFieldLabel(text: "Category")
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(ExpenseCategory.allCases) { category in
                                        Text(category.label).tag(category)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                FormFieldLabel(text: "Frequency")
                                Picker("Frequency", selection: $selectedFrequency) {
                                    ForEach(RecurrenceFrequency.allCases) { frequency in
                                        Text(frequency.label).tag(frequency)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                FormFieldLabel(text: "Start Date")
                                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Toggle(isOn: $notificationEnabled) {
                                    Text("Enable reminders")
                                        .font(AppTheme.body(14))
                                }
                                .tint(AppTheme.ocean)
                                
                                if !notes.isEmpty {
                                    FormFieldLabel(text: "Notes")
                                    TextEditor(text: $notes)
                                        .frame(height: 80)
                                        .scrollContentBackground(.hidden)
                                        .padding(12)
                                        .background(AppTheme.cloud.opacity(0.9))
                                        .foregroundStyle(AppTheme.ink)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                        
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                                    .font(AppTheme.body(13))
                            }
                            .foregroundStyle(AppTheme.coral)
                            .padding(12)
                            .background(AppTheme.coral.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Recurring Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { saveRecurringExpense() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || amount <= 0)
                }
            }
        }
    }
    
    private func saveRecurringExpense() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Title is required"
            return
        }
        
        guard amount > 0 else {
            errorMessage = "Amount must be greater than 0"
            return
        }
        
        let recurring = RecurringExpense(
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amount,
            category: selectedCategory,
            frequency: selectedFrequency,
            startDate: startDate,
            isActive: true,
            notificationEnabled: notificationEnabled,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        
        recurringExpenseStore.add(recurring)
        isPresented = false
    }
}

struct EditRecurringExpenseView: View {
    @EnvironmentObject private var recurringExpenseStore: RecurringExpenseStore
    @Binding var isPresented: Bool
    let expense: RecurringExpense
    
    @State private var title: String = ""
    @State private var amount: Double = 0
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var selectedFrequency: RecurrenceFrequency = .monthly
    @State private var startDate: Date = Date()
    @State private var notificationEnabled: Bool = true
    @State private var notes: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            BackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                FormFieldLabel(text: "Title")
                                TextField("Enter title", text: $title)
                                    .keyboardType(.default)
                                    .padding(12)
                                    .background(AppTheme.cloud.opacity(0.9))
                                    .foregroundStyle(AppTheme.ink)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                
                                FormFieldLabel(text: "Amount")
                                TextField("0.00", value: $amount, formatter: Formatters.number)
                                    .keyboardType(.decimalPad)
                                    .padding(12)
                                    .background(AppTheme.cloud.opacity(0.9))
                                    .foregroundStyle(AppTheme.ink)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                
                                FormFieldLabel(text: "Category")
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(ExpenseCategory.allCases) { category in
                                        Text(category.label).tag(category)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                FormFieldLabel(text: "Frequency")
                                Picker("Frequency", selection: $selectedFrequency) {
                                    ForEach(RecurrenceFrequency.allCases) { frequency in
                                        Text(frequency.label).tag(frequency)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                FormFieldLabel(text: "Start Date")
                                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Toggle(isOn: $notificationEnabled) {
                                    Text("Enable reminders")
                                        .font(AppTheme.body(14))
                                }
                                .tint(AppTheme.ocean)
                                
                                if !notes.isEmpty {
                                    FormFieldLabel(text: "Notes")
                                    TextEditor(text: $notes)
                                        .frame(height: 80)
                                        .scrollContentBackground(.hidden)
                                        .padding(12)
                                        .background(AppTheme.cloud.opacity(0.9))
                                        .foregroundStyle(AppTheme.ink)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                        
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                                    .font(AppTheme.body(13))
                            }
                            .foregroundStyle(AppTheme.coral)
                            .padding(12)
                            .background(AppTheme.coral.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Recurring Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Update") { updateRecurringExpense() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || amount <= 0)
                }
            }
        }
        .onAppear {
            title = expense.title
            amount = expense.amount
            selectedCategory = expense.category
            selectedFrequency = expense.frequency
            startDate = expense.startDate
            notificationEnabled = expense.notificationEnabled
            notes = expense.notes
        }
    }
    
    private func updateRecurringExpense() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Title is required"
            return
        }
        
        guard amount > 0 else {
            errorMessage = "Amount must be greater than 0"
            return
        }
        
        var updated = expense
        updated.title = title.trimmingCharacters(in: .whitespaces)
        updated.amount = amount
        updated.category = selectedCategory
        updated.frequency = selectedFrequency
        updated.startDate = startDate
        updated.notificationEnabled = notificationEnabled
        updated.notes = notes.trimmingCharacters(in: .whitespaces)
        
        recurringExpenseStore.update(updated)
        isPresented = false
    }
}

struct FormFieldLabel: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(AppTheme.body(12))
            .foregroundStyle(AppTheme.ink.opacity(0.6))
    }
}

#Preview {
    AddRecurringExpenseView(isPresented: .constant(true))
        .environmentObject(RecurringExpenseStore())
}
