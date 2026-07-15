import Foundation

/// Deep links delivered by the home screen widgets, e.g. pumpkitchen://search.
enum AppDeepLink {
    static let scheme = "pumpkitchen"

    static func isAppLink(_ url: URL) -> Bool {
        url.scheme?.lowercased() == scheme
    }

    static func isQuickSearch(_ url: URL) -> Bool {
        isAppLink(url) && url.host()?.lowercased() == "search"
    }
}

extension Notification.Name {
    static let quickSearchRequested = Notification.Name("pumpkitchen.quickSearchRequested")
}
