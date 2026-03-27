import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject private var expenseStore: ExpenseStore
    @EnvironmentObject private var settingsStore: SettingsStore

    @State private var selectedMonth: Date = Date().startOfMonth

    var body: some View {
        BackgroundView {
            List {
                SectionHeader(title: "History", subtitle: "Your past months, visualized")
                    .listRowStyle()
                    .padding(.top, 6)

                monthPicker
                    .listRowStyle()

                trendChart
                    .listRowStyle()

                categoryChart
                    .listRowStyle()

                SectionHeader(title: "Entries", subtitle: "Logged expenses")
                    .listRowStyle()
                    .padding(.top, 4)

                if monthItems.isEmpty {
                    Text("No expenses logged yet.")
                        .font(AppTheme.body(13))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                        .listRowStyle()
                } else {
                    ForEach(monthItems) { expense in
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
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var monthOptions: [Date] {
        let calendar = Calendar.current
        let current = Date().startOfMonth
        return (0..<12).map { offset in
            calendar.date(byAdding: .month, value: -offset, to: current) ?? current
        }
    }

    private var monthPicker: some View {
        GlassCard {
            HStack {
                Text("Month")
                    .font(AppTheme.title(16))
                    .foregroundStyle(AppTheme.ink)

                Spacer()

                Picker("Month", selection: $selectedMonth) {
                    ForEach(monthOptions, id: \.self) { month in
                        Text(month.monthYear)
                            .tag(month)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var trendChart: some View {
        let data = expenseStore.totalsByMonth(last: 12)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "12-month trend", subtitle: "Monthly totals")

                Chart(data, id: \.month) { item in
                    LineMark(
                        x: .value("Month", item.month.shortMonth),
                        y: .value("Total", item.total)
                    )
                    .foregroundStyle(AppTheme.ocean)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Month", item.month.shortMonth),
                        y: .value("Total", item.total)
                    )
                    .foregroundStyle(AppTheme.ocean.opacity(0.2))
                }
                .frame(height: 200)
            }
        }
    }

    private var categoryChart: some View {
        let data = expenseStore.totalsByCategory(forMonth: selectedMonth)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Category mix", subtitle: selectedMonth.monthYear)

                if data.isEmpty {
                    Text("No expenses yet for this month.")
                        .font(AppTheme.body(13))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                } else {
                    Chart(data, id: \.category) { item in
                        BarMark(
                            x: .value("Category", item.category.label),
                            y: .value("Total", item.total)
                        )
                        .foregroundStyle(item.category.color)
                        .cornerRadius(6)
                    }
                    .frame(height: 200)
                }
            }
        }
    }

    private var monthItems: [Expense] {
        let start = selectedMonth.startOfMonth
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? selectedMonth
        return expenseStore.expenses
            .filter { $0.date >= start && $0.date < end }
            .sorted(by: { $0.date > $1.date })
    }

    private func expenseRow(_ expense: Expense) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                CategoryPill(category: expense.category)

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
