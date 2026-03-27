import SwiftUI

struct SplashView: View {
    @State private var pulse = false
    @State private var shimmer = false

    var body: some View {
        BackgroundView {
            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.coral.opacity(0.18))
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulse ? 1.05 : 0.92)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)

                    Circle()
                        .stroke(AppTheme.mango.opacity(0.35), lineWidth: 18)
                        .frame(width: 170, height: 170)
                        .rotationEffect(.degrees(shimmer ? 360 : 0))
                        .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: shimmer)

                    Image(systemName: "sparkles")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(AppTheme.accentGradient)
                        .shadow(color: AppTheme.coral.opacity(0.35), radius: 12, x: 0, y: 10)
                }

                VStack(spacing: 8) {
                    Text("ExpenseFlow")
                        .font(AppTheme.display(30))
                        .foregroundStyle(AppTheme.ink)

                    Text("Color your daily spend")
                        .font(AppTheme.body(14))
                        .foregroundStyle(AppTheme.ink.opacity(0.7))
                }

                Spacer()

                Text("Loading")
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.ink.opacity(0.5))
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            pulse = true
            shimmer = true
        }
    }
}
