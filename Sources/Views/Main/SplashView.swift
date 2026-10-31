import SwiftUI

struct SplashView: View {
    @State private var showContent = false
    @State private var loadingProgress: Double = 0

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.cloud.opacity(0.4),
                    AppTheme.ocean.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()

                // Logo with animation
                VStack(spacing: 24) {
                    ExpenseFlowLogo(size: 140, showAnimation: true)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0)

                    VStack(spacing: 12) {
                        Text("ExpenseFlow")
                            .font(AppTheme.display(32))
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.ink)
                            .tracking(0.5)

                        Text("Smart Expense Tracking")
                            .font(AppTheme.body(14))
                            .foregroundStyle(AppTheme.ink.opacity(0.6))
                            .tracking(0.3)
                    }
                    .opacity(showContent ? 1.0 : 0)
                    .offset(y: showContent ? 0 : 20)
                }
                .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)

                Spacer()

                // Loading indicator
                VStack(spacing: 12) {
                    // Progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppTheme.cloud.opacity(0.3))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [AppTheme.ocean, AppTheme.teal]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 120 * loadingProgress, height: 4)
                            .animation(.easeInOut(duration: 1.5), value: loadingProgress)
                    }
                    .frame(width: 120)

                    Text("Loading")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.5))
                }
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            showContent = true
            
            // Simulate loading progress
            var progress = 0.0
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
                progress += Double.random(in: 0.1...0.3)
                loadingProgress = min(progress, 0.95)
                
                if loadingProgress >= 0.95 {
                    timer.invalidate()
                }
            }
        }
    }
}
