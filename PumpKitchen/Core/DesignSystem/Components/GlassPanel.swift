import SwiftUI

struct GlassPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(DSSpacing.md)
            .editorialGlass(cornerRadius: 24)
    }
}
