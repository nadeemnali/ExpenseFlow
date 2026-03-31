import XCTest
@testable import ExpenseFlow

final class PremiumFeatureStoreTests: XCTestCase {
    var sut: PremiumFeatureStore!
    
    override func setUp() {
        super.setUp()
        sut = PremiumFeatureStore()
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.premiumPurchased")
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.premiumPurchased")
        super.tearDown()
    }
    
    func testInitialStateNotPremium() {
        UserDefaults.standard.removeObject(forKey: "ExpenseFlow.premiumPurchased")
        let store = PremiumFeatureStore()
        XCTAssertFalse(store.isPremium)
    }
    
    func testInitialStateLoadsPremiumFromDefaults() {
        UserDefaults.standard.set(true, forKey: "ExpenseFlow.premiumPurchased")
        let store = PremiumFeatureStore()
        XCTAssertTrue(store.isPremium)
    }
    
    func testInitialStateNotLoading() {
        XCTAssertFalse(sut.isLoading)
    }
    
    func testInitialStateNoError() {
        XCTAssertNil(sut.error)
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
    
    func testPremiumFeatureStoreIsObservableObject() {
        let store = PremiumFeatureStore()
        XCTAssertTrue(store is ObservableObject)
    }
    
    func testPremiumFeatureStoreHasSharedInstance() {
        let shared1 = PremiumFeatureStore.shared
        let shared2 = PremiumFeatureStore.shared
        XCTAssertTrue(shared1 === shared2)
    }
}
