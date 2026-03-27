import SwiftUI

struct MiniStatCard: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.body(12))
                .foregroundStyle(AppTheme.ink.opacity(0.6))
            Text(value)
                .font(AppTheme.title(18))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(accent.opacity(0.15))
        )
    }
}
