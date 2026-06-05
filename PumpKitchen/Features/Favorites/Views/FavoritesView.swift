import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel: FavoritesViewModel
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
            Group {
                if viewModel.recipes.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: DSSpacing.lg) {
                            Text("Favorites")
                                .font(DSTypography.largeTitle)
                            placeholder
                        }
                        .padding(DSSpacing.lg)
                    }
                } else {
                    List {
                        Section {
                            ForEach(viewModel.recipes) { recipe in
                                NavigationLink(value: AppRoute.recipeDetails(recipe)) {
                                    RecipeCardView(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: DSSpacing.lg, bottom: 8, trailing: DSSpacing.lg))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.remove(recipe: recipe) }
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text("Favorites")
                                .font(DSTypography.largeTitle)
                                .foregroundStyle(.primary)
                                .textCase(nil)
                                .padding(.top, DSSpacing.md)
                        }
                    }
                    .listStyle(.plain)
                }
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
                await viewModel.loadFavorites()
            }
        }
    }

    private var placeholder: some View {
        VStack(spacing: DSSpacing.md) {
            Image(systemName: "heart")
                .font(.largeTitle)
                .foregroundStyle(DSColor.yuzu)
            Text("No favorites yet")
                .font(DSTypography.headline)
            Text("Save recipes from the details screen and they will stay here for quick access.")
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
