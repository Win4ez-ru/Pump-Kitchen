import SwiftUI

struct PumpLogoView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [DSColor.accent, Color(hex: 0x8DA2BE), Color(hex: 0xD7DFEA)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Capsule()
                .fill(DSColor.onAccent.opacity(0.96))
                .frame(width: size * 0.52, height: size * 0.08)

            HStack(spacing: size * 0.36) {
                Capsule()
                    .fill(DSColor.onAccent.opacity(0.96))
                    .frame(width: size * 0.1, height: size * 0.24)
                Capsule()
                    .fill(DSColor.onAccent.opacity(0.96))
                    .frame(width: size * 0.1, height: size * 0.24)
            }

            Capsule()
                .fill(DSColor.onAccent.opacity(0.96))
                .frame(width: size * 0.05, height: size * 0.54)

            HStack(spacing: size * 0.07) {
                Capsule()
                    .fill(DSColor.onAccent.opacity(0.96))
                    .frame(width: size * 0.03, height: size * 0.18)
                Capsule()
                    .fill(DSColor.onAccent.opacity(0.96))
                    .frame(width: size * 0.03, height: size * 0.18)
            }
            .offset(y: -size * 0.17)
        }
        .frame(width: size, height: size)
    }
}

struct DSCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var showsBorder = true
    var showsShadow = true

    func body(content: Content) -> some View {
        content
            .background(DSColor.card.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                if showsBorder {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 0.75)
                }
            }
            .shadow(color: .black.opacity(showsShadow ? 0.18 : 0), radius: 22, x: 0, y: 14)
    }
}

struct DSFieldBackground: ViewModifier {
    var isFocused = false

    func body(content: Content) -> some View {
        content
            .font(DSTypography.callout)
            .foregroundStyle(DSColor.textPrimary)
            .tint(DSColor.accent)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(DSColor.elevatedCard.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isFocused ? DSColor.accent.opacity(0.9) : DSColor.border.opacity(0.55), lineWidth: 1)
            }
    }
}

struct DSPill: View {
    let title: String
    var isSelected = false
    var isDestructive = false

    var body: some View {
        Text(LocalizedStringKey(title))
            .font(DSTypography.micro)
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(background.opacity(0.82))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(border, lineWidth: isSelected || isDestructive ? 1 : 0)
            }
            .animation(DSMotion.snappy, value: isSelected)
    }

    private var foreground: Color {
        if isDestructive { return DSColor.destructive }
        return isSelected ? DSColor.accent : DSColor.textPrimary
    }

    private var background: Color {
        if isDestructive { return DSColor.destructiveSurface }
        return isSelected ? DSColor.accentSurface : DSColor.elevatedCard
    }

    private var border: Color {
        if isDestructive { return DSColor.destructiveStroke.opacity(0.9) }
        return DSColor.accentStroke.opacity(0.9)
    }
}

enum RecipeTagStyle {
    case standard
    case overImage
}

struct RecipeTagStrip: View {
    let tags: [String]
    var limit = 2
    var style: RecipeTagStyle = .standard

    var body: some View {
        if !visibleTags.isEmpty {
            HStack(spacing: 7) {
                ForEach(visibleTags, id: \.self) { tag in
                    RecipeTagView(tag: tag, style: style)
                }
            }
        }
    }

    private var visibleTags: [String] {
        var seen = Set<String>()
        let uniqueTags = tags.filter { tag in
            let normalized = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !normalized.isEmpty && seen.insert(normalized).inserted
        }
        return Array(uniqueTags.prefix(limit))
    }
}

private struct RecipeTagView: View {
    let tag: String
    let style: RecipeTagStyle

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbolName)
                .font(.system(size: 9, weight: .medium))

            tagLabel
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 9)
        .frame(height: 25)
        .background(background)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(border, lineWidth: 0.55)
        }
    }

    private var normalizedTag: String {
        tag.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: " ")
    }

    @ViewBuilder
    private var tagLabel: some View {
        if let minutes = minuteValue {
            Text("\(minutes) min")
        } else {
            Text(LocalizedStringKey(tag))
        }
    }

    private var minuteValue: Int? {
        guard normalizedTag.contains("min") || normalizedTag.contains("minute") else {
            return nil
        }
        return Int(normalizedTag.split(whereSeparator: { !$0.isNumber }).first ?? "")
    }

    private var symbolName: String {
        if normalizedTag.contains("min") || normalizedTag.contains("minute") {
            return "clock"
        }
        if normalizedTag == "easy" || normalizedTag.contains("simple") {
            return "fork.knife"
        }
        if normalizedTag.contains("protein") {
            return "bolt.fill"
        }
        if normalizedTag.contains("gluten") || normalizedTag.contains("grain") {
            return "leaf"
        }
        if normalizedTag.contains("vegan") || normalizedTag.contains("vegetarian") {
            return "leaf.fill"
        }
        if normalizedTag.contains("sugar") {
            return "cube.fill"
        }
        if normalizedTag.contains("keto") {
            return "drop.fill"
        }
        if normalizedTag.contains("calorie") || normalizedTag.contains("light") {
            return "flame"
        }
        return "sparkles"
    }

    private var foreground: Color {
        switch style {
        case .standard:
            DSColor.accent
        case .overImage:
            .white
        }
    }

    private var background: Color {
        switch style {
        case .standard:
            DSColor.accentSurface.opacity(0.22)
        case .overImage:
            .white.opacity(0.12)
        }
    }

    private var border: Color {
        switch style {
        case .standard:
            DSColor.accentStroke.opacity(0.12)
        case .overImage:
            .white.opacity(0.16)
        }
    }
}

struct DSSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(title))
                .font(DSTypography.title)
                .foregroundStyle(DSColor.textPrimary)
            Spacer(minLength: DSSpacing.md)
            if let subtitle {
                Text(LocalizedStringKey(subtitle))
                    .font(DSTypography.micro)
                    .foregroundStyle(DSColor.textTertiary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

struct EditorialSectionLabel: View {
    let eyebrow: String?
    let title: String
    var subtitle: String?

    init(_ title: String, eyebrow: String? = nil, subtitle: String? = nil) {
        self.title = title
        self.eyebrow = eyebrow
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let eyebrow {
                Text(LocalizedStringKey(eyebrow))
                    .font(DSTypography.micro)
                    .foregroundStyle(DSColor.accent)
                    .textCase(.uppercase)
            }

            Text(LocalizedStringKey(title))
                .font(DSTypography.largeTitle)
                .foregroundStyle(DSColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(LocalizedStringKey(subtitle))
                    .font(DSTypography.body)
                    .foregroundStyle(DSColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EditorialGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    interactive ? .regular.tint(DSColor.card.opacity(0.14)).interactive() : .regular.tint(DSColor.card.opacity(0.14)),
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 0.75)
                }
        }
    }
}

struct EditorialFoodArtView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x333A1B), DSColor.background, Color(hex: 0x221614)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height

                Circle()
                    .fill(Color.white.opacity(0.94))
                    .frame(width: width * 0.58, height: width * 0.58)
                    .position(x: width * 0.55, y: height * 0.48)
                    .shadow(color: .black.opacity(0.38), radius: 32, x: 0, y: 22)

                Circle()
                    .fill(DSColor.foodBase)
                    .frame(width: width * 0.39, height: width * 0.39)
                    .position(x: width * 0.53, y: height * 0.48)

                Ellipse()
                    .fill(DSColor.foodGreens)
                    .frame(width: width * 0.2, height: height * 0.12)
                    .rotationEffect(.degrees(-18))
                    .position(x: width * 0.42, y: height * 0.43)

                Ellipse()
                    .fill(DSColor.foodProtein)
                    .frame(width: width * 0.22, height: height * 0.13)
                    .rotationEffect(.degrees(16))
                    .position(x: width * 0.58, y: height * 0.42)

                Ellipse()
                    .fill(DSColor.foodAccent)
                    .frame(width: width * 0.18, height: height * 0.1)
                    .rotationEffect(.degrees(-10))
                    .position(x: width * 0.49, y: height * 0.56)

                Circle()
                    .fill(DSColor.accent)
                    .frame(width: 12, height: 12)
                    .position(x: width * 0.66, y: height * 0.53)
            }

            LinearGradient(
                colors: [.black.opacity(0.28), .clear, .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct EditorialAsyncImage: View {
    let url: URL?
    var cornerRadius: CGFloat = 28

    var body: some View {
        RecipeImageView(url: url)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
    }
}

struct DSMetricCard: View {
    let title: String
    let value: String
    var isFeatured = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(title))
                .font(DSTypography.micro)
                .foregroundStyle(isFeatured ? DSColor.accent : DSColor.textSecondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(value)
                .font(isFeatured ? DSTypography.title : DSTypography.headline)
                .foregroundStyle(DSColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 2)
    }
}

struct PremiumEmptyStateView: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: DSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(DSColor.accentSurface)
                    .frame(width: 96, height: 96)

                Image(systemName: systemImage)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(DSColor.accent)
            }

            VStack(spacing: DSSpacing.xs) {
                Text(LocalizedStringKey(title))
                    .font(DSTypography.headline)
                    .foregroundStyle(DSColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(LocalizedStringKey(subtitle))
                    .font(DSTypography.body)
                    .foregroundStyle(DSColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DSSpacing.lg)
        .padding(.vertical, 34)
    }
}

struct RecipeSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(DSColor.elevatedCard)
                .frame(height: 220)
                .shimmering()

            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(DSColor.elevatedCard)
                    .frame(width: 210, height: 18)
                    .shimmering()
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(DSColor.elevatedCard)
                    .frame(width: 148, height: 14)
                    .shimmering()
                HStack(spacing: DSSpacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(DSColor.elevatedCard)
                            .frame(height: 44)
                            .shimmering()
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .dsCard(cornerRadius: 28)
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.8

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.16), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .rotationEffect(.degrees(18))
                    .offset(x: proxy.size.width * phase)
                }
                .clipShape(Rectangle())
                .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                    phase = 1.1
                }
            }
    }
}

struct DSSegmentedControl<Option: Hashable>: View {
    let options: [(Option, String)]
    @Binding var selection: Option

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.0) { option, title in
                Button {
                    withAnimation(DSMotion.snappy) {
                        selection = option
                    }
                } label: {
                    Text(LocalizedStringKey(title))
                        .font(option == selection ? DSTypography.body : DSTypography.caption)
                        .foregroundStyle(option == selection ? DSColor.accent : DSColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(option == selection ? DSColor.accentSurface.opacity(0.72) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            if option == selection {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(DSColor.accent.opacity(0.28), lineWidth: 0.75)
                            }
                        }
                        .contentTransition(.opacity)
                        .animation(DSMotion.snappy, value: option == selection)
                }
                .dsPressable(scale: 0.96)
            }
        }
        .padding(6)
        .frame(height: 48)
        .background(DSColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension View {
    func dsCard(cornerRadius: CGFloat = 26, showsBorder: Bool = true, showsShadow: Bool = true) -> some View {
        modifier(DSCardModifier(cornerRadius: cornerRadius, showsBorder: showsBorder, showsShadow: showsShadow))
    }

    func dsFieldBackground(isFocused: Bool = false) -> some View {
        modifier(DSFieldBackground(isFocused: isFocused))
    }

    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }

    func editorialGlass(cornerRadius: CGFloat = 24, interactive: Bool = false) -> some View {
        modifier(EditorialGlassModifier(cornerRadius: cornerRadius, interactive: interactive))
    }
}
