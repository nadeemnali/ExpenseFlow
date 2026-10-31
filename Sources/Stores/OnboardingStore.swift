import Foundation

final class OnboardingStore: ObservableObject {
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }

    private let key = "ExpenseFlow.hasSeenOnboarding"

    init() {
        hasSeenOnboarding = UserDefaults.standard.bool(forKey: key)
    }

    func complete() {
        hasSeenOnboarding = true
    }

    func reset() {
        hasSeenOnboarding = false
    }
}
