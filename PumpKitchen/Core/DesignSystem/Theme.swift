import SwiftUI

struct AppBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(colorScheme == .dark ? DSColor.darkPaper : DSColor.ricePaper)
            .scrollContentBackground(.hidden)
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackground())
    }
}

