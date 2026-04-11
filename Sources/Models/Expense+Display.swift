import SwiftUI

extension Expense {
    var displayCategoryLabel: String {
        customCategoryName ?? category.label
    }

    var customCategoryColor: Color? {
        guard let hex = customCategoryColorHex else { return nil }
        return Color(hex: hex)
    }

    var displayCategoryColor: Color {
        customCategoryColor ?? category.color
    }

    var displayCategoryIcon: String {
        customCategoryName == nil ? category.systemImage : "tag.fill"
    }
}
