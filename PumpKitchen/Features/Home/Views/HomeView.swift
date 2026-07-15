import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel: HomeViewModel
    @Namespace private var recipeHeroNamespace
    @FocusState private var isIngredientFieldFocused: Bool
    private let container: AppContainer

    init(container: AppContainer, initialQuery: RecipeQuery? = nil) {
        self.container = container
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                recipeGenerationService: container.recipeGenerationService,
                historyRepository: container.historyRepository,
                settingsStore: container.settingsStore,
                initialQuery: initialQuery
            )
        )
    }

    var body: some View {
        NavigationStack {
            GeometryReader { viewport in
                let contentWidth = min(viewport.size.width, 680)
                let heroHeight = responsiveHeroHeight(
                    viewportHeight: viewport.size.height,
                    topInset: viewport.safeAreaInsets.top
                )
                let composerOverlap = min(86, heroHeight * 0.13)

                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            if showsFeaturedRecipe {
                                featuredRecipe(height: heroHeight)
                                    .transition(
                                        .asymmetric(
                                            insertion: .opacity.combined(with: .offset(y: -18)),
                                            removal: .opacity
                                                .combined(with: .offset(y: -34))
                                                .combined(with: .scale(scale: 0.975, anchor: .top))
                                        )
                                    )
                            }

                            if searchPhase != 2 {
                                ingredientComposer(scrollProxy: scrollProxy)
                                    .padding(.horizontal, 18)
                                    .padding(.top, showsFeaturedRecipe ? -composerOverlap : max(viewport.safeAreaInsets.top + 8, 18))
                                    .id(HomeAnchor.composer)
                            }

                            if searchPhase == 2 {
                                Color.clear
                                    .frame(height: max(26, viewport.safeAreaInsets.top + 12))
                                    .id(HomeAnchor.resultsTitle)
                            }

                            searchContent(
                                viewportWidth: contentWidth,
                                scrollProxy: scrollProxy
                            )
                                .id(HomeAnchor.results)
                        }
                        .frame(maxWidth: contentWidth, alignment: .leading)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 156)
                        .animation(DSMotion.discovery, value: showsFeaturedRecipe)
                        .animation(DSMotion.discovery, value: searchPhase)
                    }
                    .ignoresSafeArea(edges: showsFeaturedRecipe ? .top : [])
                    .coordinateSpace(name: "homeScroll")
                    .appBackground()
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .recipeDetails(let recipe):
                            RecipeDetailsView(recipe: recipe, container: container)
                                .navigationTransition(.zoom(sourceID: recipe.id, in: recipeHeroNamespace))
                        case .repeatQuery(let query):
                            HomeView(container: container, initialQuery: query)
                        }
                    }
                    .task {
                        publishFeaturedRecipeSnapshot()
                        await viewModel.loadFrequentIngredients()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .quickSearchRequested)) { _ in
                        Task {
                            try? await Task.sleep(for: .milliseconds(350))
                            isIngredientFieldFocused = true
                        }
                    }
                    .onChange(of: searchPhase) { _, phase in
                        guard phase == 2 else { return }
                        Task {
                            await Task.yield()
                            scrollProxy.scrollTo(HomeAnchor.resultsTitle, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    private func responsiveHeroHeight(viewportHeight: CGFloat, topInset: CGFloat) -> CGFloat {
        let base = viewportHeight * 0.72 + topInset
        return min(max(base, 500 + topInset), 700 + topInset)
    }

    private func featuredRecipe(height: CGFloat) -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("homeScroll")).minY
            let pull = max(minY, 0)
            let parallax = reduceMotion ? 0 : (minY < 0 ? -minY * 0.18 : -pull * 0.18)

            ZStack(alignment: .bottomLeading) {
                NavigationLink(value: AppRoute.recipeDetails(featuredRecipeModel)) {
                        RecipeImageView(url: featuredRecipeModel.imageURL)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .offset(y: parallax)
                            .scaleEffect(reduceMotion ? 1 : 1 + pull / 1100)
	                        .mask(
	                            LinearGradient(
	                                stops: [
	                                    .init(color: .black, location: 0),
	                                    .init(color: .black, location: 0.66),
	                                    .init(color: .black.opacity(0.58), location: 0.84),
	                                    .init(color: .clear, location: 1)
	                                ],
	                                startPoint: .top,
	                                endPoint: .bottom
	                            )
	                        )
	                        .matchedTransitionSource(id: featuredRecipeModel.id, in: recipeHeroNamespace)
                }
                .buttonStyle(DSLiftButtonStyle(scale: 0.992))
                .accessibilityIdentifier("home.featuredRecipe")

                LinearGradient(
	                    stops: [
	                        .init(color: .clear, location: 0.5),
	                        .init(color: DSColor.background.opacity(0.04), location: 0.68),
	                        .init(color: DSColor.background.opacity(0.26), location: 0.82),
	                        .init(color: DSColor.background.opacity(0.76), location: 0.94),
	                        .init(color: DSColor.background, location: 1)
	                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Recipe of the Day")
                        .font(DSTypography.micro)
                        .foregroundStyle(DSColor.accent)
                        .textCase(.uppercase)

                    Text(LocalizedStringKey(featuredRecipeModel.title))
                        .font(.system(size: 31, weight: .medium, design: .serif))
                        .foregroundStyle(DSColor.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    RecipeTagStrip(tags: featuredRecipeTags, limit: 2)
                }
	                .padding(.horizontal, 20)
	                .padding(.bottom, 128)
                .allowsHitTesting(false)
                .offset(y: minY < 0 ? -minY * 0.05 : 0)
            }
        }
        .frame(height: height)
        .clipped()
        .contentShape(Rectangle())
    }

    private func ingredientComposer(scrollProxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TextField(
                    text: $viewModel.ingredientInput,
                    prompt: Text("What do you have at home?")
                        .foregroundStyle(DSColor.textSecondary.opacity(0.95))
                ) {
                    Text("What do you have at home?")
                }
                    .font(DSTypography.body)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .foregroundStyle(DSColor.textPrimary)
                    .tint(DSColor.accent)
                    .focused($isIngredientFieldFocused)
                    .onSubmit(viewModel.addIngredient)
                    .accessibilityIdentifier("home.ingredientInput")

                if viewModel.canAddIngredient {
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        withAnimation(DSMotion.snappy) {
                            viewModel.addIngredient()
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(DSColor.onAccent)
                            .frame(width: 32, height: 32)
                            .background(DSColor.accent)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.addIngredientButton")
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.leading, 15)
            .padding(.trailing, 4)
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(isIngredientFieldFocused ? 0.28 : 0.12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isIngredientFieldFocused ? DSColor.accent.opacity(0.58) : DSColor.border.opacity(0.42))
                    .frame(height: isIngredientFieldFocused ? 1.2 : 0.7)
                    .padding(.horizontal, 12)
            }
            .scaleEffect(isIngredientFieldFocused ? 1.006 : 1)
            .animation(DSMotion.focus, value: isIngredientFieldFocused)

            if searchPhase != 2 {
                QuickIngredientStrip(
                    ingredients: viewModel.popularIngredients,
                    selectedIngredients: viewModel.ingredients,
                    onToggle: viewModel.toggleQuickIngredient
                )
            }

            if !customIngredients.isEmpty {
                IngredientChipStrip(
                    ingredients: customIngredients,
                    onRemove: { ingredient in
                        withAnimation(DSMotion.list) {
                            viewModel.removeIngredient(ingredient)
                        }
                    }
                )
                .transition(.opacity.combined(with: .offset(y: -8)))
            }

            if (viewModel.canGenerate || viewModel.isLoading) && searchPhase != 2 {
                SearchTextAction(isLoading: viewModel.isLoading) {
                    generateRecipes(scrollProxy: scrollProxy)
                }
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 5)),
                        removal: .opacity.combined(with: .offset(y: 5))
                    )
                )
            }
        }
        .animation(DSMotion.list, value: viewModel.ingredients)
        .animation(DSMotion.snappy, value: viewModel.canAddIngredient)
        .animation(DSMotion.snappy, value: viewModel.canGenerate)
        .animation(DSMotion.discovery, value: showsFeaturedRecipe)
        .sensoryFeedback(.selection, trigger: viewModel.ingredients)
    }

    private var customIngredients: [String] {
        viewModel.ingredients.filter { selected in
            !viewModel.popularIngredients.contains {
                $0.caseInsensitiveCompare(selected) == .orderedSame
            }
        }
    }

    private func generateRecipes(scrollProxy: ScrollViewProxy) {
        Task {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            isIngredientFieldFocused = false
            await viewModel.generateRecipes()
            guard case .loaded = viewModel.state else {
                return
            }

            try? await Task.sleep(for: .milliseconds(260))
            withAnimation(DSMotion.gentle) {
                scrollProxy.scrollTo(HomeAnchor.composer, anchor: .top)
            }
            await Task.yield()
            scrollProxy.scrollTo(HomeAnchor.resultsTitle, anchor: .top)
        }
    }

    @ViewBuilder
    private func searchContent(
        viewportWidth: CGFloat,
        scrollProxy: ScrollViewProxy
    ) -> some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .loading:
            IntelligentSearchLoadingView()
            .padding(.horizontal, 18)
            .transition(.opacity.combined(with: .offset(y: 24)))
        case .loaded(let recipes):
            HStack(spacing: 0) {
                Spacer(minLength: 18)

                SearchResultsView(
                    recipes: recipes,
                    availableWidth: max(viewportWidth - 36, 0),
                    namespace: recipeHeroNamespace
                )

                Spacer(minLength: 18)
            }
            .frame(width: viewportWidth)
            .transition(.opacity.combined(with: .offset(y: 38)))
        case .failed(let message):
            PremiumEmptyStateView(
                systemImage: "exclamationmark.triangle",
                title: "Something went wrong",
                subtitle: message
            )
            .padding(.horizontal, 18)
        }
    }

    private var showsFeaturedRecipe: Bool {
        if case .idle = viewModel.state {
            return true
        }
        return false
    }

    private var searchPhase: Int {
        switch viewModel.state {
        case .idle: 0
        case .loading: 1
        case .loaded: 2
        case .failed: 3
        }
    }

    private var featuredRecipeModel: Recipe {
        Recipe(
            title: "Chicken Teriyaki Bowl",
            description: "Glossy chicken, rice and fresh greens built for a strong training day.",
            imageURL: URL(string: "https://images.unsplash.com/photo-1547592180-85f173990554?w=1200"),
            cookingTimeMinutes: 24,
            difficulty: "easy",
            ingredients: [
                Ingredient(name: "Chicken", amount: "200g"),
                Ingredient(name: "Rice", amount: "90g"),
                Ingredient(name: "Cucumber", amount: "80g")
            ],
            instructions: ["Cook the rice.", "Sear the chicken.", "Glaze and assemble the bowl."],
            nutrition: NutritionInfo(calories: 520, protein: 48, fats: 14, carbs: 56),
            tags: ["High Protein"]
        )
    }

    private func publishFeaturedRecipeSnapshot() {
        FeaturedRecipeSnapshotStore.save(
            FeaturedRecipeSnapshot(
                title: featuredRecipeModel.title,
                tags: featuredRecipeTags,
                calories: featuredRecipeModel.nutrition.calories,
                cookingTimeMinutes: featuredRecipeModel.cookingTimeMinutes,
                imageURL: featuredRecipeModel.imageURL
            )
        )
    }

    private var featuredRecipeTags: [String] {
        var tags = Array(featuredRecipeModel.tags.prefix(1))
        tags.append("\(featuredRecipeModel.cookingTimeMinutes) min")

        if tags.count < 2, let difficulty = featuredRecipeModel.difficulty?.capitalized {
            tags.append(difficulty)
        }

        return Array(tags.prefix(2))
    }
}

private struct SearchTextAction: View {
    let isLoading: Bool
    let action: () -> Void
    @State private var isPrimed = false

    var body: some View {
        Button {
            withAnimation(DSMotion.quick) {
                isPrimed = true
            }
            action()
            Task {
                try? await Task.sleep(for: .milliseconds(220))
                await MainActor.run {
                    withAnimation(DSMotion.smooth) {
                        isPrimed = false
                    }
                }
            }
        } label: {
            HStack(spacing: 11) {
                if isLoading {
                    Image(systemName: "sparkles")
                        .foregroundStyle(DSColor.accent)
                        .symbolEffect(.pulse, options: .repeating, value: isLoading)
                } else {
                    Image(systemName: "sparkles")
                        .foregroundStyle(DSColor.accent)
                }

                Text("What can I cook?")
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(DSColor.textPrimary)
                    .tracking(0)
                    .scaleEffect(isPrimed ? 1.035 : 1, anchor: .leading)

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DSColor.accent)
                    .offset(x: isPrimed ? 8 : 0)
                    .opacity(isPrimed ? 0.68 : 1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(DSScaleButtonStyle(scale: 0.972))
        .disabled(isLoading)
        .accessibilityIdentifier("home.generateButton")
        .frame(maxWidth: .infinity, alignment: .leading)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isLoading)
    }
}

private enum HomeAnchor: Hashable {
    case composer
    case results
    case resultsTitle
}

private struct SearchResultsView: View {
    let recipes: [Recipe]
    let availableWidth: CGFloat
    let namespace: Namespace.ID

    private var cardWidth: CGFloat {
        max((availableWidth - 12) / 2, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recipes")
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundStyle(DSColor.textPrimary)

            if let first = recipes.first {
                resultLink(first, width: availableWidth, imageHeight: 290, index: 0)
            }

            HStack(alignment: .top, spacing: 12) {
                ForEach(Array(recipes.dropFirst().prefix(2).enumerated()), id: \.element.id) { offset, recipe in
                    resultLink(
                        recipe,
                        width: cardWidth,
                        imageHeight: offset == 0 ? 205 : 245,
                        index: offset + 1
                    )
                }
            }

            ForEach(Array(recipes.dropFirst(3).enumerated()), id: \.element.id) { offset, recipe in
                resultLink(
                    recipe,
                    width: availableWidth,
                    imageHeight: 270,
                    index: offset + 3
                )
            }
        }
        .frame(width: availableWidth, alignment: .leading)
    }

    private func resultLink(
        _ recipe: Recipe,
        width: CGFloat,
        imageHeight: CGFloat,
        index: Int
    ) -> some View {
        NavigationLink(value: AppRoute.recipeDetails(recipe)) {
            SearchResultCard(
                recipe: recipe,
                imageHeight: imageHeight,
                cardWidth: width
            )
            .matchedTransitionSource(id: recipe.id, in: namespace)
        }
        .buttonStyle(DSLiftButtonStyle(scale: 0.988))
        .accessibilityIdentifier(index == 0 ? "home.recipeResult.first" : "home.recipeResult.\(index)")
        .dsAppear(delay: Double(index) * 0.065, distance: 32)
        .scrollTransition(.animated(.smooth(duration: 0.4))) { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1 : 0.985)
                .opacity(phase.isIdentity ? 1 : 0.82)
        }
        .id(recipe.id)
        .padding(.top, index == 0 ? 18 : 0)
    }
}

private struct SearchResultCard: View {
    let recipe: Recipe
    let imageHeight: CGFloat
    let cardWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            RecipeImageView(url: recipe.imageURL)
                .frame(width: cardWidth, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)

            Text(LocalizedStringKey(recipe.title))
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(DSColor.textPrimary)
                .lineLimit(2)

	            RecipeTagStrip(
	                tags: recipe.tags,
	                limit: cardWidth < 220 ? 1 : 2
	            )

            if recipe.nutrition.calories > 0 {
                HStack(spacing: 8) {
                    Text("\(recipe.nutrition.calories) kcal")
                }
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(DSColor.textSecondary)
            }
        }
        .frame(width: cardWidth, alignment: .leading)
    }
}

private struct IngredientChipStrip: View {
    let ingredients: [String]
    let onRemove: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ingredients, id: \.self) { ingredient in
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        onRemove(ingredient)
                    } label: {
                        HStack(spacing: 7) {
                            Text(ingredient)
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .font(DSTypography.caption)
                        .foregroundStyle(DSColor.textPrimary)
                        .padding(.horizontal, 13)
                        .frame(height: 34)
                        .background(DSColor.elevatedCard)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .dsPressable(scale: 0.94)
                }
            }
        }
    }
}

private struct QuickIngredientStrip: View {
    let ingredients: [String]
    let selectedIngredients: [String]
    let onToggle: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ingredients, id: \.self) { ingredient in
                    let isSelected = selectedIngredients.contains {
                        $0.caseInsensitiveCompare(ingredient) == .orderedSame
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        withAnimation(DSMotion.snappy) {
                            onToggle(ingredient)
                        }
                    } label: {
                        Text(LocalizedStringKey(ingredient))
                            .font(DSTypography.caption)
                            .foregroundStyle(isSelected ? DSColor.accent : DSColor.textPrimary)
                            .padding(.horizontal, 13)
                            .frame(height: 34)
                            .background(isSelected ? DSColor.accentSurface : DSColor.elevatedCard)
                            .clipShape(Capsule())
                            .overlay {
                                if isSelected {
                                    Capsule()
                                        .stroke(DSColor.accent.opacity(0.35), lineWidth: 0.75)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .dsPressable(scale: 0.94)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel(LocalizedStringKey(ingredient))
                    .accessibilityIdentifier("home.quickIngredient.\(ingredient)")
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedIngredients)
    }
}

private struct IntelligentSearchLoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var messageIndex = 0

    private let messages: [(String, String)] = [
        ("brain.head.profile", "Selecting the best recipes..."),
        ("leaf", "Finding ingredient matches..."),
        ("chart.bar.xaxis", "Calculating nutrition..."),
        ("fork.knife", "Updating cooking steps...")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 11) {
                Image(systemName: messages[messageIndex].0)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DSColor.accent)
                    .frame(width: 28, height: 28)
                    .symbolEffect(.bounce, value: messageIndex)

                Text(LocalizedStringKey(messages[messageIndex].1))
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundStyle(DSColor.textPrimary)
                    .contentTransition(.numericText())
            }
            .padding(.top, 30)

            VStack(spacing: 14) {
                RecipeSkeletonCard()
                    .dsAppear(delay: 0.02, distance: 24)
                RecipeSkeletonCard()
                    .scaleEffect(0.94, anchor: .top)
                    .opacity(0.72)
                    .dsAppear(delay: 0.1, distance: 28)
            }
        }
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(620))
                withAnimation(DSMotion.snappy) {
                    messageIndex = (messageIndex + 1) % messages.count
                }
            }
        }
    }
}
