import SwiftUI
import SwiftData

@main
struct PumpKitchenApp: App {
    private let container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootTabView(container: container)
                .modelContainer(container.modelContainer)
        }
    }
}

