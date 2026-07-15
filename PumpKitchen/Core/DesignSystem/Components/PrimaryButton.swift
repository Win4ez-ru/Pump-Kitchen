import SwiftUI

struct PrimaryButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let systemImage: String
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String = "sparkles",
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                buttonLabel
                    .glassEffect(
                        .regular
                            .tint(glassTint)
                            .interactive(),
                        in: .capsule
                    )
                    .overlay {
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.32), .white.opacity(0.06)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.75
                            )
                    }
            } else {
                buttonLabel
                    .background(.ultraThinMaterial, in: Capsule())
                    .background(glassTint, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(.white.opacity(0.16), lineWidth: 0.75)
                    }
            }
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.75 : 1)
    }

    private var glassTint: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.34)
            : Color(hex: 0x536049).opacity(0.52)
    }

    private var buttonLabel: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: systemImage)
                        .foregroundStyle(DSColor.accent)
                        .symbolEffect(.bounce, value: systemImage)
                        .transition(.scale.combined(with: .opacity))
                }

                Text(LocalizedStringKey(title))
                    .font(DSTypography.body.weight(.semibold))
                    .contentTransition(.opacity)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Capsule())
            .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
            .animation(DSMotion.snappy, value: isLoading)
        }
        .buttonStyle(DSScaleButtonStyle(scale: 0.975))
    }
}
