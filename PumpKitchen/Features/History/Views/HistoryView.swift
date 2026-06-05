import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(
            wrappedValue: HistoryViewModel(
                historyRepository: container.historyRepository
            )
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.queries.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: DSSpacing.lg) {
                            Text("History")
                                .font(DSTypography.largeTitle)
                            placeholder
                        }
                        .padding(DSSpacing.lg)
                    }
                } else {
                    List {
                        Section {
                            ForEach(viewModel.queries) { query in
                                NavigationLink(value: AppRoute.repeatQuery(query)) {
                                    HistoryCardView(query: query)
                                }
                                .buttonStyle(.plain)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: DSSpacing.lg, bottom: 8, trailing: DSSpacing.lg))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.delete(query: query) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text("History")
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
                await viewModel.loadHistory()
            }
        }
    }

    private var placeholder: some View {
        VStack(spacing: DSSpacing.md) {
            Image(systemName: "clock")
                .font(.largeTitle)
                .foregroundStyle(DSColor.yuzu)
            Text("No searches yet")
                .font(DSTypography.headline)
            Text("Every generated request appears here so you can repeat it in one tap.")
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

private struct HistoryCardView: View {
    let query: RecipeQuery

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Text(query.fitnessGoal?.title ?? "Flexible")
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColor.matcha)
                Spacer()
                Text(DateFormatterProvider.historyDate.string(from: query.createdAt))
                    .font(DSTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Text(query.ingredients.joined(separator: ", "))
                .font(DSTypography.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text("Tap to repeat this ingredient set")
                .font(DSTypography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
