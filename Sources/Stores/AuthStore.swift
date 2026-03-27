import Foundation
import Combine
import os.log

final class AuthStore: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentEmail: String = ""
    @Published var authError: String = ""

    private let credentialsKey = "ExpenseFlow.email"
    private let loggedInKey = "ExpenseFlow.loggedIn"

    init() {
        isAuthenticated = UserDefaults.standard.bool(forKey: loggedInKey)
        currentEmail = UserDefaults.standard.string(forKey: credentialsKey) ?? ""
        
        // Verify Keychain consistency
        if isAuthenticated && !currentEmail.isEmpty {
            do {
                if try KeychainHelper.retrievePassword(for: currentEmail) == nil {
                    AppLogger.log("Keychain password missing for authenticated user", 
                                 category: .auth, level: .default)
                    logOut()
                }
            } catch {
                AppLogger.error("Error checking Keychain on init", error: error, category: .auth)
            }
        }
    }

    func signUp(email: String, password: String, confirm: String) {
        authError = ""
        
        // Validate email format
        guard isValidEmail(email) else {
            authError = "Please enter a valid email address."
            AppLogger.log("Sign up failed: invalid email \(email)", category: .auth, level: .info)
            return
        }
        
        // Validate password length
        guard password.count >= 6 else {
            authError = "Password must be at least 6 characters."
            return
        }
        
        // Validate password strength (at least one uppercase, one number)
        guard isValidPassword(password) else {
            authError = "Password must contain at least one uppercase letter and one number."
            return
        }
        
        // Validate password match
        guard password == confirm else {
            authError = "Passwords do not match."
            return
        }

        // Save password to Keychain
        do {
            try KeychainHelper.savePassword(password, for: email)
            UserDefaults.standard.set(email, forKey: credentialsKey)
            AppLogger.log("Sign up successful for \(email)", category: .auth, level: .info)
            logIn(email: email, password: password)
        } catch {
            authError = "Failed to create account. Please try again."
            AppLogger.error("Sign up failed: Keychain save error", error: error, category: .auth)
        }
    }

    func logIn(email: String, password: String) {
        authError = ""
        
        // Get stored email
        guard let storedEmail = UserDefaults.standard.string(forKey: credentialsKey),
              storedEmail.lowercased() == email.lowercased() else {
            authError = "No account found with this email. Please sign up."
            AppLogger.log("Login failed: account not found for \(email)", category: .auth, level: .info)
            return
        }

        // Retrieve password from Keychain
        do {
            guard let storedPassword = try KeychainHelper.retrievePassword(for: storedEmail),
                  storedPassword == password else {
                authError = "Incorrect password."
                AppLogger.log("Login failed: incorrect password for \(email)", category: .auth, level: .default)
                return
            }
        } catch {
            authError = "Failed to verify password. Please try again."
            AppLogger.error("Login failed: Keychain retrieval error", error: error, category: .auth)
            return
        }

        // Login successful
        currentEmail = storedEmail
        isAuthenticated = true
        UserDefaults.standard.set(true, forKey: loggedInKey)
        AppLogger.log("Login successful for \(email)", category: .auth, level: .info)
    }

    func logOut() {
        let previousEmail = currentEmail
        isAuthenticated = false
        currentEmail = ""
        UserDefaults.standard.set(false, forKey: loggedInKey)
        AppLogger.log("Logout for \(previousEmail)", category: .auth, level: .info)
    }
    
    // MARK: - Private Helper Methods
    
    /// Validates email format using regex
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email) && email.count <= 254
    }
    
    /// Validates password strength: at least 6 chars, one uppercase, one number
    private func isValidPassword(_ password: String) -> Bool {
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasUppercase && hasNumber && password.count >= 6
    }
}

struct UserCredentials: Codable {
    let email: String
    let password: String
}
