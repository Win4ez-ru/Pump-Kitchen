import SwiftUI

struct RecipeDetailsView: View {
    @StateObject private var viewModel: RecipeDetailsViewModel
    @State private var substitutionIngredient: Ingredient?

    init(recipe: Recipe, container: AppContainer) {
        _viewModel = StateObject(
            wrappedValue: RecipeDetailsViewModel(
                recipe: recipe,
                favoritesRepository: container.favoritesRepository
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                RecipeImageView(url: viewModel.recipe.imageURL)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                hero
                favoriteButton
                scalingSection
                nutritionGrid
                ingredientsSection
                instructionsSection
                if !viewModel.recipe.tips.isEmpty { tipsSection }
            }
            .padding(DSSpacing.lg)
        }
        .appBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.toggleFavorite() }
                } label: {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.isFavorite ? DSColor.yuzu : DSColor.matcha)
                        .font(.headline)
                }
            }
        }
        .sheet(item: $substitutionIngredient) { ingredient in
            IngredientSubstitutionSheet(ingredient: ingredient)
                .presentationDetents([.medium])
        }
        .task {
            await viewModel.load()
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text(viewModel.recipe.title)
                        .font(DSTypography.largeTitle)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: DSSpacing.sm) {
                        Label("\(viewModel.recipe.cookingTimeMinutes) min", systemImage: "clock")
                        Label("\(viewModel.recipe.ingredients.count) items", systemImage: "leaf")
                        if let difficulty = viewModel.recipe.difficulty, !difficulty.isEmpty {
                            Label(difficulty.capitalized, systemImage: "chart.bar.fill")
                        }
                    }
                    .font(DSTypography.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(DSColor.matcha)
            }

            if let description = viewModel.recipe.description, !description.isEmpty {
                Text(description)
                    .font(DSTypography.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !viewModel.recipe.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DSSpacing.sm) {
                        ForEach(viewModel.recipe.tags, id: \.self) { tag in
                            Text(tag)
                                .font(DSTypography.caption)
                                .foregroundStyle(DSColor.matcha)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(DSColor.matcha.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(22)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }


    private var favoriteButton: some View {
        PrimaryButton(
            viewModel.isFavorite ? "Saved to Favorites" : "Add to Favorites",
            systemImage: viewModel.isFavorite ? "heart.fill" : "heart"
        ) {
            Task { await viewModel.toggleFavorite() }
        }
    }

    private var scalingSection: some View {
        section(title: "Scale from what you have", icon: "scalemass.fill") {
            if viewModel.scalableIngredients.isEmpty {
                Text("Add ingredient amounts like chicken 200g on Home to preview recipe scaling here.")
                    .font(DSTypography.body)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    Picker("Fixed ingredient", selection: $viewModel.selectedScalingIngredientID) {
                        ForEach(viewModel.scalableIngredients) { ingredient in
                            Text(ingredient.name).tag(Optional(ingredient.id))
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("How much do you have? e.g. 250g", text: $viewModel.fixedAmountText)
                        .font(DSTypography.body)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.background.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    Text(viewModel.scalingHint)
                        .font(DSTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var nutritionGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DSSpacing.md) {
            nutritionItem("Calories", "\(viewModel.displayedNutrition.calories)", "flame.fill", DSColor.yuzu)
            nutritionItem("Protein", "\(Int(viewModel.displayedNutrition.protein))g", "bolt.fill", DSColor.matcha)
            nutritionItem("Fats", "\(Int(viewModel.displayedNutrition.fats))g", "drop.fill", DSColor.yuzu)
            nutritionItem("Carbs", "\(Int(viewModel.displayedNutrition.carbs))g", "circle.hexagongrid.fill", DSColor.matcha)
        }
    }

    private var ingredientsSection: some View {
        section(title: "Ingredients", icon: "basket.fill") {
            VStack(spacing: DSSpacing.sm) {
                ForEach(viewModel.recipe.ingredients) { ingredient in
                    HStack(alignment: .firstTextBaseline) {
                        Text(ingredient.name)
                            .font(DSTypography.body)
                        Spacer(minLength: DSSpacing.md)
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(viewModel.displayedAmount(for: ingredient))
                                .font(DSTypography.caption)
                                .foregroundStyle(.secondary)
                            Button {
                                substitutionIngredient = ingredient
                            } label: {
                                Label("Substitute", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.caption2.weight(.semibold))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(DSColor.matcha)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private var instructionsSection: some View {
        section(title: "Instructions", icon: "list.number") {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                ForEach(Array(viewModel.recipe.instructions.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: DSSpacing.md) {
                        Text("\(index + 1)")
                            .font(DSTypography.caption)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(DSColor.matcha)
                            .clipShape(Circle())

                        Text(step)
                            .font(DSTypography.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var tipsSection: some View {
        section(title: "Tips & Lifehacks", icon: "lightbulb.fill") {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                ForEach(viewModel.recipe.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: DSSpacing.sm) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(DSColor.yuzu)
                        Text(tip)
                            .font(DSTypography.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func nutritionItem(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(value)
                .font(DSTypography.title)
            Text(title)
                .font(DSTypography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DSSpacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func section<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Label(title, systemImage: icon)
                .font(DSTypography.headline)
                .foregroundStyle(.primary)

            content()
        }
        .padding(DSSpacing.md)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct IngredientSubstitutionSheet: View {
    let ingredient: Ingredient

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(ingredient.name)
                        .font(DSTypography.title)
                    Text("Possible substitutes")
                        .font(DSTypography.body)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: DSSpacing.md) {
                    ForEach(IngredientSubstitutionProvider.substitutions(for: ingredient.name), id: \.self) { substitution in
                        HStack(spacing: DSSpacing.md) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(DSColor.matcha)
                                .frame(width: 30, height: 30)
                                .background(DSColor.matcha.opacity(0.12))
                                .clipShape(Circle())

                            Text(substitution)
                                .font(DSTypography.body)
                            Spacer()
                        }
                        .padding(DSSpacing.md)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }

                Text("Backend can later provide context-aware swaps based on the full recipe and macros.")
                    .font(DSTypography.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(DSSpacing.lg)
            .appBackground()
            .navigationTitle("Substitutes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
