import XCTest
@testable import ExpenseFlow

final class PremiumFeatureStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.premiumPurchased")
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.premiumPurchased")
        super.tearDown()
    }
    
    func testPremiumStatusPersistsToUserDefaults() {
        let key = "ExpenseFlow.premiumPurchased"
        XCTAssertFalse(UserDefaults.standard.bool(forKey: key))
        
        UserDefaults.standard.set(true, forKey: key)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: key))
    }
    
    func testErrorMessageForProductNotFound() {
        let error = PremiumError.productNotFound
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Premium"))
    }
    
    func testErrorMessageForUserCancelled() {
        let error = PremiumError.userCancelled
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("cancelled"))
    }
    
    func testErrorMessageForPending() {
        let error = PremiumError.pending
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("pending"))
    }
    
    func testErrorMessageForVerificationFailed() {
        let error = PremiumError.verificationFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("verification"))
    }
    
    func testErrorMessageForNotificationPermissionDenied() {
        let error = PremiumError.notificationPermissionDenied
        XCTAssertNotNil(error.errorDescription)
    }
    
    func testErrorMessageForPurchaseFailed() {
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let error = PremiumError.purchaseFailed(testError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Purchase"))
    }
    
    func testErrorMessageForRestoreFailed() {
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let error = PremiumError.restoreFailed(testError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Restore"))
    }
}
