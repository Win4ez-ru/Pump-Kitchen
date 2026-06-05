import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
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
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    header
                    generatorPanel
                    content
                }
                .padding(DSSpacing.lg)
            }
            .appBackground()
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .recipeDetails(let recipe):
                    RecipeDetailsView(recipe: recipe, container: container)
                case .repeatQuery(let query):
                    HomeView(container: container, initialQuery: query)
                }
            }
            .task {
                await viewModel.loadFrequentIngredients()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Pump Kitchen")
                .font(DSTypography.largeTitle)
                .foregroundStyle(.primary)
            Text("Cook beautifully with what you already have.")
                .font(DSTypography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var generatorPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Ingredients")
                    .font(DSTypography.headline)

                HStack(spacing: DSSpacing.sm) {
                    TextField("Chicken 200g, rice, eggs", text: $viewModel.ingredientInput)
                        .font(DSTypography.body)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.background.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .onSubmit {
                            viewModel.addIngredient()
                        }

                    Button {
                        viewModel.addIngredient()
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(DSColor.matcha)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canAddIngredient)
                    .opacity(viewModel.canAddIngredient ? 1 : 0.45)
                }

                if viewModel.ingredients.isEmpty {
                    Text("Add ingredients one by one. Include amounts when you know them, like chicken 200g.")
                        .font(DSTypography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    IngredientChipCloud(
                        ingredients: viewModel.ingredients,
                        onRemove: viewModel.removeIngredient
                    )
                }

                QuickIngredientSection(
                    title: "Popular",
                    ingredients: viewModel.popularIngredients,
                    selectedIngredients: viewModel.ingredients,
                    onSelect: viewModel.addQuickIngredient
                )

                if !viewModel.frequentIngredients.isEmpty {
                    QuickIngredientSection(
                        title: "Frequently used",
                        ingredients: viewModel.frequentIngredients,
                        selectedIngredients: viewModel.ingredients,
                        onSelect: viewModel.addQuickIngredient
                    )
                }

                Text("Your goal lives in Profile. Add fixed ingredient amounts here and the backend can scale the rest.")
                    .font(DSTypography.caption)
                    .foregroundStyle(.secondary)

                PrimaryButton(
                    "Generate Recipes",
                    isLoading: viewModel.isLoading
                ) {
                    Task { await viewModel.generateRecipes() }
                }
                .disabled(!viewModel.canGenerate)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyStateView(
                title: "Ready for inspiration",
                subtitle: "Add ingredients or tap a popular option to generate personalized ideas."
            )
        case .loading:
            LoadingRecipesView()
        case .loaded(let recipes):
            VStack(spacing: DSSpacing.md) {
                ForEach(recipes) { recipe in
                    NavigationLink(value: AppRoute.recipeDetails(recipe)) {
                        RecipeCardView(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
        case .failed(let message):
            EmptyStateView(title: "Something went wrong", subtitle: message)
        }
    }
}

private struct IngredientChipCloud: View {
    let ingredients: [String]
    let onRemove: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: DSSpacing.sm)], alignment: .leading, spacing: DSSpacing.sm) {
            ForEach(ingredients, id: \.self) { ingredient in
                Button {
                    onRemove(ingredient)
                } label: {
                    HStack(spacing: DSSpacing.xs) {
                        Text(ingredient)
                            .lineLimit(1)
                        Image(systemName: "xmark")
                            .font(.caption2.weight(.bold))
                    }
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColor.graphite)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(DSColor.yuzu.opacity(0.2))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}


private struct QuickIngredientSection: View {
    let title: String
    let ingredients: [String]
    let selectedIngredients: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(title)
                .font(DSTypography.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DSSpacing.sm) {
                    ForEach(ingredients, id: \.self) { ingredient in
                        let isSelected = selectedIngredients.contains { $0.caseInsensitiveCompare(ingredient) == .orderedSame }

                        Button {
                            onSelect(ingredient)
                        } label: {
                            Text(ingredient)
                                .font(DSTypography.caption)
                                .foregroundStyle(isSelected ? .white : DSColor.matcha)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isSelected ? DSColor.matcha : DSColor.matcha.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(isSelected)
                    }
                }
            }
        }
    }
}

private struct LoadingRecipesView: View {
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            ProgressView()
                .tint(DSColor.matcha)
            Text("Balancing flavor and macros")
                .font(DSTypography.headline)
            Text("Pump Kitchen is building recipes around your ingredients.")
                .font(DSTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DSSpacing.xl)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct EmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            Image(systemName: "takeoutbag.and.cup.and.straw")
                .font(.largeTitle)
                .foregroundStyle(DSColor.yuzu)
            Text(title)
                .font(DSTypography.headline)
            Text(subtitle)
                .font(DSTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DSSpacing.xl)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
