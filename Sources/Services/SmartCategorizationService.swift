import Foundation

/// Service for smart categorization using simple ML pattern matching
class SmartCategorizationService {
    // MARK: - Category Suggestion
    
    /// Suggest a category based on expense title and history
    func suggestCategory(
        for title: String,
        from expenses: [Expense],
        availableCategories: [ExpenseCategory]
    ) -> (category: ExpenseCategory, confidence: Double, reason: String) {
        let titleLower = title.lowercased()
        
        // Check direct keyword matches
        if let matched = matchKeywords(titleLower, availableCategories: availableCategories) {
            return (category: matched, confidence: 0.95, reason: "Exact keyword match")
        }
        
        // Check similar past expenses
        if let matched = findSimilarExpenses(titleLower, from: expenses) {
            return (category: matched.category, confidence: 0.80, reason: "Similar to '\(matched.title)'")
        }
        
        // Analyze pattern in title
        if let matched = analyzePattern(titleLower) {
            return (category: matched, confidence: 0.70, reason: "Pattern recognition")
        }
        
        // Default to Food if no match
        return (category: .Food, confidence: 0.5, reason: "Default category")
    }
    
    /// Get category suggestions ranked by probability
    func rankedCategorySuggestions(
        for title: String,
        from expenses: [Expense],
        availableCategories: [ExpenseCategory]
    ) -> [CategorySuggestion] {
        var suggestions: [CategorySuggestion] = []
        let titleLower = title.lowercased()
        
        // Score all categories
        for category in availableCategories {
            let score = scoreCategory(titleLower, category: category, from: expenses)
            if score.confidence > 0 {
                suggestions.append(score)
            }
        }
        
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    /// Learn from user categorization for future suggestions
    func learnFromUserChoice(title: String, chosenCategory: ExpenseCategory, store: inout [String: ExpenseCategory]) {
        let titleWords = title.lowercased().components(separatedBy: " ")
        for word in titleWords where word.count > 3 {
            store[word] = chosenCategory
        }
    }
    
    // MARK: - Pattern Matching
    
    private func matchKeywords(_ title: String, availableCategories: [ExpenseCategory]) -> ExpenseCategory? {
        let keywordMap: [String: ExpenseCategory] = [
            // Food & Dining
            "restaurant": .Food,
            "cafe": .Food,
            "coffee": .Food,
            "pizza": .Food,
            "burger": .Food,
            "sushi": .Food,
            "lunch": .Food,
            "breakfast": .Food,
            "dinner": .Food,
            "grocery": .Groceries,
            "supermarket": .Groceries,
            "whole foods": .Groceries,
            "trader joe": .Groceries,
            
            // Transportation
            "uber": .Transport,
            "lyft": .Transport,
            "taxi": .Transport,
            "gas": .Transport,
            "fuel": .Transport,
            "parking": .Transport,
            "transit": .Transport,
            "metro": .Transport,
            "train": .Transport,
            "airline": .Transport,
            "flight": .Transport,
            
            // Health & Fitness
            "gym": .Health,
            "yoga": .Health,
            "doctor": .Health,
            "pharmacy": .Health,
            "dentist": .Health,
            "hospital": .Health,
            "clinic": .Health,
            "medical": .Health,
            
            // Entertainment
            "movie": .Entertainment,
            "cinema": .Entertainment,
            "netflix": .Entertainment,
            "spotify": .Entertainment,
            "game": .Entertainment,
            "concert": .Entertainment,
            "theater": .Entertainment,
            "theatre": .Entertainment,
            
            // Shopping
            "amazon": .Shopping,
            "walmart": .Shopping,
            "target": .Shopping,
            "mall": .Shopping,
            "store": .Shopping,
            "clothing": .Shopping,
            "apparel": .Shopping,
            
            // Utilities
            "electric": .Utilities,
            "water": .Utilities,
            "gas bill": .Utilities,
            "internet": .Utilities,
            "phone": .Utilities,
            "cable": .Utilities,
            "power": .Utilities,
            
            // Other
            "work": .Other,
            "business": .Other,
            "office": .Other
        ]
        
        for (keyword, category) in keywordMap {
            if title.contains(keyword) {
                return category
            }
        }
        
        return nil
    }
    
    private func findSimilarExpenses(titleLower: String, from expenses: [Expense]) -> (title: String, category: ExpenseCategory)? {
        let titleWords = Set(titleLower.components(separatedBy: " "))
        var bestMatch: (title: String, category: ExpenseCategory, similarity: Double)?
        
        for expense in expenses.prefix(100) {  // Check last 100 expenses
            let expenseWords = Set(expense.title.lowercased().components(separatedBy: " "))
            
            // Calculate similarity using Jaccard distance
            let intersection = titleWords.intersection(expenseWords).count
            let union = titleWords.union(expenseWords).count
            let similarity = Double(intersection) / Double(max(1, union))
            
            if similarity > 0.4 {  // At least 40% similarity
                if bestMatch == nil || similarity > bestMatch!.similarity {
                    bestMatch = (title: expense.title, category: expense.category, similarity: similarity)
                }
            }
        }
        
        return bestMatch.map { ($0.title, $0.category) }
    }
    
    private func analyzePattern(_ title: String) -> ExpenseCategory? {
        // Pattern-based detection
        let patterns: [(pattern: String, category: ExpenseCategory)] = [
            // Common shopping brands
            ("amazon", .Shopping),
            ("ebay", .Shopping),
            ("etsy", .Shopping),
            ("aliexpress", .Shopping),
            
            // Subscriptions
            ("subscription", .Entertainment),
            ("monthly", .Utilities),
            ("annual", .Utilities),
            
            // Transfers
            ("transfer", .Other),
            ("payment", .Other),
        ]
        
        for (pattern, category) in patterns {
            if title.contains(pattern) {
                return category
            }
        }
        
        return nil
    }
    
    private func scoreCategory(_ title: String, category: ExpenseCategory, from expenses: [Expense]) -> CategorySuggestion {
        var score = 0.0
        
        // Check keyword match
        let categoryKeywords = getKeywordsForCategory(category)
        for keyword in categoryKeywords {
            if title.contains(keyword) {
                score += 0.3
            }
        }
        
        // Check historical frequency in this category
        let categoryCount = expenses.filter { $0.category == category }.count
        let totalCount = max(1, expenses.count)
        let categoryFrequency = Double(categoryCount) / Double(totalCount)
        score += categoryFrequency * 0.4
        
        // Boost score if commonly used
        if categoryFrequency > 0.2 {
            score += 0.2
        }
        
        return CategorySuggestion(
            category: category,
            confidence: min(1.0, score),
            reason: score > 0.5 ? "Common in this category" : "Possible category"
        )
    }
    
    private func getKeywordsForCategory(_ category: ExpenseCategory) -> [String] {
        switch category {
        case .Food:
            return ["food", "restaurant", "cafe", "lunch", "dinner", "breakfast"]
        case .Transport:
            return ["transport", "uber", "lyft", "gas", "parking", "flight"]
        case .Groceries:
            return ["grocery", "supermarket", "market", "food store"]
        case .Health:
            return ["health", "gym", "doctor", "pharmacy", "medical"]
        case .Entertainment:
            return ["movie", "netflix", "entertainment", "game", "concert"]
        case .Shopping:
            return ["shop", "store", "amazon", "mall", "buy"]
        case .Utilities:
            return ["electric", "water", "internet", "bill", "utility"]
        case .Other:
            return ["other", "misc", "miscellaneous"]
        }
    }
}

// MARK: - Data Models

struct CategorySuggestion {
    let category: ExpenseCategory
    let confidence: Double  // 0-1
    let reason: String
    
    var confidencePercentage: Int {
        Int(confidence * 100)
    }
}

struct CategoryInsight {
    let category: String
    let frequency: Double
    let averageAmount: Double
    let trend: TrendDirection
    
    enum TrendDirection {
        case increasing
        case stable
        case decreasing
    }
}
