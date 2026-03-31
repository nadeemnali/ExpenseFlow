import SwiftUI

struct SubscriptionsVaultView: View {
    @EnvironmentObject private var recurringExpenseStore: RecurringExpenseStore
    
    var body: some View {
        NavigationStack {
            BackgroundView {
                if recurringExpenseStore.subscriptions.isEmpty {
                    emptyState
                } else {
                    subscriptionsContent
                }
            }
            .navigationTitle("Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "Apps.iphone")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.ink.opacity(0.3))
            
            Text("No active subscriptions")
                .font(AppTheme.title(18))
                .foregroundStyle(AppTheme.ink)
            
            Text("Track your recurring subscriptions and entertainment expenses")
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.ink.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
    
    private var subscriptionsContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                summaryCard
                subscriptionsList
            }
            .padding(20)
        }
    }
    
    private var summaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Subscription Summary")
                    .font(AppTheme.title(16))
                    .foregroundStyle(AppTheme.ink)
                
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Monthly Cost")
                                .font(AppTheme.body(12))
                                .foregroundStyle(AppTheme.ink.opacity(0.6))
                            
                            Text(Formatters.currencyString(monthlySubscriptionCost()))
                                .font(AppTheme.title(20))
                                .foregroundStyle(AppTheme.ocean)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Yearly Cost")
                                .font(AppTheme.body(12))
                                .foregroundStyle(AppTheme.ink.opacity(0.6))
                            
                            Text(Formatters.currencyString(yearlySubscriptionCost()))
                                .font(AppTheme.title(20))
                                .foregroundStyle(AppTheme.coral)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 8) {
                        Text("\(recurringExpenseStore.subscriptions.count)")
                            .font(AppTheme.title(32))
                            .foregroundStyle(AppTheme.ink)
                        
                        Text("Active")
                            .font(AppTheme.body(12))
                            .foregroundStyle(AppTheme.ink.opacity(0.6))
                    }
                }
            }
        }
    }
    
    private var subscriptionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Subscriptions")
                .font(AppTheme.title(16))
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(recurringExpenseStore.subscriptions.sorted { $0.yearlyAmount > $1.yearlyAmount }) { subscription in
                    SubscriptionCard(subscription: subscription)
                }
            }
        }
    }
    
    private func monthlySubscriptionCost() -> Double {
        recurringExpenseStore.subscriptions.reduce(0) { total, expense in
            let occurrencesPerMonth = 30.0 / Double(expense.frequency.daysInterval)
            return total + (expense.amount * occurrencesPerMonth)
        }
    }
    
    private func yearlySubscriptionCost() -> Double {
        recurringExpenseStore.subscriptions.reduce(0) { $0 + $1.yearlyAmount }
    }
}

struct SubscriptionCard: View {
    let subscription: RecurringExpense
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(subscription.title)
                        .font(AppTheme.body(14))
                        .foregroundStyle(AppTheme.ink)
                    
                    if subscription.notificationEnabled {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.ocean)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(subscription.frequency.label)
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                    
                    Text("•")
                        .foregroundStyle(AppTheme.ink.opacity(0.3))
                    
                    Text("Next: \(formattedNextDate(subscription.nextDueDate()))")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(Formatters.currencyString(subscription.amount) + "/" + subscription.frequency.rawValue.prefix(3).lowercased())
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.ink)
                
                Text("≈ \(Formatters.currencyString(subscription.yearlyAmount))/yr")
                    .font(AppTheme.body(11))
                    .foregroundStyle(AppTheme.ink.opacity(0.6))
            }
        }
        .padding(12)
        .background(AppTheme.cloud.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func formattedNextDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    SubscriptionsVaultView()
        .environmentObject(RecurringExpenseStore())
}
