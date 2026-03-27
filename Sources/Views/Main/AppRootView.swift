import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var onboardingStore: OnboardingStore
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if onboardingStore.hasSeenOnboarding {
                AuthRootView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: onboardingStore.hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.35), value: showSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}
