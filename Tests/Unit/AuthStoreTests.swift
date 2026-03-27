import XCTest
@testable import ExpenseFlow

final class AuthStoreTests: XCTestCase {
    var sut: AuthStore!
    
    override func setUp() {
        super.setUp()
        sut = AuthStore()
        // Clean up any previous test data
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.loggedIn")
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.email")
        _ = KeychainHelper.deletePassword(for: "test@example.com")
    }
    
    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.loggedIn")
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.email")
        _ = KeychainHelper.deletePassword(for: "test@example.com")
        sut = nil
    }
    
    // MARK: - Email Validation Tests
    
    func testValidEmailAccepted() {
        // Valid emails should be accepted
        let validEmails = [
            "user@example.com",
            "john.doe@company.co.uk",
            "test+tag@domain.org",
            "name123@subdomain.example.com"
        ]
        
        for email in validEmails {
            sut.signUp(email: email, password: "Password1", confirm: "Password1")
            XCTAssertEqual(sut.authError, "", "Email '\(email)' should be valid")
        }
    }
    
    func testInvalidEmailRejected() {
        // Invalid emails should be rejected
        let invalidEmails = [
            "plaintext",           // No @
            "user@",               // No domain
            "@example.com",        // No local part
            "user@example",        // No TLD
            "user name@example.com" // Space in email
        ]
        
        for email in invalidEmails {
            sut.signUp(email: email, password: "Password1", confirm: "Password1")
            XCTAssertNotEqual(sut.authError, "", "Email '\(email)' should be invalid")
            XCTAssertTrue(sut.authError.contains("valid email"), "Should indicate invalid email")
        }
    }
    
    // MARK: - Password Strength Tests
    
    func testPasswordRequiresMinimumLength() {
        sut.signUp(email: "test@example.com", password: "Pass1", confirm: "Pass1")
        XCTAssertTrue(sut.authError.contains("6 characters"), "Should require 6+ characters")
    }
    
    func testPasswordRequiresUppercase() {
        sut.signUp(email: "test@example.com", password: "password1", confirm: "password1")
        XCTAssertTrue(sut.authError.contains("uppercase"), "Should require uppercase letter")
    }
    
    func testPasswordRequiresNumber() {
        sut.signUp(email: "test@example.com", password: "Password", confirm: "Password")
        XCTAssertTrue(sut.authError.contains("number"), "Should require number")
    }
    
    func testValidPasswordAccepted() {
        sut.signUp(email: "test@example.com", password: "Password1", confirm: "Password1")
        XCTAssertEqual(sut.authError, "", "Valid password should be accepted")
    }
    
    // MARK: - Password Confirmation Tests
    
    func testPasswordsMustMatch() {
        sut.signUp(email: "test@example.com", password: "Password1", confirm: "Password2")
        XCTAssertTrue(sut.authError.contains("not match"), "Passwords must match")
    }
    
    // MARK: - Sign Up Tests
    
    func testSuccessfulSignUp() {
        sut.signUp(email: "newuser@example.com", password: "Password1", confirm: "Password1")
        XCTAssertEqual(sut.authError, "")
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentEmail, "newuser@example.com")
    }
    
    func testPasswordSavedToKeychain() {
        let email = "secure@example.com"
        let password = "SecurePass1"
        
        sut.signUp(email: email, password: password, confirm: password)
        
        // Verify password is in Keychain
        let retrievedPassword = try? KeychainHelper.retrievePassword(for: email)
        XCTAssertEqual(retrievedPassword, password, "Password should be saved to Keychain")
    }
    
    // MARK: - Login Tests
    
    func testLoginWithCorrectCredentials() {
        // First sign up
        sut.signUp(email: "user@example.com", password: "Password1", confirm: "Password1")
        sut.logOut()
        XCTAssertFalse(sut.isAuthenticated)
        
        // Then login
        sut.logIn(email: "user@example.com", password: "Password1")
        XCTAssertEqual(sut.authError, "")
        XCTAssertTrue(sut.isAuthenticated)
    }
    
    func testLoginWithIncorrectPassword() {
        sut.signUp(email: "user@example.com", password: "Password1", confirm: "Password1")
        sut.logOut()
        
        sut.logIn(email: "user@example.com", password: "WrongPassword1")
        XCTAssertTrue(sut.authError.contains("Incorrect"))
        XCTAssertFalse(sut.isAuthenticated)
    }
    
    func testLoginWithNonexistentAccount() {
        sut.logIn(email: "nonexistent@example.com", password: "Password1")
        XCTAssertTrue(sut.authError.contains("No account"))
        XCTAssertFalse(sut.isAuthenticated)
    }
    
    func testLoginCaseInsensitive() {
        sut.signUp(email: "User@Example.com", password: "Password1", confirm: "Password1")
        sut.logOut()
        
        sut.logIn(email: "user@example.com", password: "Password1")
        XCTAssertTrue(sut.isAuthenticated)
    }
    
    // MARK: - Logout Tests
    
    func testLogout() {
        sut.signUp(email: "user@example.com", password: "Password1", confirm: "Password1")
        XCTAssertTrue(sut.isAuthenticated)
        
        sut.logOut()
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertEqual(sut.currentEmail, "")
    }
}
