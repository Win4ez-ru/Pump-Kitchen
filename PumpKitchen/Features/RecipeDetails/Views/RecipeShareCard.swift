import SwiftUI
import UIKit

/// A fixed-size, light-themed recipe card rendered to an image for sharing.
/// Colors are hardcoded so the exported card looks the same regardless of
/// the in-app theme.
struct RecipeShareCardView: View {
    let recipe: Recipe
    let nutrition: NutritionInfo
    let heroImage: UIImage?

    private let cardWidth: CGFloat = 360
    private let cardHeight: CGFloat = 480

    private let paper = Color(hex: 0xF7F8FA)
    private let ink = Color(hex: 0x15171A)
    private let inkMuted = Color(hex: 0x5F6670)
    private let accent = Color(hex: 0x6F8FB4)
    private let accentSurface = Color(hex: 0xE7EEF7)

    var body: some View {
        VStack(spacing: 0) {
            heroSection

            VStack(alignment: .leading, spacing: 12) {
                Text(verbatim: "PUMP KITCHEN")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2.2)
                    .foregroundStyle(accent)

                Text(recipe.title)
                    .font(.system(size: 26, weight: .medium, design: .serif))
                    .foregroundStyle(ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .fixedSize(horizontal: false, vertical: true)

                if !visibleTags.isEmpty {
                    HStack(spacing: 7) {
                        ForEach(visibleTags, id: \.self) { tag in
                            Text(LocalizedStringKey(tag))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 10)
                                .frame(height: 24)
                                .background(accentSurface)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 0) {
                    metric(value: "\(nutrition.calories)", label: "kcal")
                    metricDivider
                    metric(value: "\(Int(nutrition.protein))g", label: "Protein")
                    metricDivider
                    metric(value: "\(Int(nutrition.fats))g", label: "Fat")
                    metricDivider
                    metric(value: "\(Int(nutrition.carbs))g", label: "Carbs")
                    if recipe.cookingTimeMinutes > 0 {
                        metricDivider
                        metric(value: "\(recipe.cookingTimeMinutes)", label: "min")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: 0xDDE3EA).opacity(0.8), lineWidth: 0.75)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let heroImage {
                    Image(uiImage: heroImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [accentSurface, accent.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "fork.knife")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(accent)
                    }
                }
            }
            .frame(width: cardWidth, height: 264)
            .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.62),
                    .init(color: paper.opacity(0.35), location: 0.86),
                    .init(color: paper, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(width: cardWidth, height: 264)
    }

    private var visibleTags: [String] {
        var seen = Set<String>()
        let uniqueTags = recipe.tags.filter { tag in
            let normalized = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !normalized.isEmpty && seen.insert(normalized).inserted
        }
        return Array(uniqueTags.prefix(2))
    }

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(ink)
            Text(LocalizedStringKey(label))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(inkMuted)
        }
        .frame(maxWidth: .infinity)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(Color(hex: 0xDDE3EA))
            .frame(width: 1, height: 26)
    }
}

@MainActor
enum RecipeShareCardRenderer {
    /// Fetches the recipe image first (ImageRenderer cannot wait for
    /// AsyncImage), then renders the share card at 3x scale.
    static func render(recipe: Recipe, nutrition: NutritionInfo, locale: Locale) async -> UIImage? {
        var heroImage: UIImage?
        if let imageURL = recipe.imageURL,
           let (data, _) = try? await URLSession.shared.data(from: imageURL) {
            heroImage = UIImage(data: data)
        }

        let card = RecipeShareCardView(recipe: recipe, nutrition: nutrition, heroImage: heroImage)
            .environment(\.locale, locale)
            .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage
    }
}

struct ShareCardPayload: Identifiable {
    let id = UUID()
    let image: UIImage
    let title: String
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
