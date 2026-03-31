import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Home", systemImage: "sparkles")
            }

            NavigationStack {
                AddExpenseView()
            }
            .tabItem {
                Label("Add", systemImage: "plus.circle.fill")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "chart.bar.xaxis")
            }
            
            NavigationStack {
                PremiumFeaturesView()
            }
            .tabItem {
                Label("Premium", systemImage: "crown.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(AppTheme.ocean)
    }
}
