import SwiftUI
import UIKit

struct PremiumLockedView: View {
    @ObservedObject var premiumStore: PremiumFeatureStore
    let action: () -> Void
    let featureName: String
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                VStack(spacing: 12) {
                    Text("Premium Feature")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Unlock \(featureName) with a one-time purchase of $0.99")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: purchaseAction) {
                    if premiumStore.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Unlock for $0.99")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(premiumStore.isLoading)
                
                Button(action: restoreAction) {
                    Text("Restore Purchase")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if let error = premiumStore.error {
                    Text(error.errorDescription ?? "Unknown error")
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func purchaseAction() {
        Task {
            await premiumStore.purchase()
            if premiumStore.isPremium {
                action()
            }
        }
    }
    
    private func restoreAction() {
        Task {
            await premiumStore.restorePurchases()
        }
    }
}

struct PremiumLockedView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumLockedView(
            premiumStore: PremiumFeatureStore(),
            action: {},
            featureName: "Bill Scanner"
        )
    }
}
