import SwiftUI

enum DSMotion {
    static let quick = Animation.spring(duration: 0.24, bounce: 0.16)
    static let smooth = Animation.spring(duration: 0.44, bounce: 0.08)
    static let snappy = Animation.spring(duration: 0.36, bounce: 0.16)
    static let gentle = Animation.spring(duration: 0.62, bounce: 0.08)
    static let list = Animation.spring(duration: 0.56, bounce: 0.1)
    static let page = Animation.spring(duration: 0.64, bounce: 0.06)
    static let carousel = Animation.spring(duration: 0.72, bounce: 0.08)
    static let focus = Animation.spring(duration: 0.66, bounce: 0.1)
    static let discovery = Animation.spring(duration: 0.96, bounce: 0.06)
    static let hero = Animation.spring(duration: 0.86, bounce: 0.06)

    static func delayed(_ index: Int, base: Double = 0.045) -> Animation {
        gentle.delay(Double(index) * base)
    }
}

struct DSAppearModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false
    let delay: Double
    let distance: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (hasAppeared ? 0 : distance))
            .scaleEffect(reduceMotion ? 1 : (hasAppeared ? 1 : 0.972), anchor: .top)
            .blur(radius: reduceMotion ? 0 : (hasAppeared ? 0 : 5))
            .onAppear {
                guard !hasAppeared else { return }

                withAnimation(reduceMotion ? .easeOut(duration: 0.01) : DSMotion.gentle.delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

struct DSScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.965

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(DSMotion.snappy, value: configuration.isPressed)
    }
}

struct DSLiftButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.985

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .offset(y: configuration.isPressed ? -2 : 0)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.14 : 0), radius: configuration.isPressed ? 18 : 0, x: 0, y: configuration.isPressed ? 12 : 0)
            .animation(DSMotion.snappy, value: configuration.isPressed)
    }
}

extension AnyTransition {
    static var dsCard: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .scale(scale: 0.94, anchor: .center).combined(with: .opacity)
        )
    }

    static var dsPanel: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

extension View {
    func dsAppear(delay: Double = 0, distance: CGFloat = 18) -> some View {
        modifier(DSAppearModifier(delay: delay, distance: distance))
    }

    func dsPressable(scale: CGFloat = 0.965) -> some View {
        buttonStyle(DSScaleButtonStyle(scale: scale))
    }

    func dsLiftable(scale: CGFloat = 0.985) -> some View {
        buttonStyle(DSLiftButtonStyle(scale: scale))
    }
}
