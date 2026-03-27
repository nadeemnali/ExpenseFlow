import SwiftUI

struct SignupView: View {
    @EnvironmentObject private var authStore: AuthStore
    let onSwitch: () -> Void

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirm: String = ""

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Create your account")
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

                    SecureField("Confirm password", text: $confirm)
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

                Button("Create account") {
                    authStore.signUp(email: email, password: password, confirm: confirm)
                }
                .buttonStyle(PrimaryButtonStyle())

                HStack {
                    Text("Already have an account?")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                    Button("Log in", action: onSwitch)
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ocean)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

