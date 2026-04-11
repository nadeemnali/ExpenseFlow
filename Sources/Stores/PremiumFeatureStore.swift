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
        
        self.isPremium = UserDefaults.standard.bool(forKey: Self.premiumPurchasedKey)
        
        self.updateListenerTask = listenForTransactions()
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
                case .verified:
                    UserDefaults.standard.set(true, forKey: Self.premiumPurchasedKey)
                    self.isPremium = true
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
            
            var hasPurchase = false
            for await result in Transaction.all {
                switch result {
                case .verified:
                    hasPurchase = true
                case .unverified:
                    continue
                @unknown default:
                    break
                }
            }
            
            self.isPremium = hasPurchase
            UserDefaults.standard.set(hasPurchase, forKey: Self.premiumPurchasedKey)
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
                case .verified:
                    UserDefaults.standard.set(true, forKey: Self.premiumPurchasedKey)
                    await MainActor.run {
                        self.isPremium = true
                    }
                case .unverified:
                    break
                @unknown default:
                    break
                }
            }
        }
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
