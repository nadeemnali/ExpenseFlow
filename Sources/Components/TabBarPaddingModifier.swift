import SwiftUI

struct TabBarPaddingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 72)
            }
    }
}

extension View {
    func tabBarPadding() -> some View {
        modifier(TabBarPaddingModifier())
    }
}
