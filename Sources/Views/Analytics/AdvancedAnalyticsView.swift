import SwiftUI
import Charts

/// Advanced analytics screen with annual reports and trends
struct AdvancedAnalyticsView: View {
    @ObservedObject var expenseStore: ExpenseStore
    @StateObject private var analyticsService = AdvancedAnalyticsService()
    
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showMonthComparison = false
    
    var availableYears: [Int] {
        let years = Set(expenseStore.expenses.map { Calendar.current.component(.year, from: $0.date) })
        return years.sorted().reversed()
    }
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    SectionHeader(title: "Advanced Analytics", subtitle: "Detailed spending insights")
                    
                    // Year selector
                    if !availableYears.isEmpty {
                        Picker("Year", selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text("\(year)").tag(year)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                    }
                    
                    // Annual report
                    let report = analyticsService.annualReport(for: selectedYear, from: expenseStore.expenses)
                    
                    annualSummaryCard(report)
                    
                    // Monthly breakdown chart
                    monthlyChartCard(report)
                    
                    // Category breakdown card
                    categoryBreakdownCard(report)
                    
                    // Top categories
                    topCategoriesCard(report)
                    
                    // Month comparison
                    monthComparisonCard()
                    
                    // Trending categories
                    trendingCategoriesCard()
                }
                .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabBarPadding()
        }
        .navigationTitle("Advanced Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Report Cards
    
    private func annualSummaryCard(_ report: AnalyticsReport) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Annual Summary - \(report.year)")
                    .font(AppTheme.title(16))
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    summaryRow(label: "Total Spent", value: formatCurrency(report.totalSpent), emphasis: true)
                    summaryRow(label: "Average/Month", value: formatCurrency(report.averageMonthly))
                    summaryRow(label: "Highest Month", value: "\(report.highestMonth) - \(formatCurrency(report.highestMonthAmount))")
                    summaryRow(label: "Lowest Month", value: "\(report.lowestMonth) - \(formatCurrency(report.lowestMonthAmount))")
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }
    
    private func monthlyChartCard(_ report: AnalyticsReport) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Monthly Breakdown")
                    .font(AppTheme.title(16))
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                Chart {
                    ForEach(report.monthlyData, id: \.month) { data in
                        BarMark(
                            x: .value("Month", data.month),
                            y: .value("Total", data.total)
                        )
                        .foregroundStyle(AppTheme.teal)
                    }
                }
                .frame(height: 200)
                .padding(16)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func categoryBreakdownCard(_ report: AnalyticsReport) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Category Breakdown")
                    .font(AppTheme.title(16))
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                VStack(spacing: 8) {
                    ForEach(report.categoryData.prefix(6), id: \.category) { item in
                        categoryProgressRow(
                            category: item.category,
                            amount: item.amount,
                            percentage: item.percentage
                        )
                    }
                }
                .padding(16)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func topCategoriesCard(_ report: AnalyticsReport) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Top Categories")
                    .font(AppTheme.title(16))
                    .fontWeight(.semibold)
                
                ForEach(report.topCategories, id: \.category) { category in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.category)
                                .font(AppTheme.body(14))
                                .fontWeight(.semibold)
                            Text("\(Int(category.percentage))% of total")
                                .font(AppTheme.body(12))
                                .foregroundStyle(AppTheme.ink.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Text(formatCurrency(category.amount))
                            .font(AppTheme.body(14))
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.teal)
                    }
                    .padding(12)
                    .background(AppTheme.ink.opacity(0.02))
                    .cornerRadius(8)
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }
    
    private func monthComparisonCard() -> some View {
        let today = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
        
        let comparison = analyticsService.monthComparison(
            current: currentMonth,
            previous: previousMonth,
            from: expenseStore.expenses
        )
        
        return GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Month-over-Month Comparison")
                    .font(AppTheme.title(16))
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    comparisonRow(
                        label: "This Month",
                        value: formatCurrency(comparison.current),
                        color: AppTheme.teal
                    )
                    comparisonRow(
                        label: "Last Month",
                        value: formatCurrency(comparison.previous),
                        color: AppTheme.ink.opacity(0.5)
                    )
                    
                    Divider()
                    
                    let arrow = comparison.change >= 0 ? "↑" : "↓"
                    let changeColor = comparison.change >= 0 ? Color.red : Color.green
                    
                    HStack {
                        Text("Change")
                            .font(AppTheme.body(13))
                        Spacer()
                        HStack(spacing: 4) {
                            Text(arrow)
                                .foregroundStyle(changeColor)
                            Text("\(formatCurrency(abs(comparison.change))) (\(String(format: "%.1f", abs(comparison.percentChange)))%)")
                                .font(AppTheme.body(14))
                                .fontWeight(.semibold)
                                .foregroundStyle(changeColor)
                        }
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }
    
    private func trendingCategoriesCard() -> some View {
        let today = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        let trends = analyticsService.trendingCategories(currentMonth: currentMonth, from: expenseStore.expenses)
        
        return Group {
            if !trends.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Trending Categories (Increased Spending)")
                            .font(AppTheme.title(16))
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ForEach(trends, id: \.category) { trend in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(trend.category)
                                            .font(AppTheme.body(14))
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text("↑ \(formatCurrency(trend.trend))")
                                            .font(AppTheme.body(13))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.red)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Text("This month: \(formatCurrency(trend.current))")
                                            .font(AppTheme.body(12))
                                        Spacer()
                                        Text("Last month: \(formatCurrency(trend.previous))")
                                            .font(AppTheme.body(12))
                                            .foregroundStyle(AppTheme.ink.opacity(0.6))
                                    }
                                }
                                .padding(12)
                                .background(AppTheme.coral.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func summaryRow(label: String, value: String, emphasis: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.body(emphasis ? 14 : 13))
                .fontWeight(emphasis ? .semibold : .regular)
                .foregroundStyle(emphasis ? AppTheme.ink : AppTheme.ink.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(AppTheme.body(emphasis ? 16 : 13))
                .fontWeight(.semibold)
                .foregroundStyle(emphasis ? AppTheme.teal : AppTheme.ink)
        }
    }
    
    private func comparisonRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.body(13))
            Spacer()
            Text(value)
                .font(AppTheme.body(14))
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
    
    private func categoryProgressRow(category: String, amount: Double, percentage: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category)
                    .font(AppTheme.body(13))
                    .fontWeight(.semibold)
                Spacer()
                Text(formatCurrency(amount))
                    .font(AppTheme.body(13))
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.teal)
            }
            
            ProgressView(value: percentage / 100)
                .tint(AppTheme.teal)
                .frame(height: 6)
                .cornerRadius(3)
            
            Text("\(Int(percentage))%")
                .font(AppTheme.body(11))
                .foregroundStyle(AppTheme.ink.opacity(0.5))
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

#Preview {
    @Previewable @State var expenseStore = ExpenseStore()
    
    NavigationStack {
        AdvancedAnalyticsView(expenseStore: expenseStore)
    }
}
