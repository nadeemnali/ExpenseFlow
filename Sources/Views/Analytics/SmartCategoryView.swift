import SwiftUI

/// Smart category suggestion during expense creation/editing
struct SmartCategoryView: View {
    @ObservedObject var expenseStore: ExpenseStore
    @StateObject private var categorizationService = SmartCategorizationService()
    
    let title: String
    @Binding var selectedCategory: ExpenseCategory
    @Environment(\.dismiss) var dismiss
    
    var suggestions: [CategorySuggestion] {
        categorizationService.rankedCategorySuggestions(
            for: title,
            from: expenseStore.expenses,
            availableCategories: ExpenseCategory.allCases
        )
    }
    
    var body: some View {
        BackgroundView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Suggest Category")
                        .font(AppTheme.title(18))
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.ink.opacity(0.5))
                    }
                }
                .padding(20)
                .background(AppTheme.background)
                
                Divider()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Expense title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Expense")
                                .font(AppTheme.body(12))
                                .foregroundStyle(AppTheme.ink.opacity(0.6))
                            
                            Text(title)
                                .font(AppTheme.title(16))
                                .fontWeight(.semibold)
                                .lineLimit(2)
                        }
                        .padding(16)
                        .background(AppTheme.teal.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                        
                        // Top suggestion
                        if let topSuggestion = suggestions.first {
                            topSuggestionCard(topSuggestion)
                        }
                        
                        // All suggestions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Other Categories")
                                .font(AppTheme.title(14))
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 8) {
                                ForEach(suggestions, id: \.category) { suggestion in
                                    suggestionRow(suggestion)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
    }
    
    private func topSuggestionCard(_ suggestion: CategorySuggestion) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.teal)
                    
                    Text("Our Suggestion")
                        .font(AppTheme.body(12))
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.category.displayName)
                        .font(AppTheme.title(18))
                        .fontWeight(.semibold)
                    
                    Text(suggestion.reason)
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                }
                
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.teal.opacity(0.2))
                        
                        ProgressView(value: suggestion.confidence)
                            .scaleEffect(0.7, anchor: .center)
                    }
                    .frame(height: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Confidence")
                            .font(AppTheme.body(11))
                            .foregroundStyle(AppTheme.ink.opacity(0.6))
                        Text("\(suggestion.confidencePercentage)%")
                            .font(AppTheme.body(14))
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        selectedCategory = suggestion.category
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Use")
                        }
                        .font(AppTheme.body(13))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(AppTheme.teal)
                        .cornerRadius(6)
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }
    
    private func suggestionRow(_ suggestion: CategorySuggestion) -> some View {
        Button(action: {
            selectedCategory = suggestion.category
            dismiss()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.category.displayName)
                        .font(AppTheme.body(14))
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.ink)
                    
                    Text(suggestion.reason)
                        .font(AppTheme.body(11))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(suggestion.confidencePercentage)%")
                        .font(AppTheme.body(12))
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.teal)
                    
                    ProgressView(value: suggestion.confidence)
                        .tint(AppTheme.teal)
                        .frame(width: 40)
                }
            }
            .padding(12)
            .background(AppTheme.ink.opacity(0.02))
            .cornerRadius(8)
        }
    }
}

#Preview {
    @Previewable @State var expenseStore = ExpenseStore()
    @Previewable @State var selectedCategory = ExpenseCategory.Food
    
    SmartCategoryView(
        expenseStore: expenseStore,
        title: "Starbucks Coffee",
        selectedCategory: $selectedCategory
    )
}
