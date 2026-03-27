import XCTest
@testable import ExpenseFlow

final class KeychainHelperTests: XCTestCase {
    let testAccount = "test.keychain.account@example.com"
    
    override func tearDown() {
        super.tearDown()
        // Clean up after each test
        _ = KeychainHelper.deletePassword(for: testAccount)
    }
    
    // MARK: - Save and Retrieve Tests
    
    func testSaveAndRetrievePassword() throws {
        let password = "SecurePassword123!"
        
        try KeychainHelper.savePassword(password, for: testAccount)
        let retrieved = try KeychainHelper.retrievePassword(for: testAccount)
        
        XCTAssertEqual(retrieved, password)
    }
    
    func testRetrieveNonexistentPassword() throws {
        let retrieved = try KeychainHelper.retrievePassword(for: "nonexistent@example.com")
        XCTAssertNil(retrieved)
    }
    
    // MARK: - Update Password Tests
    
    func testUpdatePassword() throws {
        let originalPassword = "OriginalPassword1"
        let newPassword = "NewPassword2"
        
        try KeychainHelper.savePassword(originalPassword, for: testAccount)
        try KeychainHelper.savePassword(newPassword, for: testAccount)
        
        let retrieved = try KeychainHelper.retrievePassword(for: testAccount)
        XCTAssertEqual(retrieved, newPassword)
    }
    
    // MARK: - Delete Tests
    
    func testDeletePassword() throws {
        let password = "PasswordToDelete1"
        try KeychainHelper.savePassword(password, for: testAccount)
        
        let deleted = KeychainHelper.deletePassword(for: testAccount)
        XCTAssertTrue(deleted)
        
        let retrieved = try KeychainHelper.retrievePassword(for: testAccount)
        XCTAssertNil(retrieved)
    }
    
    func testDeleteNonexistentPassword() {
        let deleted = KeychainHelper.deletePassword(for: "nonexistent@example.com")
        XCTAssertTrue(deleted) // Deletion of non-existent item returns true
    }
    
    // MARK: - Special Characters Tests
    
    func testPasswordWithSpecialCharacters() throws {
        let specialPasswords = [
            "P@ssw0rd!#$%^&*()",
            "测试密码123",  // Chinese characters
            "Пароль1",     // Cyrillic characters
            "🔐SecurePass1",  // Emoji
            "Pass\nword\t1"  // Whitespace
        ]
        
        for password in specialPasswords {
            try KeychainHelper.savePassword(password, for: testAccount + password.prefix(3))
            let retrieved = try KeychainHelper.retrievePassword(for: testAccount + password.prefix(3))
            XCTAssertEqual(retrieved, password)
            _ = KeychainHelper.deletePassword(for: testAccount + password.prefix(3))
        }
    }
    
    // MARK: - Long Password Tests
    
    func testLongPassword() throws {
        let longPassword = String(repeating: "a", count: 1000)
        
        try KeychainHelper.savePassword(longPassword, for: testAccount)
        let retrieved = try KeychainHelper.retrievePassword(for: testAccount)
        
        XCTAssertEqual(retrieved, longPassword)
    }
    
    // MARK: - Empty String Tests
    
    func testEmptyPassword() throws {
        let emptyPassword = ""
        
        try KeychainHelper.savePassword(emptyPassword, for: testAccount)
        let retrieved = try KeychainHelper.retrievePassword(for: testAccount)
        
        XCTAssertEqual(retrieved, "")
    }
    
    // MARK: - Multiple Accounts Tests
    
    func testMultipleAccounts() throws {
        let accounts = [
            ("user1@example.com", "Password1"),
            ("user2@example.com", "Password2"),
            ("user3@example.com", "Password3")
        ]
        
        for (account, password) in accounts {
            try KeychainHelper.savePassword(password, for: account)
        }
        
        for (account, expectedPassword) in accounts {
            let retrieved = try KeychainHelper.retrievePassword(for: account)
            XCTAssertEqual(retrieved, expectedPassword)
            _ = KeychainHelper.deletePassword(for: account)
        }
    }
}
