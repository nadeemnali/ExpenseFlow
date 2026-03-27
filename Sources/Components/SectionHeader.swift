import SwiftUI

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.title(20))
                .foregroundStyle(AppTheme.ink)
            Text(subtitle)
                .font(AppTheme.body(13))
                .foregroundStyle(AppTheme.ink.opacity(0.6))
        }
    }
}
