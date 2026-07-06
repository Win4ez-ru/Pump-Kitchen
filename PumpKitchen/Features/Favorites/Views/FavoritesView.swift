import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel: FavoritesViewModel
    @State private var hasLoaded = false
    @State private var selectedFilter = "All"
    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(
            wrappedValue: FavoritesViewModel(
                favoritesRepository: container.favoritesRepository
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    favoritesHeader
                        .dsAppear(delay: 0.02, distance: 14)

                    favoriteFilters
                        .dsAppear(delay: 0.08, distance: 14)

                    if !hasLoaded {
                        RecipeSkeletonCard()
                    } else if viewModel.recipes.isEmpty {
                        favoritesEmptyState
                            .dsAppear(delay: 0.12, distance: 18)
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            ForEach(Array(viewModel.recipes.enumerated()), id: \.element.id) { index, recipe in
                                favoriteTile(recipe)
                                    .dsAppear(delay: Double(index) * 0.035)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 30)
                .padding(.bottom, 132)
            }
            .appBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .recipeDetails(let recipe):
                    RecipeDetailsView(recipe: recipe, container: container)
                case .repeatQuery(let query):
                    HomeView(container: container, initialQuery: query)
                }
            }
            .task {
                await viewModel.loadFavorites()
                withAnimation(DSMotion.gentle) {
                    hasLoaded = true
                }
            }
        }
    }

    private var favoritesHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(DSColor.accent)

                Text("Saved recipes")
                    .font(.system(size: 32, weight: .medium, design: .serif))
                    .foregroundStyle(DSColor.textPrimary)
            }

            if !hasLoaded || viewModel.recipes.isEmpty {
                Text(favoritesSummary)
                    .font(DSTypography.body)
                    .foregroundStyle(DSColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var favoritesSummary: String {
        if !hasLoaded { return String(localized: "Opening your collection...") }
        return String(localized: "Recipes you save will live here.")
    }

    private var favoriteFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(["All", "Protein", "Quick", "Breakfast", "Dinner"], id: \.self) { filter in
                    Button {
                        withAnimation(DSMotion.snappy) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(LocalizedStringKey(filter))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(selectedFilter == filter ? DSColor.accent : DSColor.textSecondary)
                            .padding(.horizontal, 13)
                            .frame(height: 32)
                            .background(selectedFilter == filter ? DSColor.accentSurface.opacity(0.42) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .dsPressable(scale: 0.94)
                }
            }
        }
    }

    private var favoritesEmptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "heart")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(DSColor.accent)

            Text("No favorites yet")
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundStyle(DSColor.textPrimary)

            Text("Save recipes from the details screen and they will stay here for quick access.")
                .font(DSTypography.body)
                .foregroundStyle(DSColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 36)
    }

    private func favoriteTile(_ recipe: Recipe) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: AppRoute.recipeDetails(recipe)) {
                GeometryReader { proxy in
                    let drift = min(max(proxy.frame(in: .global).minY * -0.024, -10), 10)

                    ZStack(alignment: .bottomLeading) {
                        RecipeImageView(url: recipe.imageURL)
                            .scaleEffect(1.055)
                            .offset(y: drift)

                        LinearGradient(
                            colors: [.clear, .black.opacity(0.1), .black.opacity(0.74)],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        VStack(alignment: .leading, spacing: 9) {
                            RecipeTagStrip(tags: recipe.tags, limit: 1, style: .overImage)

                            Text(LocalizedStringKey(recipe.title))
                                .font(.system(size: 18, weight: .medium, design: .serif))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                        }
                        .padding(13)
                    }
                }
                .aspectRatio(0.66, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .scrollTransition(.animated(.smooth(duration: 0.44))) { content, phase in
                    content
                        .scaleEffect(phase.isIdentity ? 1 : 0.975)
                        .opacity(phase.isIdentity ? 1 : 0.88)
                }
            }
            .buttonStyle(.plain)
            .dsLiftable(scale: 0.985)

            Button {
                Task { await viewModel.remove(recipe: recipe) }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(.black.opacity(0.45))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(8)
        }
    }
}
