import SwiftUI

struct AuthShellView: View {
    @State private var showSignup = false

    var body: some View {
        BackgroundView {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Text("ExpenseFlow")
                        .font(AppTheme.display(34))
                        .foregroundStyle(AppTheme.ink)
                    Text("Your daily expenses, painted in color.")
                        .font(AppTheme.body(15))
                        .foregroundStyle(AppTheme.ink.opacity(0.7))
                }

                ZStack {
                    if showSignup {
                        SignupView(onSwitch: { withAnimation { showSignup = false } })
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        LoginView(onSwitch: { withAnimation { showSignup = true } })
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}
