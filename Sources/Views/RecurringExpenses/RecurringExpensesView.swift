import SwiftUI

struct RecurringExpensesView: View {
    @EnvironmentObject private var recurringExpenseStore: RecurringExpenseStore
    @State private var showAddRecurring = false
    @State private var selectedExpense: RecurringExpense?
    
    var body: some View {
        NavigationStack {
            BackgroundView {
                if recurringExpenseStore.recurringExpenses.isEmpty {
                    emptyState
                } else {
                    recurringList
                }
            }
            .navigationTitle("Recurring Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddRecurring = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundStyle(AppTheme.ocean)
                }
            }
        }
        .sheet(isPresented: $showAddRecurring) {
            AddRecurringExpenseView(isPresented: $showAddRecurring)
                .environmentObject(recurringExpenseStore)
        }
        .sheet(item: $selectedExpense) { expense in
            EditRecurringExpenseView(isPresented: .constant(true), expense: expense)
                .environmentObject(recurringExpenseStore)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "repeat.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.ink.opacity(0.3))
            
            Text("No recurring expenses")
                .font(AppTheme.title(18))
                .foregroundStyle(AppTheme.ink)
            
            Text("Add recurring payments to automate expense tracking")
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.ink.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Button(action: { showAddRecurring = true }) {
                Text("Add Recurring Expense")
                    .font(AppTheme.body(14))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(AppTheme.ocean)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
    
    private var recurringList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                summaryCard
                
                VStack(spacing: 12) {
                    ForEach(recurringExpenseStore.recurringExpenses) { expense in
                        RecurringExpenseRow(
                            expense: expense,
                            onTap: { selectedExpense = expense },
                            onDelete: { recurringExpenseStore.delete(expense) },
                            onToggle: {
                                var updated = expense
                                updated.isActive.toggle()
                                recurringExpenseStore.update(updated)
                            }
                        )
                    }
                }
            }
            .padding(20)
        }
    }
    
    private var summaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recurring Summary")
                    .font(AppTheme.title(16))
                    .foregroundStyle(AppTheme.ink)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly")
                            .font(AppTheme.body(12))
                            .foregroundStyle(AppTheme.ink.opacity(0.6))
                        
                        Text(Formatters.currencyString(recurringExpenseStore.monthlyRecurringAmount))
                            .font(AppTheme.title(18))
                            .foregroundStyle(AppTheme.ocean)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Yearly")
                            .font(AppTheme.body(12))
                            .foregroundStyle(AppTheme.ink.opacity(0.6))
                        
                        Text(Formatters.currencyString(recurringExpenseStore.totalYearlyAmount))
                            .font(AppTheme.title(18))
                            .foregroundStyle(AppTheme.coral)
                    }
                }
            }
        }
    }
}

struct RecurringExpenseRow: View {
    let expense: RecurringExpense
    let onTap: () -> Void
    let onDelete: () -> Void
    let onToggle: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(expense.title)
                            .font(AppTheme.body(14))
                            .foregroundStyle(AppTheme.ink)
                        
                        if expense.notificationEnabled {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.ocean)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(expense.frequency.label)
                            .font(AppTheme.body(12))
                            .foregroundStyle(AppTheme.ink.opacity(0.6))
                        
                        Text("•")
                            .foregroundStyle(AppTheme.ink.opacity(0.3))
                        
                        Text(expense.category.label)
                            .font(AppTheme.body(12))
                            .foregroundStyle(AppTheme.ink.opacity(0.6))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(Formatters.currencyString(expense.amount))
                        .font(AppTheme.body(14))
                        .foregroundStyle(AppTheme.ink)
                    
                    Text("Yearly: \(Formatters.currencyString(expense.yearlyAmount))")
                        .font(AppTheme.body(11))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                }
            }
            .padding(12)
            .background(AppTheme.cloud.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                onToggle()
            } label: {
                Label(expense.isActive ? "Deactivate" : "Activate", systemImage: expense.isActive ? "pause.circle" : "play.circle")
            }
        }
        .alert("Delete Recurring Expense?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This will remove the recurring expense. Existing generated expenses will remain.")
        }
    }
}

#Preview {
    RecurringExpensesView()
        .environmentObject(RecurringExpenseStore())
}
