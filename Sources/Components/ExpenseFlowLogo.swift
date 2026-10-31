import SwiftUI

struct ExpenseFlowLogo: View {
    let size: CGFloat
    var showAnimation: Bool = true
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer glow circle
            Circle()
                .fill(AppTheme.coral.opacity(0.15))
                .frame(width: size, height: size)
                .scaleEffect(showAnimation && isAnimating ? 1.08 : 1.0)
                .animation(showAnimation ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default, value: isAnimating)
            
            // Rotating accent ring
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [AppTheme.teal, AppTheme.ocean]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.08
                )
                .frame(width: size * 0.85, height: size * 0.85)
                .rotationEffect(.degrees(showAnimation && isAnimating ? 360 : 0))
                .animation(showAnimation ? .linear(duration: 8).repeatForever(autoreverses: false) : .default, value: isAnimating)
            
            // Inner circle background
            Circle()
                .fill(AppTheme.cloud.opacity(0.6))
                .frame(width: size * 0.72, height: size * 0.72)
            
            // Logo content - wallet/money symbol
            VStack(spacing: 0) {
                // Wallet top
                RoundedRectangle(cornerRadius: size * 0.12)
                    .fill(AppTheme.ocean)
                    .frame(height: size * 0.25)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.08)
                            .fill(AppTheme.teal)
                            .frame(width: size * 0.18, height: size * 0.12)
                            .padding(.trailing, size * 0.08)
                            .padding(.top, size * 0.04),
                        alignment: .topTrailing
                    )
                
                Spacer()
                    .frame(height: size * 0.08)
                
                // Dollar sign
                Text("$")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(AppTheme.ocean)
                
                Spacer()
            }
            .frame(width: size * 0.6, height: size * 0.6)
        }
        .frame(width: size, height: size)
        .onAppear {
            if showAnimation {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        ExpenseFlowLogo(size: 100)
        ExpenseFlowLogo(size: 150, showAnimation: true)
        ExpenseFlowLogo(size: 200, showAnimation: true)
    }
    .padding()
    .background(Color(.systemGray6))
}
