import Foundation
import StoreKit
import UserNotifications

@MainActor
class PremiumFeatureStore: NSObject, ObservableObject {
    static let shared = PremiumFeatureStore()
    
    private static let premiumPurchasedKey = "ExpenseFlow.premiumPurchased"
    private static let productID = "com.expenseflow.ocr_bill_scanner"
    
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: PremiumError? = nil
    
    private var updateListenerTask: Task<Void, Never>? = nil
    
    override init() {
        super.init()

        self.updateListenerTask = listenForTransactions()

        Task {
            await refreshPremiumStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func purchase() async {
        isLoading = true
        error = nil
        
        do {
            guard let product = try await Product.products(for: [Self.productID]).first else {
                throw PremiumError.productNotFound
            }
            
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    guard transaction.productID == Self.productID else {
                        throw PremiumError.verificationFailed
                    }
                    await transaction.finish()
                    setPremiumStatus(true)
                case .unverified:
                    throw PremiumError.verificationFailed
                @unknown default:
                    throw PremiumError.unknownError
                }
            case .userCancelled:
                error = .userCancelled
            case .pending:
                error = .pending
            @unknown default:
                throw PremiumError.unknownError
            }
        } catch {
            if let storeError = error as? StoreKitError {
                self.error = .storeKitError(storeError)
            } else {
                self.error = .purchaseFailed(error)
            }
        }
        
        isLoading = false
    }
    
    func restorePurchases() async {
        isLoading = true
        error = nil
        
        do {
            try await AppStore.sync()
            await refreshPremiumStatus()
        } catch {
            if let storeError = error as? StoreKitError {
                self.error = .storeKitError(storeError)
            } else {
                self.error = .restoreFailed(error)
            }
        }
        
        isLoading = false
    }
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            self.error = .notificationPermissionDenied
            return false
        }
    }
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    if transaction.productID == Self.productID {
                        await transaction.finish()
                        await MainActor.run {
                            self.setPremiumStatus(transaction.revocationDate == nil)
                        }
                    }
                case .unverified:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    private func refreshPremiumStatus() async {
        var hasActivePremium = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == Self.productID else { continue }
            guard transaction.revocationDate == nil else { continue }

            hasActivePremium = true
            break
        }

        setPremiumStatus(hasActivePremium)
    }

    private func setPremiumStatus(_ isPremium: Bool) {
        self.isPremium = isPremium
        UserDefaults.standard.set(isPremium, forKey: Self.premiumPurchasedKey)
        UserDefaults.standard.synchronize()
    }
}

enum PremiumError: LocalizedError {
    case productNotFound
    case purchaseFailed(Error)
    case restoreFailed(Error)
    case verificationFailed
    case userCancelled
    case pending
    case storeKitError(StoreKitError)
    case notificationPermissionDenied
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Premium feature not available"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .restoreFailed(let error):
            return "Restore failed: \(error.localizedDescription)"
        case .verificationFailed:
            return "Purchase verification failed"
        case .userCancelled:
            return "Purchase cancelled"
        case .pending:
            return "Purchase pending"
        case .storeKitError(let error):
            return "Store error: \(error.localizedDescription)"
        case .notificationPermissionDenied:
            return "Notification permission denied"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
}
