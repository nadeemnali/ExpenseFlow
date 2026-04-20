import Foundation
import AuthenticationServices
import os.log

enum AuthProvider: String, Codable, CaseIterable, Identifiable {
    case password
    case apple
    case google
    case facebook

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .password:
            return "Email"
        case .apple:
            return "Apple"
        case .google:
            return "Google"
        case .facebook:
            return "Facebook"
        }
    }
}

struct AuthAccount: Identifiable, Codable, Hashable {
    let id: UUID
    let email: String
    let provider: AuthProvider
    let providerUserID: String?
    let displayName: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        email: String,
        provider: AuthProvider,
        providerUserID: String? = nil,
        displayName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.provider = provider
        self.providerUserID = providerUserID
        self.displayName = displayName
        self.createdAt = createdAt
    }
}

final class AuthStore: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentEmail: String = ""
    @Published private(set) var currentProvider: AuthProvider?
    @Published var authError: String = ""

    private let accountsKey = "ExpenseFlow.accounts"
    private let credentialsKey = "ExpenseFlow.email"
    private let loggedInKey = "ExpenseFlow.loggedIn"
    private let currentUserIDKey = "ExpenseFlow.currentUserID"

    private var accounts: [AuthAccount] = []

    init() {
        loadAccounts()
        migrateLegacyAccountIfNeeded()
        restoreSession()
        validateSession()
    }

    func signUp(email: String, password: String, confirm: String) {
        authError = ""

        let normalizedEmail = Self.normalizeEmail(email)

        guard isValidEmail(normalizedEmail) else {
            authError = "Please enter a valid email address."
            AppLogger.log("Sign up failed: invalid email \(email)", category: .auth, level: .info)
            return
        }

        guard account(forEmail: normalizedEmail) == nil else {
            authError = "An account with this email already exists."
            AppLogger.log("Sign up failed: duplicate email \(normalizedEmail)", category: .auth, level: .info)
            return
        }

        guard password.count >= 6 else {
            authError = "Password must be at least 6 characters."
            return
        }

        guard isValidPassword(password) else {
            authError = "Password must contain at least one uppercase letter and one number."
            return
        }

        guard password == confirm else {
            authError = "Passwords do not match."
            return
        }

        do {
            try KeychainHelper.savePassword(password, for: Self.keychainAccountIdentifier(forEmail: normalizedEmail))

            let account = AuthAccount(
                email: normalizedEmail,
                provider: .password
            )
            accounts.append(account)
            saveAccounts()
            setAuthenticated(account)

            AppLogger.log("Sign up successful for \(normalizedEmail)", category: .auth, level: .info)
        } catch {
            authError = "Failed to create account. Please try again."
            AppLogger.error("Sign up failed: Keychain save error", error: error, category: .auth)
        }
    }

    func logIn(email: String, password: String) {
        authError = ""

        let normalizedEmail = Self.normalizeEmail(email)

        guard let account = account(forEmail: normalizedEmail) else {
            authError = "No account found with this email. Please sign up."
            AppLogger.log("Login failed: account not found for \(normalizedEmail)", category: .auth, level: .info)
            return
        }

        guard account.provider == .password else {
            authError = "This email uses Sign in with \(account.provider.displayName)."
            AppLogger.log("Login failed: wrong provider for \(normalizedEmail)", category: .auth, level: .default)
            return
        }

        do {
            guard let storedPassword = try KeychainHelper.retrievePassword(
                for: Self.keychainAccountIdentifier(forEmail: normalizedEmail)
            ), storedPassword == password else {
                authError = "Incorrect password."
                AppLogger.log("Login failed: incorrect password for \(normalizedEmail)", category: .auth, level: .default)
                return
            }
        } catch {
            authError = "Failed to verify password. Please try again."
            AppLogger.error("Login failed: Keychain retrieval error", error: error, category: .auth)
            return
        }

        setAuthenticated(account)
        AppLogger.log("Login successful for \(normalizedEmail)", category: .auth, level: .info)
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        authError = ""

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                authError = "Unable to read your Apple sign-in details."
                return
            }

            let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            completeSocialSignIn(
                provider: .apple,
                providerUserID: credential.user,
                email: credential.email,
                displayName: displayName.isEmpty ? nil : displayName
            )
        case .failure(let error):
            authError = "Apple sign in failed: \(error.localizedDescription)"
            AppLogger.error("Apple sign in failed", error: error, category: .auth)
        }
    }

    func completeSocialSignIn(
        provider: AuthProvider,
        providerUserID: String,
        email: String?,
        displayName: String? = nil
    ) {
        authError = ""

        guard provider != .password else {
            authError = "Use email sign up for password accounts."
            return
        }

        if let existingAccount = account(forProvider: provider, providerUserID: providerUserID) {
            setAuthenticated(existingAccount)
            AppLogger.log("Social login successful for \(provider.displayName)", category: .auth, level: .info)
            return
        }

        guard let email else {
            authError = "\(provider.displayName) didn't share an email for this account. Try again with the same provider or remove app access and retry."
            return
        }

        let normalizedEmail = Self.normalizeEmail(email)

        guard isValidEmail(normalizedEmail) else {
            authError = "\(provider.displayName) did not return a valid email address."
            return
        }

        guard account(forEmail: normalizedEmail) == nil else {
            authError = "An account with this email already exists. Use the original sign-in method to avoid duplicates."
            AppLogger.log("Social sign in blocked: duplicate email \(normalizedEmail)", category: .auth, level: .info)
            return
        }

        let account = AuthAccount(
            email: normalizedEmail,
            provider: provider,
            providerUserID: providerUserID,
            displayName: displayName
        )

        accounts.append(account)
        saveAccounts()
        setAuthenticated(account)
        AppLogger.log("Social sign up successful for \(normalizedEmail)", category: .auth, level: .info)
    }

    func startUnsupportedSocialSignIn(provider: AuthProvider) {
        authError = "\(provider.displayName) sign-in still needs that provider's SDK and app credentials configured in ExpenseFlow."
    }

    func logOut() {
        let previousEmail = currentEmail
        isAuthenticated = false
        currentEmail = ""
        currentProvider = nil

        UserDefaults.standard.set(false, forKey: loggedInKey)
        UserDefaults.standard.removeObject(forKey: currentUserIDKey)
        UserDefaults.standard.removeObject(forKey: credentialsKey)

        AppLogger.log("Logout for \(previousEmail)", category: .auth, level: .info)
    }

    private func loadAccounts() {
        guard let data = UserDefaults.standard.data(forKey: accountsKey) else { return }

        do {
            accounts = try JSONDecoder().decode([AuthAccount].self, from: data)
        } catch {
            accounts = []
            AppLogger.error("Failed to load auth accounts", error: error, category: .auth)
        }
    }

    private func saveAccounts() {
        do {
            let data = try JSONEncoder().encode(accounts)
            UserDefaults.standard.set(data, forKey: accountsKey)
        } catch {
            AppLogger.error("Failed to save auth accounts", error: error, category: .auth)
        }
    }

    private func migrateLegacyAccountIfNeeded() {
        guard let legacyEmail = UserDefaults.standard.string(forKey: credentialsKey) else { return }

        let normalizedEmail = Self.normalizeEmail(legacyEmail)
        guard account(forEmail: normalizedEmail) == nil else { return }

        do {
            let legacyPassword =
                try KeychainHelper.retrievePassword(for: legacyEmail)
                ?? KeychainHelper.retrievePassword(for: normalizedEmail)

            guard let legacyPassword else { return }

            let migratedAccount = AuthAccount(
                email: normalizedEmail,
                provider: .password
            )

            accounts.append(migratedAccount)
            try KeychainHelper.savePassword(
                legacyPassword,
                for: Self.keychainAccountIdentifier(forEmail: normalizedEmail)
            )
            saveAccounts()

            AppLogger.log("Migrated legacy auth account for \(normalizedEmail)", category: .auth, level: .info)
        } catch {
            AppLogger.error("Failed to migrate legacy auth account", error: error, category: .auth)
        }
    }

    private func restoreSession() {
        guard UserDefaults.standard.bool(forKey: loggedInKey) else { return }

        if let storedUserID = UserDefaults.standard.string(forKey: currentUserIDKey),
           let userID = UUID(uuidString: storedUserID),
           let account = accounts.first(where: { $0.id == userID }) {
            setAuthenticated(account)
            return
        }

        if let storedEmail = UserDefaults.standard.string(forKey: credentialsKey),
           let account = account(forEmail: Self.normalizeEmail(storedEmail)) {
            setAuthenticated(account)
        }
    }

    private func validateSession() {
        guard isAuthenticated, currentProvider == .password, !currentEmail.isEmpty else { return }

        do {
            if try KeychainHelper.retrievePassword(for: Self.keychainAccountIdentifier(forEmail: currentEmail)) == nil {
                AppLogger.log("Keychain password missing for authenticated user", category: .auth, level: .default)
                logOut()
            }
        } catch {
            AppLogger.error("Error checking Keychain on init", error: error, category: .auth)
            logOut()
        }
    }

    private func setAuthenticated(_ account: AuthAccount) {
        currentEmail = account.email
        currentProvider = account.provider
        isAuthenticated = true

        UserDefaults.standard.set(true, forKey: loggedInKey)
        UserDefaults.standard.set(account.email, forKey: credentialsKey)
        UserDefaults.standard.set(account.id.uuidString, forKey: currentUserIDKey)
    }

    private func account(forEmail normalizedEmail: String) -> AuthAccount? {
        accounts.first { Self.normalizeEmail($0.email) == normalizedEmail }
    }

    private func account(forProvider provider: AuthProvider, providerUserID: String) -> AuthAccount? {
        accounts.first { $0.provider == provider && $0.providerUserID == providerUserID }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email) && email.count <= 254
    }

    private func isValidPassword(_ password: String) -> Bool {
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasUppercase && hasNumber && password.count >= 6
    }

    static func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func keychainAccountIdentifier(forEmail email: String) -> String {
        "password:\(normalizeEmail(email))"
    }
}
