import SwiftUI

struct RootTabView: View {
    let container: AppContainer
    @State private var showsOnboarding = false

    var body: some View {
        TabView {
            HomeView(container: container)
                .tabItem {
                    Label("Home", systemImage: "sparkles")
                }

            FavoritesView(container: container)
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }

            HistoryView(container: container)
                .tabItem {
                    Label("History", systemImage: "clock")
                }

            SettingsView(container: container)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(DSColor.matcha)
        .task {
            showsOnboarding = !container.settingsStore.hasCompletedOnboarding
        }
        .fullScreenCover(isPresented: $showsOnboarding) {
            OnboardingView(
                initialGoal: container.settingsStore.defaultGoal,
                initialHeightCentimeters: container.settingsStore.heightCentimeters,
                initialWeightKilograms: container.settingsStore.weightKilograms,
                initialActivityLevel: container.settingsStore.activityLevel
            ) { goal, height, weight, activity in
                container.settingsStore.defaultGoal = goal
                container.settingsStore.heightCentimeters = height
                container.settingsStore.weightKilograms = weight
                container.settingsStore.activityLevel = activity
                container.settingsStore.hasCompletedOnboarding = true
                showsOnboarding = false
            }
        }
    }
}
