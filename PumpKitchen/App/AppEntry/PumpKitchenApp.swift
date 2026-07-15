
import SwiftUI
import SwiftData

@main
struct PumpKitchenApp: App {
    private let container: AppContainer

    init() {
        UITestConfiguration.applyIfNeeded()
        container = AppContainer.live()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(container: container)
                .modelContainer(container.modelContainer)
        }
    }
}

private enum UITestConfiguration {
    static func applyIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-ui-testing") else { return }

        if arguments.contains("-reset-user-defaults"),
           let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }

        if arguments.contains("-skip-onboarding") {
            UserDefaults.standard.set(true, forKey: "settings.hasCompletedOnboarding")
        }
    }
}
