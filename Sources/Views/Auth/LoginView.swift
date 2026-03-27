import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authStore: AuthStore
    let onSwitch: () -> Void

    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Welcome back")
                    .font(AppTheme.title(20))
                    .foregroundStyle(AppTheme.ink)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(12)
                        .background(AppTheme.cloud.opacity(0.9))
                        .foregroundStyle(AppTheme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    SecureField("Password", text: $password)
                        .padding(12)
                        .background(AppTheme.cloud.opacity(0.9))
                        .foregroundStyle(AppTheme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if !authStore.authError.isEmpty {
                    Text(authStore.authError)
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.coral)
                }

                Button("Log In") {
                    authStore.logIn(email: email, password: password)
                }
                .buttonStyle(PrimaryButtonStyle())

                HStack {
                    Text("No account yet?")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                    Button("Sign up", action: onSwitch)
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ocean)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
