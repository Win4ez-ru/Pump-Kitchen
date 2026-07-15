import Foundation
import WidgetKit

/// Snapshot of the featured "Recipe of the Day" shared with the home screen
/// widget through the app group. The JSON shape must stay in sync with the
/// copy of this type in the PumpKitchenWidget target.
struct FeaturedRecipeSnapshot: Codable {
    let title: String
    let tags: [String]
    let calories: Int
    let cookingTimeMinutes: Int
    let imageURL: URL?
}

enum FeaturedRecipeSnapshotStore {
    static let appGroupID = "group.com.pumpkitchen.PumpKitchen"
    static let widgetKind = "RecipeOfDayWidget"
    private static let snapshotKey = "widget.featuredRecipeSnapshot"

    static func save(_ snapshot: FeaturedRecipeSnapshot) {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = try? JSONEncoder().encode(snapshot)
        else { return }

        guard defaults.data(forKey: snapshotKey) != data else { return }
        defaults.set(data, forKey: snapshotKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
