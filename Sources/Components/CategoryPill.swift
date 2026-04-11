import SwiftUI

struct CategoryPill: View {
    let label: String
    let systemImage: String
    let color: Color

    init(category: ExpenseCategory, customLabel: String? = nil, customColor: Color? = nil, customSystemImage: String? = nil) {
        self.label = customLabel ?? category.label
        self.systemImage = customSystemImage ?? category.systemImage
        self.color = customColor ?? category.color
    }

    init(label: String, systemImage: String, color: Color) {
        self.label = label
        self.systemImage = systemImage
        self.color = color
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.bold())
            Text(label)
                .font(AppTheme.body(12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.18))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}
