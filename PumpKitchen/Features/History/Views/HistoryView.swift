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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("History")
                            .font(.system(size: 32, weight: .medium, design: .serif))
                            .foregroundStyle(DSColor.textPrimary)

                        Text("Recent searches, ready to replay.")
                            .font(DSTypography.body)
                            .foregroundStyle(DSColor.textSecondary)
                    }
                    .dsAppear(delay: 0.02, distance: 14)

                    if uniqueQueries.isEmpty {
                        historyEmptyState
                            .dsAppear(delay: 0.1, distance: 18)
                    } else {
                        ForEach(Array(historySections.enumerated()), id: \.element.id) { sectionIndex, section in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizedStringKey(section.title))
                                    .font(.system(size: 18, weight: .medium, design: .serif))
                                    .foregroundStyle(DSColor.textPrimary)

                                ForEach(Array(section.queries.enumerated()), id: \.element.id) { index, query in
                                    historyRow(query)
                                        .dsAppear(delay: Double(sectionIndex + index) * 0.035)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 30)
                .padding(.bottom, 132)
                .animation(DSMotion.list, value: viewModel.queries.map(\.id))
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
                await viewModel.loadHistory()
            }
        }
    }

    private var uniqueQueries: [RecipeQuery] {
        var seen = Set<String>()

        return viewModel.queries.filter { query in
            let signature = query.ingredients
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
                .sorted()
                .joined(separator: "|")

            return seen.insert(signature).inserted
        }
    }

    private var historySections: [HistorySection] {
        let grouped = Dictionary(grouping: uniqueQueries, by: historySectionTitle)
        let order = ["Today", "Yesterday", "This Week", "Earlier"]
        return order.compactMap { title in
            guard let queries = grouped[title], !queries.isEmpty else { return nil }
            return HistorySection(title: title, queries: queries)
        }
    }

    private var historyEmptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "clock")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(DSColor.accent)

            Text("No searches yet")
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundStyle(DSColor.textPrimary)

            Text("Search with ingredients from Home and your past ideas will appear here.")
                .font(DSTypography.body)
                .foregroundStyle(DSColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 36)
    }

    private func historySectionTitle(for query: RecipeQuery) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(query.createdAt) { return "Today" }
        if calendar.isDateInYesterday(query.createdAt) { return "Yesterday" }
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now), query.createdAt >= weekAgo {
            return "This Week"
        }
        return "Earlier"
    }

    private func historyRow(_ query: RecipeQuery) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: AppRoute.repeatQuery(query)) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: historyImageURL(for: query)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            FittedRecipeImage(url: nil)
                        }
                    }
                    .frame(height: 210)
                    .frame(maxWidth: .infinity)
                    .clipped()

	                    LinearGradient(
	                        colors: [.clear, .black.opacity(0.78)],
	                        startPoint: .top,
	                        endPoint: .bottom
	                    )

	                    Rectangle()
	                        .fill(.ultraThinMaterial)
	                        .frame(height: 92)
	                        .blur(radius: 18)
	                        .opacity(0.42)
	                        .mask(
	                            LinearGradient(
	                                colors: [.clear, .black],
	                                startPoint: .top,
	                                endPoint: .bottom
	                            )
	                        )
	                        .frame(maxHeight: .infinity, alignment: .bottom)

	                    localizedIngredientList(query.ingredients)
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .padding(16)
                }
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
            .dsLiftable(scale: 0.985)

            Button {
                Task { await viewModel.delete(query: query) }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.46))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(10)
        }
    }

    private func localizedIngredientList(_ ingredients: [String]) -> Text {
        ingredients.enumerated().reduce(Text("")) { result, item in
            result
                + (item.offset == 0 ? Text("") : Text(", "))
                + Text(LocalizedStringKey(item.element))
        }
    }

    private func historyImageURL(for query: RecipeQuery) -> URL? {
        let images = [
            "https://images.unsplash.com/photo-1547592180-85f173990554?w=1200",
            "https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=1200",
            "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=1200"
        ]
        return URL(string: images[abs(query.id.hashValue) % images.count])
    }
}

private struct HistorySection: Identifiable {
    let title: String
    let queries: [RecipeQuery]

    var id: String { title }
}
