import Foundation

/// Service for generating advanced analytics reports and insights
class AdvancedAnalyticsService {
    // MARK: - Comprehensive Analytics
    
    /// Calculate spending by category for a given year
    func categoryBreakdown(for year: Int, from expenses: [Expense]) -> [(category: String, amount: Double, percentage: Double)] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? Date()
        let endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? Date()
        
        let yearExpenses = expenses.filter { expense in
            let expenseYear = calendar.component(.year, from: expense.date)
            return expenseYear == year
        }
        
        var categoryTotals: [String: Double] = [:]
        var total = 0.0
        
        for expense in yearExpenses {
            let categoryName = expense.customCategoryName ?? expense.category.displayName
            categoryTotals[categoryName, default: 0] += expense.amount
            total += expense.amount
        }
        
        let breakdown = categoryTotals
            .map { category, amount in
                (
                    category: category,
                    amount: amount,
                    percentage: total > 0 ? (amount / total * 100) : 0
                )
            }
            .sorted { $0.amount > $1.amount }
        
        return breakdown
    }
    
    /// Calculate monthly breakdown for a year
    func monthlyBreakdown(for year: Int, from expenses: [Expense]) -> [(month: String, total: Double)] {
        let calendar = Calendar.current
        var monthlyTotals: [Int: Double] = [:]
        
        for expense in expenses {
            let expenseYear = calendar.component(.year, from: expense.date)
            let expenseMonth = calendar.component(.month, from: expense.date)
            
            if expenseYear == year {
                monthlyTotals[expenseMonth, default: 0] += expense.amount
            }
        }
        
        let monthNames = [
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        ]
        
        return (1...12).compactMap { month in
            let total = monthlyTotals[month] ?? 0
            return (month: monthNames[month - 1], total: total)
        }
    }
    
    /// Calculate annual spending summary
    func annualSummary(from expenses: [Expense]) -> [Int: Double] {
        let calendar = Calendar.current
        var yearTotals: [Int: Double] = [:]
        
        for expense in expenses {
            let year = calendar.component(.year, from: expense.date)
            yearTotals[year, default: 0] += expense.amount
        }
        
        return yearTotals.sorted { $0.key > $1.key }
    }
    
    /// Compare spending between two months
    func monthComparison(current: Date, previous: Date, from expenses: [Expense]) -> (current: Double, previous: Double, change: Double, percentChange: Double) {
        let calendar = Calendar.current
        
        let currentStart = calendar.date(from: calendar.dateComponents([.year, .month], from: current))!
        let currentEnd = calendar.date(byAdding: .month, value: 1, to: currentStart)!
        
        let previousStart = calendar.date(from: calendar.dateComponents([.year, .month], from: previous))!
        let previousEnd = calendar.date(byAdding: .month, value: 1, to: previousStart)!
        
        let currentTotal = expenses
            .filter { $0.date >= currentStart && $0.date < currentEnd }
            .reduce(0) { $0 + $1.amount }
        
        let previousTotal = expenses
            .filter { $0.date >= previousStart && $0.date < previousEnd }
            .reduce(0) { $0 + $1.amount }
        
        let change = currentTotal - previousTotal
        let percentChange = previousTotal > 0 ? (change / previousTotal * 100) : 0
        
        return (current: currentTotal, previous: previousTotal, change: change, percentChange: percentChange)
    }
    
    /// Identify trending categories with increased spending
    func trendingCategories(currentMonth: Date, from expenses: [Expense]) -> [(category: String, current: Double, previous: Double, trend: Double)] {
        let calendar = Calendar.current
        
        // Get current month totals by category
        let currentStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let currentEnd = calendar.date(byAdding: .month, value: 1, to: currentStart)!
        let currentExpenses = expenses.filter { $0.date >= currentStart && $0.date < currentEnd }
        
        // Get previous month totals by category
        let previousStart = calendar.date(byAdding: .month, value: -1, to: currentStart)!
        let previousEnd = currentStart
        let previousExpenses = expenses.filter { $0.date >= previousStart && $0.date < previousEnd }
        
        var categoryTrends: [String: (current: Double, previous: Double)] = [:]
        
        // Sum by category
        for expense in currentExpenses {
            let category = expense.customCategoryName ?? expense.category.displayName
            categoryTrends[category, default: (0, 0)].current += expense.amount
        }
        
        for expense in previousExpenses {
            let category = expense.customCategoryName ?? expense.category.displayName
            categoryTrends[category, default: (0, 0)].previous += expense.amount
        }
        
        // Calculate trends and filter for increases
        let trends = categoryTrends
            .compactMap { category, values in
                let trend = values.current - values.previous
                return (
                    category: category,
                    current: values.current,
                    previous: values.previous,
                    trend: trend
                )
            }
            .filter { $0.trend > 0 }
            .sorted { $0.trend > $1.trend }
        
        return Array(trends.prefix(5)) // Top 5 trending
    }
    
    /// Generate annual spending report with insights
    func annualReport(for year: Int, from expenses: [Expense]) -> AnalyticsReport {
        let monthlyData = monthlyBreakdown(for: year, from: expenses)
        let categoryData = categoryBreakdown(for: year, from: expenses)
        
        let totalSpent = monthlyData.reduce(0) { $0 + $1.total }
        let averageMonthly = totalSpent / Double(monthlyData.count)
        
        // Find highest spending month
        let highestMonth = monthlyData.max(by: { $0.total < $1.total })
        let lowestMonth = monthlyData.min(by: { $0.total < $1.total })
        
        // Top categories
        let topCategories = Array(categoryData.prefix(3))
        
        return AnalyticsReport(
            year: year,
            totalSpent: totalSpent,
            averageMonthly: averageMonthly,
            highestMonth: highestMonth?.month ?? "N/A",
            highestMonthAmount: highestMonth?.total ?? 0,
            lowestMonth: lowestMonth?.month ?? "N/A",
            lowestMonthAmount: lowestMonth?.total ?? 0,
            monthlyData: monthlyData,
            categoryData: categoryData,
            topCategories: topCategories
        )
    }
    
    /// Predict spending for next month based on current trend
    func predictNextMonth(from expenses: [Expense]) -> Double {
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        // Get last 6 months of spending
        var lastSixMonthsTotals: [Double] = []
        
        for i in 0..<6 {
            let monthStart = calendar.date(byAdding: .month, value: -i, to: currentMonth)!
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            
            let monthTotal = expenses
                .filter { $0.date >= monthStart && $0.date < monthEnd }
                .reduce(0) { $0 + $1.amount }
            
            lastSixMonthsTotals.append(monthTotal)
        }
        
        // Calculate average, weighted toward recent months
        let weights = [6.0, 5.0, 4.0, 3.0, 2.0, 1.0]
        let weightedSum = zip(lastSixMonthsTotals, weights).reduce(0) { $0 + $1.0 * $1.1 }
        let totalWeight = weights.reduce(0, +)
        
        return weightedSum / totalWeight
    }
}

// MARK: - Data Models

struct AnalyticsReport {
    let year: Int
    let totalSpent: Double
    let averageMonthly: Double
    let highestMonth: String
    let highestMonthAmount: Double
    let lowestMonth: String
    let lowestMonthAmount: Double
    let monthlyData: [(month: String, total: Double)]
    let categoryData: [(category: String, amount: Double, percentage: Double)]
    let topCategories: [(category: String, amount: Double, percentage: Double)]
}

struct SpendingInsight {
    let title: String
    let description: String
    let value: String
    let trend: TrendDirection
    
    enum TrendDirection {
        case up
        case down
        case neutral
    }
}
