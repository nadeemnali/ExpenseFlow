import SwiftUI

struct PremiumFeaturesView: View {
    @EnvironmentObject private var premiumStore: PremiumFeatureStore
    @State private var showBillScanner = false
    
    var body: some View {
        NavigationView {
            BackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        SectionHeader(title: "Premium Features", subtitle: "Unlock advanced tools")
                        
                        if premiumStore.isPremium {
                            premiumActiveView
                        } else {
                            premiumLockedView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabBarPadding()
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showBillScanner) {
            if premiumStore.isPremium {
                BillScannerView(premiumStore: premiumStore)
            }
        }
    }
    
    private var premiumActiveView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Premium Unlocked")
                        .font(AppTheme.title(16))
                        .fontWeight(.semibold)
                    Text("Thank you for supporting ExpenseFlow!")
                        .font(AppTheme.body(12))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(16)
            .background(AppTheme.teal.opacity(0.2))
            .cornerRadius(12)
            
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    featureRow(
                        icon: "doc.text.viewfinder",
                        title: "Bill Scanner",
                        description: "Scan bills to extract vendor, amount, date, and description automatically"
                    )
                    
                    Divider()
                        .opacity(0.3)
                    
                    featureRow(
                        icon: "star.fill",
                        title: "More Coming Soon",
                        description: "Additional premium features in development"
                    )
                }
            }
            
            Button(action: { showBillScanner = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.viewfinder")
                    Text("Try Bill Scanner")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppTheme.teal)
                .foregroundStyle(AppTheme.ink)
                .cornerRadius(8)
                .fontWeight(.semibold)
            }
            
            Button(action: restorePurchase) {
                if premiumStore.isLoading {
                    ProgressView()
                } else {
                    Text("Restore Purchase")
                }
            }
            .font(AppTheme.body(13))
            .foregroundStyle(.blue)
        }
    }
    
    private var premiumLockedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("Unlock Premium Features")
                    .font(AppTheme.title(18))
                    .fontWeight(.semibold)
                
                Text("Get access to advanced tools with a one-time $0.99 purchase")
                    .font(AppTheme.body(14))
                    .foregroundStyle(AppTheme.ink.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    featureRow(
                        icon: "doc.text.viewfinder",
                        title: "Bill Scanner",
                        description: "Scan bills to automatically extract all data"
                    )
                    
                    Divider()
                        .opacity(0.3)
                    
                    featureRow(
                        icon: "star.fill",
                        title: "Future Features",
                        description: "More premium tools coming soon"
                    )
                }
            }
            
            Button(action: purchasePremium) {
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
            .foregroundStyle(.white)
            .cornerRadius(8)
            .disabled(premiumStore.isLoading)
            
            Button(action: restorePurchase) {
                Text("Restore Purchase")
                    .font(AppTheme.body(13))
            }
            .foregroundStyle(.blue)
            
            if let error = premiumStore.error {
                Text(error.errorDescription ?? "Unknown error")
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.coral)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(16)
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.body(14))
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.ink.opacity(0.6))
            }
            
            Spacer()
        }
    }
    
    private func purchasePremium() {
        Task {
            await premiumStore.purchase()
        }
    }
    
    private func restorePurchase() {
        Task {
            await premiumStore.restorePurchases()
        }
    }
}

struct PremiumFeaturesView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumFeaturesView()
            .environmentObject(PremiumFeatureStore())
    }
}
