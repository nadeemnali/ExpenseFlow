import SwiftUI

struct AuthRootView: View {
    @EnvironmentObject private var authStore: AuthStore

    var body: some View {
        Group {
            if authStore.isAuthenticated {
                MainTabView()
            } else {
                AuthShellView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: authStore.isAuthenticated)
    }
}
