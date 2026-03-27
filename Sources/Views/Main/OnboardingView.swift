import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var onboardingStore: OnboardingStore
    @State private var selection: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Track daily moments",
            subtitle: "Log expenses in seconds with smart categories and notes.",
            systemImage: "plus.circle.fill",
            accent: AppTheme.coral
        ),
        OnboardingPage(
            title: "See the bigger picture",
            subtitle: "Beautiful charts show monthly trends and category mix.",
            systemImage: "chart.bar.xaxis",
            accent: AppTheme.ocean
        ),
        OnboardingPage(
            title: "Stay on budget",
            subtitle: "Set a monthly goal and keep your spending in check.",
            systemImage: "target",
            accent: AppTheme.teal
        )
    ]

    var body: some View {
        BackgroundView {
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button("Skip") {
                        onboardingStore.complete()
                    }
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.ink.opacity(0.6))
                }
                .padding(.horizontal, 24)

                TabView(selection: $selection) {
                    ForEach(pages.indices, id: \.self) { index in
                        onboardingCard(for: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(selection == pages.count - 1 ? "Get started" : "Continue") {
                    advance()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func onboardingCard(for page: OnboardingPage) -> some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.accent.opacity(0.2))
                    .frame(width: 140, height: 140)

                Image(systemName: page.systemImage)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(page.accent)
            }

            VStack(spacing: 10) {
                Text(page.title)
                    .font(AppTheme.display(26))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(AppTheme.body(14))
                    .foregroundStyle(AppTheme.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding(.top, 12)
    }

    private func advance() {
        if selection < pages.count - 1 {
            withAnimation {
                selection += 1
            }
        } else {
            onboardingStore.complete()
        }
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
}
