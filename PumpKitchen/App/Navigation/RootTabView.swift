import SwiftUI

struct RootTabView: View {
    let container: AppContainer
    @State private var showsOnboarding = false
    @State private var selectedTab: RootTab = .home
    @State private var tabMovesForward = true
    @State private var hidesTabBar = false
    @ObservedObject private var authSession: AuthSession
    @ObservedObject private var settingsStore: UserDefaultsAppSettingsStore

    init(container: AppContainer) {
        self.container = container
        self.authSession = container.authSession
        self.settingsStore = container.settingsStore
    }

    var body: some View {
        Group {
            if authSession.isAuthenticated || authSession.useMockGeneration {
                tabs
                    .transition(.dsPanel)
            } else {
                AuthView(session: authSession, settingsStore: settingsStore)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .accessibilityHidden(authSession.needsProfileSetup)
        .onOpenURL { url in
            guard AppDeepLink.isAppLink(url) else { return }
            select(.home)
            if AppDeepLink.isQuickSearch(url) {
                NotificationCenter.default.post(name: .quickSearchRequested, object: nil)
            }
        }
        .environment(\.locale, settingsStore.appLanguage.locale)
        .preferredColorScheme(settingsStore.appTheme.colorScheme)
        .animation(DSMotion.gentle, value: authSession.isAuthenticated)
        .animation(DSMotion.gentle, value: authSession.useMockGeneration)
        .fullScreenCover(isPresented: profileSetupBinding) {
            ProfileSetupView(
                initialName: container.settingsStore.userName,
                initialDiet: container.settingsStore.dietaryPreference,
                initialAllergens: container.settingsStore.allergens
            ) { draft in
                await completeRegistrationProfileSetup(draft)
            } onSkip: {
                skipRegistrationProfileSetup()
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }

    private var tabs: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(container: container)
                case .favorites:
                    FavoritesView(container: container)
                case .history:
                    HistoryView(container: container)
                case .profile:
                    SettingsView(container: container)
                }
            }
            .id(selectedTab)
            .transition(tabTransition)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 116)
            }

            if !hidesTabBar {
                FloatingRootTabBar(selection: selectedTab) { tab in
                    select(tab)
                }
                .frame(maxWidth: 248)
                .padding(.bottom, -4)
                .zIndex(100)
                .transition(.scale(scale: 0.94, anchor: .bottom).combined(with: .opacity))
            }
        }
        .accessibilityHidden(showsOnboarding)
        .onPreferenceChange(RootTabBarVisibilityPreferenceKey.self) { hidesTabBar = $0 }
        .animation(DSMotion.quick, value: hidesTabBar)
        .task {
            refreshOnboardingPresentation()
        }
        .onChange(of: authSession.needsProfileSetup) {
            refreshOnboardingPresentation()
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
                withAnimation(DSMotion.gentle) {
                    showsOnboarding = false
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }

    private var profileSetupBinding: Binding<Bool> {
        Binding(
            get: { authSession.needsProfileSetup },
            set: { isPresented in
                if !isPresented {
                    authSession.completeProfileSetup()
                }
            }
        )
    }

    private func completeRegistrationProfileSetup(_ draft: RegistrationProfileDraft) async {
        container.settingsStore.userName = draft.name
        container.settingsStore.dietaryPreference = draft.diet
        container.settingsStore.allergens = draft.allergens

        if authSession.isAuthenticated && !authSession.useMockGeneration {
            try? await container.profileService.updateProfile(
                goal: container.settingsStore.defaultGoal,
                diet: draft.diet,
                name: draft.name,
                allergens: draft.allergens
            )
        }

        authSession.completeProfileSetup()
        refreshOnboardingPresentation()
    }

    private func skipRegistrationProfileSetup() {
        authSession.completeProfileSetup()
        refreshOnboardingPresentation()
    }

    private func refreshOnboardingPresentation() {
        showsOnboarding = !container.settingsStore.hasCompletedOnboarding && !authSession.needsProfileSetup
    }

    private var tabTransition: AnyTransition {
        return .asymmetric(
            insertion: .offset(x: tabMovesForward ? 36 : -36)
                .combined(with: .opacity),
            removal: .offset(x: tabMovesForward ? -22 : 22)
                .combined(with: .opacity)
        )
    }

    private func select(_ tab: RootTab) {
        guard tab != selectedTab else { return }
        let movesForward = tab.order > selectedTab.order
        withAnimation(DSMotion.page) {
            tabMovesForward = movesForward
            selectedTab = tab
        }
    }
}

struct RootTabBarVisibilityPreferenceKey: PreferenceKey {
    static var defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

private enum RootTab: String, CaseIterable, Identifiable {
    case home
    case favorites
    case history
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .favorites: "Favorites"
        case .history: "History"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "magnifyingglass"
        case .favorites: "heart"
        case .history: "clock"
        case .profile: "person.crop.circle"
        }
    }

    var order: Int {
        switch self {
        case .home: 0
        case .favorites: 1
        case .history: 2
        case .profile: 3
        }
    }
}

private struct FloatingRootTabBar: View {
    let selection: RootTab
    let onSelect: (RootTab) -> Void
    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 6) {
            ForEach(RootTab.allCases) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    ZStack {
                        Image(systemName: tab.systemImage)
                            .font(.system(
                                size: selection == tab ? 20 : 18,
                                weight: selection == tab ? .semibold : .medium
                            ))
                            .symbolEffect(.bounce, value: selection == tab)
                    }
                    .foregroundStyle(selection == tab ? DSColor.accent.opacity(0.9) : DSColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Rectangle())
                    .background {
                        if selection == tab {
                            Capsule()
                                .fill(DSColor.accentSurface.opacity(0.44))
                                .overlay {
                                    Capsule()
                                        .stroke(DSColor.accentStroke.opacity(0.22), lineWidth: 0.65)
                                }
                                .matchedGeometryEffect(id: "selected-tab", in: selectionNamespace)
                        }
                    }
                }
                .buttonStyle(DSScaleButtonStyle(scale: 0.94))
                .contentShape(Rectangle())
                .accessibilityLabel(LocalizedStringKey(tab.title))
                .accessibilityIdentifier("tab.\(tab.rawValue)")
            }
        }
        .padding(6)
        .editorialGlass(cornerRadius: 32)
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}
