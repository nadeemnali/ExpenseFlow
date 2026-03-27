import SwiftUI

struct CategoryPill: View {
    let category: ExpenseCategory

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.systemImage)
                .font(.caption.bold())
            Text(category.label)
                .font(AppTheme.body(12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(category.color.opacity(0.18))
        .foregroundStyle(category.color)
        .clipShape(Capsule())
    }
}
