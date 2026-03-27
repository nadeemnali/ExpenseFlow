import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var expenseStore: ExpenseStore
    @EnvironmentObject private var settingsStore: SettingsStore

    private var todayTotal: Double {
        expenseStore.dailyTotal(for: Date())
    }

    private var monthTotal: Double {
        expenseStore.monthlyTotal(for: Date())
    }

    private var remainingBudget: Double {
        max(settingsStore.monthlyBudget - monthTotal, 0)
    }

    var body: some View {
        BackgroundView {
            List {
                header
                    .listRowStyle()
                    .padding(.top, 6)

                statsRow
                    .listRowStyle()

                budgetCard
                    .listRowStyle()

                monthChart
                    .listRowStyle()

                SectionHeader(title: "Recent", subtitle: "Latest expenses logged")
                    .listRowStyle()
                    .padding(.top, 4)

                if recentExpenses.isEmpty {
                    Text("No expenses logged yet.")
                        .font(AppTheme.body(13))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                        .listRowStyle()
                } else {
                    ForEach(recentExpenses) { expense in
                        expenseRow(expense)
                            .listRowStyle()
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    expenseStore.deleteExpense(id: expense.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .tabBarPadding()
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)

    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.ink.opacity(0.6))
            Text("Daily Flow")
                .font(AppTheme.display(28))
                .foregroundStyle(AppTheme.ink)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            MiniStatCard(title: "Today", value: currency(todayTotal), accent: AppTheme.coral)
            MiniStatCard(title: "This month", value: currency(monthTotal), accent: AppTheme.teal)
        }
    }

    private var budgetCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(title: "Budget pulse", subtitle: "Monthly budget progress")
                    Spacer()
                    Text(currency(remainingBudget))
                        .font(AppTheme.title(16))
                        .foregroundStyle(AppTheme.ocean)
                }

                ProgressView(value: min(monthTotal / max(settingsStore.monthlyBudget, 1), 1))
                    .tint(AppTheme.ocean)
                    .scaleEffect(x: 1, y: 1.6, anchor: .center)

                Text("Spent \(currency(monthTotal)) of \(currency(settingsStore.monthlyBudget))")
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.ink.opacity(0.6))
            }
        }
    }

    private var monthChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Last 6 months", subtitle: "Compare monthly totals")

                Chart(expenseStore.totalsByMonth(last: 6), id: \.month) { item in
                    BarMark(
                        x: .value("Month", item.month.shortMonth),
                        y: .value("Total", item.total)
                    )
                    .foregroundStyle(AppTheme.accentGradient)
                    .cornerRadius(8)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
    }

    private var recentExpenses: [Expense] {
        expenseStore.recentExpenses()
    }

    private func expenseRow(_ expense: Expense) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                Circle()
                    .fill(expense.category.color.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: expense.category.systemImage)
                            .foregroundStyle(expense.category.color)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.title)
                        .font(AppTheme.body(14))
                        .foregroundStyle(AppTheme.ink)
                    Text(expense.date.dayLabel)
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.5))
                }

                Spacer()

                Text(currency(expense.amount))
                    .font(AppTheme.title(14))
                    .foregroundStyle(AppTheme.ink)
            }
        }
    }

    private func currency(_ value: Double) -> String {
        Formatters.currency(code: settingsStore.currencyCode).string(from: NSNumber(value: value)) ?? "$0"
    }
}
