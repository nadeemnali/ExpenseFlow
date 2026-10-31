import SwiftUI

/// Budget forecasting and spending prediction view
struct BudgetForecastView: View {
    @ObservedObject var expenseStore: ExpenseStore
    @ObservedObject var settingsStore: SettingsStore
    @StateObject private var forecastService = BudgetForecastingService()
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    SectionHeader(title: "Budget Forecast", subtitle: "Spending predictions")
                    
                    // Monthly prediction
                    let today = Date()
                    let calendar = Calendar.current
                    let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
                    
                    let prediction = forecastService.predictMonthlyTotal(
                        currentMonth: currentMonth,
                        from: expenseStore.expenses
                    )
                    
                    monthlyForecastCard(prediction, budget: settingsStore.monthlyBudget)
                    
                    // Budget exceedance warning
                    if let warning = forecastService.budgetExceedanceWarning(
                        monthBudget: settingsStore.monthlyBudget,
                        currentMonth: currentMonth,
                        from: expenseStore.expenses
                    ) {
                        budgetWarningCard(warning)
                    }
                    
                    // Spending insights
                    let insights = forecastService.forecastInsights(
                        monthBudget: settingsStore.monthlyBudget,
                        currentMonth: currentMonth,
                        from: expenseStore.expenses
                    )
                    
                    insightsCard(insights)
                    
                    // Category forecasts
                    categoryForecastsCard(prediction, currentMonth: currentMonth)
                    
                    // Spending velocity
                    spendingVelocityCard(prediction)
                }
                .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabBarPadding()
        }
        .navigationTitle("Budget Forecast")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Cards
    
    private func monthlyForecastCard(
        _ prediction: (predicted: Double, confidence: Double, dailyRate: Double),
        budget: Double
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("End-of-Month Prediction")
                    .font(AppTheme.title(16))
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Predicted Total")
                                .font(AppTheme.body(13))
                                .foregroundStyle(AppTheme.ink.opacity(0.6))
                            Text(formatCurrency(prediction.predicted))
                                .font(AppTheme.title(18))
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.teal)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Your Budget")
                                .font(AppTheme.body(13))
                                .foregroundStyle(AppTheme.ink.opacity(0.6))
                            Text(formatCurrency(budget))
                                .font(AppTheme.title(18))
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.ink)
                        }
                    }
                    
                    Divider()
                    
                    let difference = prediction.predicted - budget
                    let statusColor: Color = difference > 0 ? .red : .green
                    let statusText = difference > 0 ? "Over Budget" : "Under Budget"
                    
                    HStack {
                        Text(statusText)
                            .font(AppTheme.body(13))
                            .fontWeight(.semibold)
                            .foregroundStyle(statusColor)
                        
                        Spacer()
                        
                        Text(difference > 0 ? "+" : "-")
                            .font(AppTheme.body(13))
                            .fontWeight(.semibold)
                            .foregroundStyle(statusColor)
                        + Text(formatCurrency(abs(difference)))
                            .font(AppTheme.body(13))
                            .fontWeight(.semibold)
                            .foregroundStyle(statusColor)
                    }
                    
                    // Confidence indicator
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Confidence Level")
                                .font(AppTheme.body(12))
                                .foregroundStyle(AppTheme.ink.opacity(0.6))
                            Spacer()
                            Text("\(Int(prediction.confidence * 100))%")
                                .font(AppTheme.body(12))
                                .fontWeight(.semibold)
                        }
                        
                        ProgressView(value: prediction.confidence)
                            .tint(AppTheme.teal)
                            .frame(height: 6)
                            .cornerRadius(3)
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }
    
    private func budgetWarningCard(_ warning: BudgetWarning) -> some View {
        let backgroundColor: Color
        switch warning.level {
        case .exceeded, .critical:
            backgroundColor = Color.red.opacity(0.1)
        case .high:
            backgroundColor = Color.orange.opacity(0.1)
        case .medium:
            backgroundColor = Color.yellow.opacity(0.1)
        }
        
        let textColor: Color
        switch warning.level {
        case .exceeded, .critical:
            textColor = .red
        case .high:
            textColor = .orange
        case .medium:
            textColor = .yellow
        }
        
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(textColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(warning.level.rawValue)
                            .font(AppTheme.body(13))
                            .fontWeight(.semibold)
                            .foregroundStyle(textColor)
                        
                        Text(warning.message)
                            .font(AppTheme.body(12))
                            .foregroundStyle(textColor.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Budget Usage")
                            .font(AppTheme.body(12))
                        Spacer()
                        Text("\(Int(warning.percentage))%")
                            .font(AppTheme.body(12))
                            .fontWeight(.semibold)
                    }
                    
                    ProgressView(value: min(warning.percentage, 100) / 100)
                        .tint(textColor)
                        .frame(height: 6)
                        .cornerRadius(3)
                }
            }
            .padding(16)
            .background(backgroundColor)
        }
        .padding(.horizontal, 20)
    }
    
    private func insightsCard(_ insights: [SpendingInsight]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Spending Insights")
                    .font(AppTheme.title(16))
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    ForEach(insights, id: \.title) { insight in
                        insightRow(insight)
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }
    
    private func insightRow(_ insight: SpendingInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: trendIcon(insight.trend))
                .font(.system(size: 16))
                .foregroundStyle(trendColor(insight.trend))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(AppTheme.body(13))
                    .fontWeight(.semibold)
                
                Text(insight.description)
                    .font(AppTheme.body(11))
                    .foregroundStyle(AppTheme.ink.opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(insight.value)
                .font(AppTheme.body(13))
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.teal)
        }
        .padding(12)
        .background(AppTheme.ink.opacity(0.02))
        .cornerRadius(8)
    }
    
    private func categoryForecastsCard(
        _ prediction: (predicted: Double, confidence: Double, dailyRate: Double),
        currentMonth: Date
    ) -> some View {
        let forecasts = forecastService.categoryForecast(
            currentMonth: currentMonth,
            from: expenseStore.expenses,
            categoryLimit: [:]
        )
        
        return Group {
            if !forecasts.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Category Forecasts")
                            .font(AppTheme.title(16))
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ForEach(forecasts.prefix(5), id: \.category) { forecast in
                                categoryForecastRow(forecast)
                            }
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func categoryForecastRow(_ forecast: CategoryForecast) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(forecast.category)
                    .font(AppTheme.body(13))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(formatCurrency(forecast.predicted))
                    .font(AppTheme.body(13))
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.teal)
            }
            
            ProgressView(value: min(forecast.percentOfLimit, 100) / 100)
                .tint(forecast.willExceed ? .red : AppTheme.teal)
                .frame(height: 4)
                .cornerRadius(2)
            
            Text("\(Int(forecast.percentOfLimit))% of limit")
                .font(AppTheme.body(11))
                .foregroundStyle(AppTheme.ink.opacity(0.5))
        }
        .padding(12)
        .background(AppTheme.ink.opacity(0.02))
        .cornerRadius(8)
    }
    
    private func spendingVelocityCard(
        _ prediction: (predicted: Double, confidence: Double, dailyRate: Double)
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Spending Velocity")
                    .font(AppTheme.title(16))
                    .fontWeight(.semibold)
                
                VStack(spacing: 10) {
                    velocityRow(label: "Daily Average", value: formatCurrency(prediction.dailyRate))
                    velocityRow(label: "Weekly Pace", value: formatCurrency(prediction.dailyRate * 7))
                    velocityRow(label: "Bi-weekly Pace", value: formatCurrency(prediction.dailyRate * 14))
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }
    
    private func velocityRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.body(13))
            Spacer()
            Text(value)
                .font(AppTheme.body(13))
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.teal)
        }
    }
    
    // MARK: - Helpers
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    private func trendIcon(_ trend: SpendingInsight.TrendDirection) -> String {
        switch trend {
        case .up:
            return "arrow.up.circle.fill"
        case .down:
            return "arrow.down.circle.fill"
        case .neutral:
            return "minus.circle.fill"
        }
    }
    
    private func trendColor(_ trend: SpendingInsight.TrendDirection) -> Color {
        switch trend {
        case .up:
            return .red
        case .down:
            return .green
        case .neutral:
            return AppTheme.ink.opacity(0.5)
        }
    }
}

#Preview {
    @Previewable @State var expenseStore = ExpenseStore()
    @Previewable @State var settingsStore = SettingsStore()
    
    NavigationStack {
        BudgetForecastView(expenseStore: expenseStore, settingsStore: settingsStore)
    }
}
