import SwiftUI

struct AppBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                DSColor.background
                    .ignoresSafeArea()
            }
            .scrollContentBackground(.hidden)
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackground())
    }
}
