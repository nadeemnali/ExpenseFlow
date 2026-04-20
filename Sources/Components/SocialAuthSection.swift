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

            Button {
                authStore.startUnsupportedSocialSignIn(provider: .google)
            } label: {
                socialButtonLabel(title: "Continue with Google", systemImage: "globe")
            }
            .buttonStyle(.plain)

            Button {
                authStore.startUnsupportedSocialSignIn(provider: .facebook)
            } label: {
                socialButtonLabel(title: "Continue with Facebook", systemImage: "person.2.fill")
            }
            .buttonStyle(.plain)
        }
    }

    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func socialButtonLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .frame(width: 20)

            Text(title)
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.ink)

            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(AppTheme.cloud.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
