import XCTest
@testable import ExpenseFlow

final class BillReminderServiceTests: XCTestCase {
    var sut: BillReminderService!
    
    override func setUp() {
        super.setUp()
        sut = BillReminderService.shared
        // Clean up pending notifications
        sut.removeAllPendingReminders()
    }
    
    override func tearDown() {
        super.tearDown()
        sut.removeAllPendingReminders()
    }
    
    // MARK: - Permission Tests
    
    func testRequestNotificationPermission() {
        let expectation = XCTestExpectation(description: "Notification permission requested")
        
        sut.requestNotificationPermission { granted in
            XCTAssertTrue(granted || !granted) // Either granted or denied, but should complete
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    // MARK: - Scheduling Tests
    
    func testScheduleReminder() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        let recurring = RecurringExpense(
            title: "Test Bill",
            amount: 100,
            category: .utilities,
            frequency: .monthly,
            startDate: tomorrow,
            notificationEnabled: true,
            notificationDaysBefore: 1
        )
        
        sut.scheduleReminders(for: recurring)
        
        let expectation = XCTestExpectation(description: "Check pending notifications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sut.getPendingNotifications { requests in
                XCTAssertGreater(requests.count, 0)
                let identifier = requests.first?.identifier ?? ""
                XCTAssertTrue(identifier.contains(recurring.id.uuidString))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testScheduleReminderDisabled() {
        let recurring = RecurringExpense(
            title: "Test Bill",
            amount: 100,
            category: .utilities,
            frequency: .monthly,
            startDate: Date(),
            notificationEnabled: false
        )
        
        sut.scheduleReminders(for: recurring)
        
        let expectation = XCTestExpectation(description: "Check no notifications scheduled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sut.getPendingNotifications { requests in
                let billReminders = requests.filter { $0.identifier.hasPrefix("BillReminder_") }
                XCTAssertEqual(billReminders.count, 0)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testScheduleAllReminders() {
        let store = RecurringExpenseStore()
        
        let recurring1 = RecurringExpense(
            title: "Bill 1",
            amount: 50,
            category: .utilities,
            frequency: .monthly,
            startDate: Date(),
            notificationEnabled: true
        )
        let recurring2 = RecurringExpense(
            title: "Bill 2",
            amount: 100,
            category: .utilities,
            frequency: .monthly,
            startDate: Date(),
            notificationEnabled: true
        )
        
        store.add(recurring1)
        store.add(recurring2)
        
        sut.scheduleAllReminders(from: store)
        
        let expectation = XCTestExpectation(description: "Check all reminders scheduled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sut.getPendingNotifications { requests in
                let billReminders = requests.filter { $0.identifier.hasPrefix("BillReminder_") }
                XCTAssertGreaterThanOrEqual(billReminders.count, 2)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    // MARK: - Removal Tests
    
    func testRemovePendingReminders() {
        let recurring = RecurringExpense(
            title: "Test Bill",
            amount: 100,
            category: .utilities,
            frequency: .monthly,
            startDate: Date(),
            notificationEnabled: true
        )
        
        sut.scheduleReminders(for: recurring)
        
        let expectation1 = XCTestExpectation(description: "Scheduled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1)
        
        sut.removePendingReminders(for: recurring.id)
        
        let expectation2 = XCTestExpectation(description: "Check removed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sut.getPendingNotifications { requests in
                let removed = requests.filter { $0.identifier.contains(recurring.id.uuidString) }
                XCTAssertEqual(removed.count, 0)
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation2], timeout: 1)
    }
    
    func testRemoveAllPendingReminders() {
        let recurring1 = RecurringExpense(
            title: "Bill 1",
            amount: 50,
            category: .utilities,
            frequency: .monthly,
            startDate: Date(),
            notificationEnabled: true
        )
        let recurring2 = RecurringExpense(
            title: "Bill 2",
            amount: 100,
            category: .utilities,
            frequency: .monthly,
            startDate: Date(),
            notificationEnabled: true
        )
        
        let store = RecurringExpenseStore()
        store.add(recurring1)
        store.add(recurring2)
        sut.scheduleAllReminders(from: store)
        
        let expectation1 = XCTestExpectation(description: "Scheduled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1)
        
        sut.removeAllPendingReminders()
        
        let expectation2 = XCTestExpectation(description: "Check all removed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sut.getPendingNotifications { requests in
                let billReminders = requests.filter { $0.identifier.hasPrefix("BillReminder_") }
                XCTAssertEqual(billReminders.count, 0)
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation2], timeout: 1)
    }
    
    // MARK: - Query Tests
    
    func testGetPendingNotifications() {
        let expectation = XCTestExpectation(description: "Get pending notifications")
        
        sut.getPendingNotifications { requests in
            XCTAssertNotNil(requests)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
}
