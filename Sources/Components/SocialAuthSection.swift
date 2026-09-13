import SwiftUI
import AuthenticationServices

struct SocialAuthSection: View {
    @EnvironmentObject private var authStore: AuthStore

    let appleButtonType: SignInWithAppleButton.Label

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(AppTheme.ink.opacity(0.12))
                    .frame(height: 1)

                Text("or continue with")
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.ink.opacity(0.55))

                Rectangle()
                    .fill(AppTheme.ink.opacity(0.12))
                    .frame(height: 1)
            }

            SignInWithAppleButton(appleButtonType, onRequest: configureAppleRequest, onCompletion: authStore.handleAppleSignIn)
                .signInWithAppleButtonStyle(.black)
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
}
