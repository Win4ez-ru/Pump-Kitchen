import SwiftUI

struct RootTabView: View {
    let container: AppContainer
    @State private var showsOnboarding = false
    @ObservedObject private var authSession: AuthSession

    init(container: AppContainer) {
        self.container = container
        self.authSession = container.authSession
    }

    var body: some View {
        Group {
            if authSession.isAuthenticated || authSession.useMockGeneration {
                tabs
            } else {
                AuthView(session: authSession)
            }
        }
    }

    private var tabs: some View {
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
                initialActivityLevel: container.settingsStore.activityLevel,
                initialDietaryPreference: container.settingsStore.dietaryPreference
            ) { goal, height, weight, activity, diet in
                container.settingsStore.defaultGoal = goal
                container.settingsStore.heightCentimeters = height
                container.settingsStore.weightKilograms = weight
                container.settingsStore.activityLevel = activity
                container.settingsStore.dietaryPreference = diet
                container.settingsStore.hasCompletedOnboarding = true
                showsOnboarding = false
            }
        }
    }
}
