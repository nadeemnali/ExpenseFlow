import Foundation

/// Service for predicting budget and spending forecasts
class BudgetForecastingService {
    // MARK: - Forecasting Calculations
    
    /// Predict end-of-month total based on current spending trend
    func predictMonthlyTotal(currentMonth: Date, from expenses: [Expense]) -> (predicted: Double, confidence: Double, dailyRate: Double) {
        let calendar = Calendar.current
        let today = Date()
        
        // Get current month start and end
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        
        // Get days in month
        let daysInMonth = calendar.dateComponents([.day], from: monthStart, to: monthEnd).day ?? 30
        
        // Get current month expenses up to today
        let currentExpenses = expenses.filter { expense in
            expense.date >= monthStart && expense.date <= today
        }
        
        let spentSoFar = currentExpenses.reduce(0) { $0 + $1.amount }
        
        // Calculate days elapsed
        let daysElapsed = calendar.dateComponents([.day], from: monthStart, to: today).day ?? 1
        let daysRemaining = max(1, daysInMonth - daysElapsed)
        
        // Calculate daily average rate
        let dailyRate = spentSoFar / Double(max(1, daysElapsed))
        
        // Predict remaining days
        let predictedRemaining = dailyRate * Double(daysRemaining)
        let predicted = spentSoFar + predictedRemaining
        
        // Calculate confidence (0-1) based on how much of the month has passed
        let confidence = Double(daysElapsed) / Double(daysInMonth)
        
        return (predicted: max(0, predicted), confidence: confidence, dailyRate: dailyRate)
    }
    
    /// Predict if budget will be exceeded and by when
    func budgetExceedanceWarning(
        monthBudget: Double,
        currentMonth: Date,
        from expenses: [Expense]
    ) -> BudgetWarning? {
        let calendar = Calendar.current
        let today = Date()
        
        // Get current month start
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        
        // Get current month expenses up to today
        let currentExpenses = expenses.filter { expense in
            expense.date >= monthStart && expense.date <= today
        }
        
        let spentSoFar = currentExpenses.reduce(0) { $0 + $1.amount }
        
        // Check if already exceeded
        if spentSoFar > monthBudget {
            let exceeded = spentSoFar - monthBudget
            return BudgetWarning(
                level: .exceeded,
                message: "You've exceeded your budget by \(formatCurrency(exceeded))",
                percentage: (spentSoFar / monthBudget) * 100,
                daysUntilExceedance: 0
            )
        }
        
        // Calculate days elapsed and daily rate
        let daysElapsed = calendar.dateComponents([.day], from: monthStart, to: today).day ?? 1
        let dailyRate = spentSoFar / Double(max(1, daysElapsed))
        
        // Calculate days until budget is exceeded
        let remainingBudget = monthBudget - spentSoFar
        let daysUntilExceedance = Int(ceil(remainingBudget / max(0.01, dailyRate)))
        
        // Return warning if will be exceeded within month
        if daysUntilExceedance < 30 {
            let percentage = (spentSoFar / monthBudget) * 100
            
            let level: BudgetWarning.Level
            if percentage >= 90 {
                level = .critical
            } else if percentage >= 75 {
                level = .high
            } else if percentage >= 50 {
                level = .medium
            } else {
                return nil
            }
            
            return BudgetWarning(
                level: level,
                message: "At this rate, you'll exceed your budget in \(daysUntilExceedance) days",
                percentage: percentage,
                daysUntilExceedance: daysUntilExceedance
            )
        }
        
        return nil
    }
    
    /// Predict category spending for the month
    func categoryForecast(
        currentMonth: Date,
        from expenses: [Expense],
        categoryLimit: [String: Double]
    ) -> [CategoryForecast] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get current month start and end
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        
        // Get days in month and days elapsed
        let daysInMonth = calendar.dateComponents([.day], from: monthStart, to: monthEnd).day ?? 30
        let daysElapsed = max(1, calendar.dateComponents([.day], from: monthStart, to: today).day ?? 1)
        let daysRemaining = daysInMonth - daysElapsed
        
        // Group expenses by category
        var categoryExpenses: [String: [Expense]] = [:]
        
        let currentExpenses = expenses.filter { expense in
            expense.date >= monthStart && expense.date <= today
        }
        
        for expense in currentExpenses {
            let categoryName = expense.customCategoryName ?? expense.category.displayName
            categoryExpenses[categoryName, default: []].append(expense)
        }
        
        // Calculate forecasts
        var forecasts: [CategoryForecast] = []
        
        for (category, categoryExp) in categoryExpenses {
            let spentSoFar = categoryExp.reduce(0) { $0 + $1.amount }
            let dailyRate = spentSoFar / Double(daysElapsed)
            let predictedRemaining = dailyRate * Double(daysRemaining)
            let predicted = spentSoFar + predictedRemaining
            
            let limit = categoryLimit[category] ?? Double.infinity
            let willExceed = predicted > limit
            let percentOfLimit = (predicted / limit) * 100
            
            forecasts.append(
                CategoryForecast(
                    category: category,
                    spentToDate: spentSoFar,
                    predicted: predicted,
                    limit: limit,
                    willExceed: willExceed,
                    percentOfLimit: min(100, percentOfLimit)
                )
            )
        }
        
        return forecasts.sorted { $0.predicted > $1.predicted }
    }
    
    /// Generate forecast insights for dashboard
    func forecastInsights(
        monthBudget: Double,
        currentMonth: Date,
        from expenses: [Expense]
    ) -> [SpendingInsight] {
        var insights: [SpendingInsight] = []
        
        // Monthly prediction insight
        let prediction = predictMonthlyTotal(currentMonth: currentMonth, from: expenses)
        let message = "Based on current pace, you'll spend \(formatCurrency(prediction.predicted)) this month"
        
        let trend: SpendingInsight.TrendDirection
        if prediction.predicted > monthBudget * 1.1 {
            trend = .up
        } else if prediction.predicted < monthBudget * 0.8 {
            trend = .down
        } else {
            trend = .neutral
        }
        
        insights.append(
            SpendingInsight(
                title: "Monthly Forecast",
                description: message,
                value: formatCurrency(prediction.predicted),
                trend: trend
            )
        )
        
        // Daily rate insight
        insights.append(
            SpendingInsight(
                title: "Daily Average",
                description: "You're spending \(formatCurrency(prediction.dailyRate)) per day on average",
                value: formatCurrency(prediction.dailyRate),
                trend: prediction.dailyRate > monthBudget / 30 ? .up : .down
            )
        )
        
        return insights
    }
    
    // MARK: - Helpers
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

// MARK: - Data Models

struct BudgetWarning {
    let level: Level
    let message: String
    let percentage: Double  // 0-100 of budget spent
    let daysUntilExceedance: Int
    
    enum Level: String {
        case exceeded = "Exceeded"
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        
        var color: String {
            switch self {
            case .exceeded, .critical:
                return "FF3B30"  // Red
            case .high:
                return "FF9500"  // Orange
            case .medium:
                return "FFCC00"  // Yellow
            }
        }
    }
}

struct CategoryForecast {
    let category: String
    let spentToDate: Double
    let predicted: Double
    let limit: Double
    let willExceed: Bool
    let percentOfLimit: Double
}
