import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject private var expenseStore: ExpenseStore
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var customCategoryStore: CustomCategoryStore

    @State private var selectedMonth: Date = Date().startOfMonth
    @State private var searchText: String = ""
    @State private var selectedFilter: CategoryFilter = .all
    @State private var sortOption: SortOption = .dateDesc
    @State private var selectedExpense: Expense?

    var body: some View {
        BackgroundView {
            List {
                SectionHeader(title: "History", subtitle: "Your past months, visualized")
                    .listRowStyle()
                    .padding(.top, 6)

                monthPicker
                    .listRowStyle()

                filterControls
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
                        Button {
                            selectedExpense = expense
                        } label: {
                            expenseRow(expense)
                        }
                        .buttonStyle(.plain)
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
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search expenses")
        .sheet(item: $selectedExpense) { expense in
            NavigationStack {
                EditExpenseView(expense: expense)
            }
        }
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

    private var filterControls: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Text("Filter")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))

                    Spacer()

                    Menu {
                        ForEach(availableFilters) { filter in
                            Button(filter.label) {
                                selectedFilter = filter
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedFilter.label)
                                .font(AppTheme.body(13))
                                .foregroundStyle(AppTheme.ink)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppTheme.ink.opacity(0.6))
                        }
                    }
                }

                HStack {
                    Text("Sort")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))

                    Spacer()

                    Menu {
                        ForEach(SortOption.allCases) { option in
                            Button(option.label) {
                                sortOption = option
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(sortOption.label)
                                .font(AppTheme.body(13))
                                .foregroundStyle(AppTheme.ink)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppTheme.ink.opacity(0.6))
                        }
                    }
                }
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
        let data = categoryChartData
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Category mix", subtitle: selectedMonth.monthYear)

                if data.isEmpty {
                    Text("No expenses yet for this month.")
                        .font(AppTheme.body(13))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                } else {
                    Chart(data, id: \.label) { item in
                        BarMark(
                            x: .value("Category", item.label),
                            y: .value("Total", item.total)
                        )
                        .foregroundStyle(item.color)
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
        let monthlyExpenses = expenseStore.expenses
            .filter { $0.date >= start && $0.date < end }

        let searched = monthlyExpenses.filter { expense in
            guard !searchText.isEmpty else { return true }
            let query = searchText.lowercased()
            return expense.title.lowercased().contains(query)
                || expense.notes.lowercased().contains(query)
                || expense.displayCategoryLabel.lowercased().contains(query)
        }

        let filtered = searched.filter { expense in
            switch selectedFilter {
            case .all:
                return true
            case .standard(let category):
                if category == .other {
                    return expense.category == .other && expense.customCategoryName == nil
                }
                return expense.category == category
            case .custom(let custom):
                return expense.customCategoryName?.caseInsensitiveCompare(custom.name) == .orderedSame
            }
        }

        switch sortOption {
        case .dateDesc:
            return filtered.sorted { $0.date > $1.date }
        case .dateAsc:
            return filtered.sorted { $0.date < $1.date }
        case .amountDesc:
            return filtered.sorted { $0.amount > $1.amount }
        case .amountAsc:
            return filtered.sorted { $0.amount < $1.amount }
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                CategoryPill(
                    category: expense.category,
                    customLabel: expense.customCategoryName,
                    customColor: expense.customCategoryColor,
                    customSystemImage: expense.customCategoryName == nil ? nil : "tag.fill"
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

private extension HistoryView {
    var availableFilters: [CategoryFilter] {
        var filters: [CategoryFilter] = [.all]
        filters.append(contentsOf: ExpenseCategory.allCases.map { .standard($0) })
        filters.append(contentsOf: customCategoryStore.categories.map { .custom($0) })
        return filters
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case dateDesc
        case dateAsc
        case amountDesc
        case amountAsc

        var id: String { rawValue }

        var label: String {
            switch self {
            case .dateDesc: return "Date (newest)"
            case .dateAsc: return "Date (oldest)"
            case .amountDesc: return "Amount (high)"
            case .amountAsc: return "Amount (low)"
            }
        }
    }

    enum CategoryFilter: Hashable, Identifiable {
        case all
        case standard(ExpenseCategory)
        case custom(CustomCategory)

        var id: String {
            switch self {
            case .all: return "all"
            case .standard(let category): return "standard-\(category.rawValue)"
            case .custom(let category): return "custom-\(category.id.uuidString)"
            }
        }

        var label: String {
            switch self {
            case .all:
                return "All categories"
            case .standard(let category):
                return category.label
            case .custom(let category):
                return category.name
            }
        }
    }

    struct CategoryChartItem: Identifiable {
        let id = UUID()
        let label: String
        let total: Double
        let color: Color
    }

    var categoryChartData: [CategoryChartItem] {
        let start = selectedMonth.startOfMonth
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? selectedMonth
        let monthlyExpenses = expenseStore.expenses
            .filter { $0.date >= start && $0.date < end }

        let grouped = Dictionary(grouping: monthlyExpenses) { $0.displayCategoryLabel }
        return grouped.map { label, expenses in
            let total = expenses.reduce(0) { $0 + $1.amount }
            let color = expenses.first?.displayCategoryColor ?? AppTheme.ocean
            return CategoryChartItem(label: label, total: total, color: color)
        }
        .sorted { $0.total > $1.total }
    }
}
