import SwiftUI

struct BackgroundView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                Circle()
                    .fill(AppTheme.coral.opacity(0.2))
                    .frame(width: 260, height: 260)
                    .blur(radius: 30)
                    .offset(x: -140, y: -220)

                Circle()
                    .fill(AppTheme.teal.opacity(0.25))
                    .frame(width: 220, height: 220)
                    .blur(radius: 24)
                    .offset(x: 160, y: -120)

                RoundedRectangle(cornerRadius: 80, style: .continuous)
                    .fill(AppTheme.mango.opacity(0.18))
                    .frame(width: 260, height: 180)
                    .blur(radius: 22)
                    .rotationEffect(.degrees(-20))
                    .offset(x: 120, y: 260)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
