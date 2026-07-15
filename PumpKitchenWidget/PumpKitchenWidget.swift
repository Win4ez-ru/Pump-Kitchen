import SwiftUI
import UIKit
import WidgetKit

@main
struct PumpKitchenWidgetBundle: WidgetBundle {
    var body: some Widget {
        RecipeOfDayWidget()
        QuickSearchWidget()
    }
}

// MARK: - Shared data
// The JSON shape must stay in sync with FeaturedRecipeSnapshotStore
// in the app target.

struct FeaturedRecipeSnapshot: Codable {
    let title: String
    let tags: [String]
    let calories: Int
    let cookingTimeMinutes: Int
    let imageURL: URL?
}

enum WidgetSharedStore {
    static let appGroupID = "group.com.pumpkitchen.PumpKitchen"
    private static let snapshotKey = "widget.featuredRecipeSnapshot"

    static func loadSnapshot() -> FeaturedRecipeSnapshot? {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: snapshotKey)
        else { return nil }
        return try? JSONDecoder().decode(FeaturedRecipeSnapshot.self, from: data)
    }

    /// Mirrors the app's built-in featured recipe so the widget has content
    /// before the app is launched for the first time.
    static var fallbackSnapshot: FeaturedRecipeSnapshot {
        FeaturedRecipeSnapshot(
            title: "Chicken Teriyaki Bowl",
            tags: ["High Protein"],
            calories: 520,
            cookingTimeMinutes: 24,
            imageURL: URL(string: "https://images.unsplash.com/photo-1547592180-85f173990554?w=800")
        )
    }
}

// MARK: - Palette (mirrors the app design system)

enum WidgetPalette {
    static let background = Color(light: 0xF7F8FA, dark: 0x101114)
    static let accent = Color(light: 0x6F8FB4, dark: 0x9BB7D5)
    static let accentSurface = Color(light: 0xE7EEF7, dark: 0x202A36)
    static let textPrimary = Color(light: 0x15171A, dark: 0xF8FAFC)
    static let textSecondary = Color(light: 0x5F6670, dark: 0xAEB5BF)
}

private extension Color {
    init(light: UInt, dark: UInt) {
        self.init(
            uiColor: UIColor { traits in
                let hex = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(
                    red: CGFloat((hex >> 16) & 0xFF) / 255,
                    green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255,
                    alpha: 1
                )
            }
        )
    }
}

enum WidgetCopy {
    static var isRussian: Bool {
        Locale.current.language.languageCode?.identifier == "ru"
    }

    static var recipeOfDayEyebrow: String {
        isRussian ? "РЕЦЕПТ ДНЯ" : "RECIPE OF THE DAY"
    }

    static var quickSearchTitle: String {
        isRussian ? "Что приготовить?" : "What can I cook?"
    }

    static var quickSearchSubtitle: String {
        isRussian ? "Поиск по ингредиентам" : "Search by ingredients"
    }

    static var minutesSuffix: String {
        isRussian ? "мин" : "min"
    }

    static var kcalSuffix: String {
        isRussian ? "ккал" : "kcal"
    }
}

// MARK: - Recipe of the Day widget

struct RecipeOfDayEntry: TimelineEntry {
    let date: Date
    let snapshot: FeaturedRecipeSnapshot
    let image: UIImage?
}

struct RecipeOfDayProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecipeOfDayEntry {
        RecipeOfDayEntry(date: .now, snapshot: WidgetSharedStore.fallbackSnapshot, image: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (RecipeOfDayEntry) -> Void) {
        Task {
            completion(await makeEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecipeOfDayEntry>) -> Void) {
        Task {
            let entry = await makeEntry()
            // The recipe of the day changes once per day, so ask for a
            // refresh right after the next midnight.
            let nextMidnight = Calendar.current.startOfDay(
                for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
            )
            completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
        }
    }

    private func makeEntry() async -> RecipeOfDayEntry {
        let snapshot = WidgetSharedStore.loadSnapshot() ?? WidgetSharedStore.fallbackSnapshot
        let image = await fetchImage(from: snapshot.imageURL)
        return RecipeOfDayEntry(date: .now, snapshot: snapshot, image: image)
    }

    private func fetchImage(from url: URL?) async -> UIImage? {
        guard
            let url,
            let (data, _) = try? await URLSession.shared.data(from: url),
            let image = UIImage(data: data)
        else { return nil }
        return image.downscaled(maxDimension: 700)
    }
}

private extension UIImage {
    /// Widgets have a tight memory budget, so large photos are downscaled
    /// before they reach the timeline entry.
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else { return self }

        let scaleFactor = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

struct RecipeOfDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RecipeOfDayWidget", provider: RecipeOfDayProvider()) { entry in
            RecipeOfDayWidgetView(entry: entry)
                .widgetURL(URL(string: "pumpkitchen://home"))
        }
        .configurationDisplayName(WidgetCopy.isRussian ? "Рецепт дня" : "Recipe of the Day")
        .description(
            WidgetCopy.isRussian
                ? "Новая идея для готовки каждый день."
                : "A fresh cooking idea every day."
        )
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RecipeOfDayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RecipeOfDayEntry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumLayout
        default:
            smallLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 5) {
            Spacer(minLength: 0)

            Text(WidgetCopy.recipeOfDayEyebrow)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(entry.image == nil ? WidgetPalette.accent : .white.opacity(0.85))

            Text(entry.snapshot.title)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundStyle(entry.image == nil ? WidgetPalette.textPrimary : .white)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            metadataRow
                .foregroundStyle(entry.image == nil ? WidgetPalette.textSecondary : .white.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            if let image = entry.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.32),
                                .init(color: .black.opacity(0.68), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } else {
                WidgetPalette.background
            }
        }
    }

    private var mediumLayout: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                Text(WidgetCopy.recipeOfDayEyebrow)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(WidgetPalette.accent)

                Text(entry.snapshot.title)
                    .font(.system(size: 19, weight: .medium, design: .serif))
                    .foregroundStyle(WidgetPalette.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                metadataRow
                    .foregroundStyle(WidgetPalette.textSecondary)

                if let tag = entry.snapshot.tags.first {
                    Text(tag)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetPalette.accent)
                        .padding(.horizontal, 9)
                        .frame(height: 22)
                        .background(WidgetPalette.accentSurface)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if let image = entry.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        WidgetPalette.accentSurface
                        Image(systemName: "fork.knife")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(WidgetPalette.accent)
                    }
                }
            }
            .frame(width: 108, height: 108)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .containerBackground(for: .widget) {
            WidgetPalette.background
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 4) {
            if entry.snapshot.calories > 0 {
                Text("\(entry.snapshot.calories) \(WidgetCopy.kcalSuffix)")
            }
            if entry.snapshot.calories > 0, entry.snapshot.cookingTimeMinutes > 0 {
                Text(verbatim: "•")
            }
            if entry.snapshot.cookingTimeMinutes > 0 {
                Text("\(entry.snapshot.cookingTimeMinutes) \(WidgetCopy.minutesSuffix)")
            }
        }
        .font(.system(size: 10, weight: .medium, design: .rounded))
        .lineLimit(1)
    }
}

// MARK: - Quick search widget

struct QuickSearchEntry: TimelineEntry {
    let date: Date
}

struct QuickSearchProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickSearchEntry {
        QuickSearchEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickSearchEntry) -> Void) {
        completion(QuickSearchEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickSearchEntry>) -> Void) {
        completion(Timeline(entries: [QuickSearchEntry(date: .now)], policy: .never))
    }
}

struct QuickSearchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QuickSearchWidget", provider: QuickSearchProvider()) { _ in
            QuickSearchWidgetView()
                .widgetURL(URL(string: "pumpkitchen://search"))
        }
        .configurationDisplayName(WidgetCopy.isRussian ? "Быстрый поиск" : "Quick Search")
        .description(
            WidgetCopy.isRussian
                ? "Сразу к поиску рецептов по ингредиентам."
                : "Jump straight into ingredient search."
        )
        .supportedFamilies([.systemSmall])
    }
}

struct QuickSearchWidgetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(WidgetPalette.accent)
                .frame(width: 34, height: 34)
                .background(WidgetPalette.accentSurface)
                .clipShape(Circle())

            Spacer(minLength: 0)

            Text(WidgetCopy.quickSearchTitle)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(WidgetPalette.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Text(WidgetCopy.quickSearchSubtitle)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(WidgetPalette.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            WidgetPalette.background
        }
    }
}
