import XCTest
@testable import ExpenseFlow

final class AuthStoreTests: XCTestCase {
    var sut: AuthStore!

    override func setUp() {
        super.setUp()
        clearAuthState()
        sut = AuthStore()
    }

    override func tearDown() {
        clearAuthState()
        sut = nil
        super.tearDown()
    }

    func testValidEmailAccepted() {
        let validEmails = [
            "user@example.com",
            "john.doe@company.co.uk",
            "test+tag@domain.org",
            "name123@subdomain.example.com"
        ]

        for email in validEmails {
            sut.signUp(email: email, password: "Password1", confirm: "Password1")
            XCTAssertEqual(sut.authError, "", "Email '\(email)' should be valid")
            sut.logOut()
            clearStoredAccount(email)
        }
    }

    func testInvalidEmailRejected() {
        let invalidEmails = [
            "plaintext",
            "user@",
            "@example.com",
            "user@example",
            "user name@example.com"
        ]

        for email in invalidEmails {
            sut.signUp(email: email, password: "Password1", confirm: "Password1")
            XCTAssertNotEqual(sut.authError, "", "Email '\(email)' should be invalid")
            XCTAssertTrue(sut.authError.contains("valid email"))
        }
    }

    func testPasswordRequiresMinimumLength() {
        sut.signUp(email: "test@example.com", password: "Pass1", confirm: "Pass1")
        XCTAssertTrue(sut.authError.contains("6 characters"))
    }

    func testPasswordRequiresUppercase() {
        sut.signUp(email: "test@example.com", password: "password1", confirm: "password1")
        XCTAssertTrue(sut.authError.contains("uppercase"))
    }

    func testPasswordRequiresNumber() {
        sut.signUp(email: "test@example.com", password: "Password", confirm: "Password")
        XCTAssertTrue(sut.authError.contains("number"))
    }

    func testValidPasswordAccepted() {
        sut.signUp(email: "test@example.com", password: "Password1", confirm: "Password1")
        XCTAssertEqual(sut.authError, "")
    }

    func testPasswordsMustMatch() {
        sut.signUp(email: "test@example.com", password: "Password1", confirm: "Password2")
        XCTAssertTrue(sut.authError.contains("not match"))
    }

    func testSuccessfulSignUp() {
        sut.signUp(email: "newuser@example.com", password: "Password1", confirm: "Password1")
        XCTAssertEqual(sut.authError, "")
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentEmail, "newuser@example.com")
        XCTAssertEqual(sut.currentProvider, .password)
    }

    func testDuplicateEmailRejectedCaseInsensitive() {
        sut.signUp(email: "newuser@example.com", password: "Password1", confirm: "Password1")
        sut.logOut()

        sut.signUp(email: "NewUser@Example.com", password: "Password1", confirm: "Password1")

        XCTAssertTrue(sut.authError.contains("already exists"))
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testPasswordSavedToKeychain() {
        let email = "secure@example.com"
        let password = "SecurePass1"

        sut.signUp(email: email, password: password, confirm: password)

        let retrievedPassword = try? KeychainHelper.retrievePassword(
            for: AuthStore.keychainAccountIdentifier(forEmail: email)
        )
        XCTAssertEqual(retrievedPassword, password)
    }

    func testLoginWithCorrectCredentials() {
        sut.signUp(email: "user@example.com", password: "Password1", confirm: "Password1")
        sut.logOut()

        sut.logIn(email: "user@example.com", password: "Password1")
        XCTAssertEqual(sut.authError, "")
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentProvider, .password)
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

    func testSocialSignInCreatesPersistentAccount() {
        sut.completeSocialSignIn(
            provider: .apple,
            providerUserID: "apple-user-1",
            email: "social@example.com",
            displayName: "Social User"
        )

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentEmail, "social@example.com")
        XCTAssertEqual(sut.currentProvider, .apple)

        let restoredStore = AuthStore()
        XCTAssertTrue(restoredStore.isAuthenticated)
        XCTAssertEqual(restoredStore.currentEmail, "social@example.com")
        XCTAssertEqual(restoredStore.currentProvider, .apple)
    }

    func testSocialSignInRejectsDuplicateEmail() {
        sut.signUp(email: "duplicate@example.com", password: "Password1", confirm: "Password1")
        sut.logOut()

        sut.completeSocialSignIn(
            provider: .apple,
            providerUserID: "apple-user-2",
            email: "duplicate@example.com",
            displayName: "Duplicate User"
        )

        XCTAssertTrue(sut.authError.contains("already exists"))
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testPasswordLoginRejectedForSocialAccount() {
        sut.completeSocialSignIn(
            provider: .apple,
            providerUserID: "apple-user-3",
            email: "appleonly@example.com",
            displayName: nil
        )
        sut.logOut()

        sut.logIn(email: "appleonly@example.com", password: "Password1")

        XCTAssertTrue(sut.authError.contains("Sign in with Apple"))
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testLogout() {
        sut.signUp(email: "user@example.com", password: "Password1", confirm: "Password1")
        XCTAssertTrue(sut.isAuthenticated)

        sut.logOut()
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertEqual(sut.currentEmail, "")
        XCTAssertNil(sut.currentProvider)
    }

    private func clearAuthState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "ExpenseFlow.loggedIn")
        defaults.removeObject(forKey: "ExpenseFlow.email")
        defaults.removeObject(forKey: "ExpenseFlow.currentUserID")
        defaults.removeObject(forKey: "ExpenseFlow.accounts")

        let emails = [
            "test@example.com",
            "newuser@example.com",
            "secure@example.com",
            "user@example.com",
            "social@example.com",
            "duplicate@example.com",
            "appleonly@example.com"
        ]

        for email in emails {
            clearStoredAccount(email)
            _ = KeychainHelper.deletePassword(for: email)
        }
    }

    private func clearStoredAccount(_ email: String) {
        _ = KeychainHelper.deletePassword(for: AuthStore.keychainAccountIdentifier(forEmail: email))
    }
}
