import SwiftUI

struct ListRowStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

extension View {
    func listRowStyle() -> some View {
        modifier(ListRowStyleModifier())
    }
}
