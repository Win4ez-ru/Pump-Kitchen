import SwiftUI
import UIKit

struct RecipeDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel: RecipeDetailsViewModel
    @State private var substitutionIngredient: Ingredient?
    @State private var hasPresentedContent = false
    @State private var sharePayload: ShareCardPayload?
    @State private var isPreparingShareCard = false

    init(recipe: Recipe, container: AppContainer) {
        _viewModel = StateObject(
            wrappedValue: RecipeDetailsViewModel(
                recipe: recipe,
                favoritesRepository: container.favoritesRepository,
                recipeDetailsService: container.recipeDetailsService
            )
        )
    }

    var body: some View {
        GeometryReader { viewport in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroImage(topInset: viewport.safeAreaInsets.top)

                    VStack(alignment: .leading, spacing: 28) {
                        if viewModel.isLoadingDetails {
                            detailsLoadingRow
                                .stagedDetailsAppearance(isPresented: hasPresentedContent, index: 1)
                        }
                        nutritionSummary
                            .stagedDetailsAppearance(isPresented: hasPresentedContent, index: 2)
                        ingredientsSection
                            .stagedDetailsAppearance(isPresented: hasPresentedContent, index: 3)
                        instructionsSection
                            .stagedDetailsAppearance(isPresented: hasPresentedContent, index: 4)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, DSSpacing.xl)
                }
            }
            .ignoresSafeArea(edges: .top)
            .scrollDismissesKeyboard(.interactively)
            .coordinateSpace(name: "recipeScroll")
            .appBackground()
        }
        .safeAreaInset(edge: .bottom) {
            ingredientRemovalUndoBanner
        }
        .preference(key: RootTabBarVisibilityPreferenceKey.self, value: true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(items: [payload.image, payload.title])
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $substitutionIngredient) { ingredient in
            IngredientSubstitutionSheet(ingredient: ingredient) { substitution in
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                withAnimation(DSMotion.snappy) {
                    viewModel.replaceIngredient(ingredient, with: substitution)
                    substitutionIngredient = nil
                }
            }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .task {
            withAnimation(DSMotion.gentle.delay(0.08)) {
                hasPresentedContent = true
            }
            await viewModel.load()
        }
    }

    private func heroImage(topInset: CGFloat) -> some View {
        let heroHeight = 570 + topInset

        return GeometryReader { proxy in
            let minY = proxy.frame(in: .global).minY
            let stretch = max(minY, 0)
            let collapse = min(max(-minY / 340, 0), 1)

            ZStack(alignment: .bottomLeading) {
                // The image lives in an overlay so scroll-linked stretching
                // never inflates the hero's layout frame.
                Color.clear
                    .overlay(alignment: .top) {
                        FittedRecipeImage(url: viewModel.recipe.imageURL)
                            .frame(width: proxy.size.width, height: heroHeight + stretch)
                            .clipped()
                            .offset(y: reduceMotion ? -stretch : -stretch + (minY < 0 ? -minY * 0.14 : 0))
                            .opacity(1 - collapse * 0.3)
                    }

                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.04), location: 0),
                        .init(color: .clear, location: 0.3),
                        .init(color: DSColor.background.opacity(0.06), location: 0.56),
                        .init(color: DSColor.background.opacity(0.55), location: 0.82),
                        .init(color: DSColor.background, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                HStack(spacing: 10) {
                    topIconButton("chevron.left") {
                        dismiss()
                    }
                    .accessibilityIdentifier("recipeDetails.backButton")

                    Spacer()

                    topIconButton(isPreparingShareCard ? "ellipsis" : "square.and.arrow.up") {
                        shareRecipe()
                    }
                    .accessibilityIdentifier("recipeDetails.shareButton")
                    .accessibilityLabel("Share Recipe")
                    .contentTransition(.symbolEffect(.replace))

                    topIconButton(
                        viewModel.isFavorite ? "heart.fill" : "heart",
                        foreground: viewModel.isFavorite ? DSColor.accent : DSColor.textPrimary
                    ) {
                        Task { await viewModel.toggleFavorite() }
                    }
                    .accessibilityIdentifier("recipeDetails.favoriteButton")
                    .symbolEffect(.bounce, value: viewModel.isFavorite)
                    .contentTransition(.symbolEffect(.replace))
                    .sensoryFeedback(.success, trigger: viewModel.isFavorite)
                }
                .padding(.horizontal, 18)
                .padding(.top, topInset + 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .opacity(hasPresentedContent ? 1 : 0)
                .offset(y: hasPresentedContent ? 0 : -10)
                .animation(DSMotion.gentle.delay(0.06), value: hasPresentedContent)

                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedStringKey(viewModel.recipe.title))
                        .font(.system(size: 32, weight: .medium, design: .serif))
                        .foregroundStyle(DSColor.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: DSSpacing.sm) {
                        detailPill(Text("\(viewModel.recipe.cookingTimeMinutes) min"))
                        detailPill(viewModel.recipe.difficulty?.capitalized.nonEmpty ?? "Flexible")
                    }

                    if !viewModel.recipe.tags.isEmpty {
                        RecipeTagStrip(tags: viewModel.recipe.tags, limit: 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
                .opacity(hasPresentedContent ? 1 : 0)
                .offset(y: hasPresentedContent ? 0 : 18)
                .animation(DSMotion.hero.delay(0.14), value: hasPresentedContent)
            }
        }
        .frame(height: heroHeight)
        .opacity(hasPresentedContent ? 1 : 0.92)
        .animation(DSMotion.hero, value: hasPresentedContent)
    }

    private var nutritionSummary: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                compactMetric(Text("\(viewModel.displayedNutrition.calories) kcal"))
                separator
                compactMetric(Text("\(Int(viewModel.displayedNutrition.protein))g"), label: "Protein")
                separator
                compactMetric(Text("\(Int(viewModel.displayedNutrition.fats))g"), label: "Fat")
                separator
                compactMetric(Text("\(Int(viewModel.displayedNutrition.carbs))g"), label: "Carbs")
                separator
                compactMetric(Text("\(viewModel.recipe.cookingTimeMinutes) min"))
            }
            .font(DSTypography.caption)
            .foregroundStyle(DSColor.textTertiary)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    compactMetric(Text("\(viewModel.displayedNutrition.calories) kcal"))
                    separator
                    compactMetric(Text("\(Int(viewModel.displayedNutrition.protein))g"), label: "Protein")
                }
                HStack(spacing: 10) {
                    compactMetric(Text("\(Int(viewModel.displayedNutrition.fats))g"), label: "Fat")
                    separator
                    compactMetric(Text("\(Int(viewModel.displayedNutrition.carbs))g"), label: "Carbs")
                    separator
                    compactMetric(Text("\(viewModel.recipe.cookingTimeMinutes) min"))
                }
            }
            .font(DSTypography.caption)
            .foregroundStyle(DSColor.textTertiary)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DSColor.border.opacity(0.34))
                .frame(height: 1)
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                sectionTitle("Ingredients")

                Text("Change one amount and the whole recipe follows.")
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if viewModel.recipe.ingredients.isEmpty {
                detailPlaceholder("Ingredients will appear when recipe details load.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recipe.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                        ingredientRow(for: ingredient)
                        .padding(.vertical, 14)
                        .frame(minHeight: 68)
                        .overlay(alignment: .bottom) {
                            if index != viewModel.recipe.ingredients.count - 1 {
                                Rectangle()
                                    .fill(DSColor.border.opacity(0.55))
                                    .frame(height: 1)
                            }
                        }
                        .transition(.dsCard)
                        .dsAppear(delay: Double(index) * 0.035, distance: 12)
                    }
                }
            }
        }
    }

    private func ingredientRow(for ingredient: Ingredient) -> some View {
        let displayName = IngredientTranslator.displayName(for: ingredient.name, locale: locale)

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                ingredientName(displayName)
                quantityEditor(for: ingredient, displayName: displayName)
                ingredientActions(for: ingredient, displayName: displayName)
            }

            VStack(alignment: .leading, spacing: 10) {
                ingredientName(displayName)
                HStack(spacing: 10) {
                    quantityEditor(for: ingredient, displayName: displayName)
                    Spacer(minLength: 8)
                    ingredientActions(for: ingredient, displayName: displayName)
                }
            }
        }
    }

    private func ingredientName(_ displayName: String) -> some View {
        Text(displayName)
            .font(DSTypography.body.weight(.medium))
            .foregroundStyle(DSColor.textPrimary)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ingredientActions(for ingredient: Ingredient, displayName: String) -> some View {
        HStack(spacing: 8) {
            ingredientAction(
                "Replace",
                accessibilityName: displayName,
                systemImage: "arrow.triangle.2.circlepath",
                color: DSColor.accent
            ) {
                withAnimation(DSMotion.gentle) {
                    substitutionIngredient = ingredient
                }
            }

            ingredientAction(
                "Delete",
                accessibilityName: displayName,
                systemImage: "trash",
                color: DSColor.destructive
            ) {
                withAnimation(DSMotion.snappy) {
                    viewModel.removeIngredient(ingredient)
                }
            }
        }
    }

    @ViewBuilder
    private var ingredientRemovalUndoBanner: some View {
        if let ingredientName = viewModel.removedIngredientName {
            HStack(spacing: 12) {
                Text("\(IngredientTranslator.displayName(for: ingredientName, locale: locale)) removed")
                    .font(DSTypography.caption.weight(.medium))
                    .foregroundStyle(DSColor.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Undo") {
                    withAnimation(DSMotion.snappy) {
                        viewModel.undoLastIngredientRemoval()
                    }
                }
                .font(DSTypography.caption.weight(.semibold))
                .foregroundStyle(DSColor.accent)
                .buttonStyle(.plain)

                Button {
                    withAnimation(DSMotion.snappy) {
                        viewModel.dismissIngredientRemovalUndo()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DSColor.textSecondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(DSColor.border.opacity(0.45), lineWidth: 1)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Cooking Steps")

            if viewModel.recipe.instructions.isEmpty {
                detailPlaceholder("Cooking steps will appear when recipe details load.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recipe.instructions.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 8) {
                                Text(String(format: "%02d", index + 1))
                                    .font(.system(size: 21, weight: .regular, design: .serif))
                                    .foregroundStyle(DSColor.accent)
                                    .frame(width: 44, alignment: .leading)

                                if index != viewModel.recipe.instructions.count - 1 {
                                    Rectangle()
                                        .fill(DSColor.border.opacity(0.38))
                                        .frame(width: 1)
                                        .frame(maxHeight: .infinity)
                                }
                            }

                            if let stepURL = RecipeStepLink.url(from: step) {
                                originalRecipeLink(stepURL)
                                    .padding(.top, 6)
                            } else {
                                Text(LocalizedStringKey(step))
                                    .font(.system(size: 17, weight: .regular, design: .serif))
                                    .foregroundStyle(DSColor.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 6)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                        .padding(.vertical, 14)
                        .dsAppear(delay: Double(index) * 0.035, distance: 12)
                    }
                }
            }
        }
    }

    private func shareRecipe() {
        guard !isPreparingShareCard else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        isPreparingShareCard = true

        Task {
            let image = await RecipeShareCardRenderer.render(
                recipe: viewModel.recipe,
                nutrition: viewModel.displayedNutrition,
                locale: locale
            )
            isPreparingShareCard = false
            if let image {
                sharePayload = ShareCardPayload(image: image, title: viewModel.recipe.title)
            }
        }
    }

    private func originalRecipeLink(_ url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 9) {
                Image(systemName: "safari")
                    .font(.system(size: 15, weight: .medium))

                Text("Open Original Recipe")
                    .font(DSTypography.callout)
                    .lineLimit(1)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(DSColor.accent)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(DSColor.accentSurface.opacity(0.72))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(DSColor.accentStroke.opacity(0.35), lineWidth: 0.75)
            }
            .contentShape(Capsule())
        }
        .dsPressable(scale: 0.96)
        .accessibilityLabel("Open Original Recipe")
    }

    private var detailsLoadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(DSColor.accent)
            Text("Loading recipe details...")
                .font(DSTypography.caption)
                .foregroundStyle(DSColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func detailPlaceholder(_ text: String) -> some View {
        Text(LocalizedStringKey(text))
            .font(DSTypography.caption)
            .foregroundStyle(DSColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
    }

    private func detailPill(_ title: String, isPrimary: Bool = false) -> some View {
        detailPill(Text(LocalizedStringKey(title)), isPrimary: isPrimary)
    }

    private func detailPill(_ text: Text, isPrimary: Bool = false) -> some View {
        text
            .font(DSTypography.micro)
            .foregroundStyle(isPrimary ? DSColor.accent : DSColor.textSecondary)
            .padding(.horizontal, 14)
            .frame(height: 30)
            .background(isPrimary ? DSColor.accentSurface.opacity(0.72) : DSColor.elevatedCard.opacity(0.7))
            .clipShape(Capsule())
    }

    private func compactMetric(_ value: Text, label: String? = nil) -> some View {
        HStack(spacing: 4) {
            value
                .foregroundStyle(DSColor.textPrimary)
                .contentTransition(.numericText())

            if let label {
                Text(LocalizedStringKey(label))
                    .foregroundStyle(DSColor.textTertiary)
            }
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }

    private var separator: some View {
        Circle()
            .fill(DSColor.textTertiary.opacity(0.55))
            .frame(width: 3, height: 3)
            .accessibilityHidden(true)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(LocalizedStringKey(title))
            .font(.system(size: 21, weight: .medium, design: .serif))
            .foregroundStyle(DSColor.textPrimary)
    }

    private func topIconButton(
        _ systemImage: String,
        foreground: Color = DSColor.textPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(foreground)
                .frame(width: 42, height: 42)
                .editorialGlass(cornerRadius: 21, interactive: true)
        }
        .dsPressable(scale: 0.92)
    }

    private func quantityEditor(for ingredient: Ingredient, displayName: String) -> some View {
        IngredientQuantityField(
            ingredientName: displayName,
            amount: viewModel.amountText(for: ingredient)
        ) { amount in
            viewModel.updateAmount(amount, for: ingredient)
        }
    }

    private func ingredientAction(
        _ title: String,
        accessibilityName: String,
        systemImage: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 46, height: 46)
                .background(color.opacity(0.08))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .dsPressable(scale: 0.9)
        .accessibilityLabel(Text("\(String(localized: String.LocalizationValue(title))) \(accessibilityName)"))
    }
}

private struct StagedDetailsAppearance: ViewModifier {
    let isPresented: Bool
    let index: Int

    func body(content: Content) -> some View {
        content
            .opacity(isPresented ? 1 : 0)
            .offset(y: isPresented ? 0 : CGFloat(18 + index * 4))
            .animation(DSMotion.gentle.delay(Double(index) * 0.11), value: isPresented)
    }
}

private extension View {
    func stagedDetailsAppearance(isPresented: Bool, index: Int) -> some View {
        modifier(StagedDetailsAppearance(isPresented: isPresented, index: index))
    }
}

private struct IngredientQuantityField: View {
    let ingredientName: String
    let amount: String
    let onChange: (String) -> Void

    @State private var isSettingGrams = false
    @State private var gramDraft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if isNumericAmount {
                numericAmountField
            } else if isSettingGrams {
                gramSetupField
            } else {
                nonNumericAmountLabel
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Amount for \(ingredientName)"))
    }

    private var numericAmountField: some View {
        HStack(spacing: 5) {
            TextField("0", text: numericBinding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(DSColor.textPrimary)
                .tint(DSColor.accent)
                .focused($isFocused)
                .frame(minWidth: 34, maxWidth: 64)

            if !unit.isEmpty {
                Text(LocalizedStringKey(unit))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(DSColor.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 11)
        .frame(minWidth: 104, minHeight: 48)
        .background(isFocused ? DSColor.accentSurface.opacity(0.46) : DSColor.card.opacity(0.32))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(isFocused ? DSColor.accent.opacity(0.62) : DSColor.border.opacity(0.34), lineWidth: 1)
        }
        .shadow(color: DSColor.accent.opacity(isFocused ? 0.18 : 0), radius: 12, x: 0, y: 6)
        .scaleEffect(isFocused ? 1.018 : 1)
        .animation(DSMotion.snappy, value: isFocused)
    }

    private var gramSetupField: some View {
        HStack(spacing: 5) {
            TextField("0", text: gramDraftBinding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(DSColor.textPrimary)
                .tint(DSColor.accent)
                .focused($isFocused)
                .frame(minWidth: 34, maxWidth: 64)

            Text("g")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(DSColor.textSecondary)
        }
        .padding(.horizontal, 11)
        .frame(minWidth: 104, minHeight: 48)
        .background(DSColor.accentSurface.opacity(0.46))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(DSColor.accent.opacity(0.62), lineWidth: 1)
        }
        .shadow(color: DSColor.accent.opacity(0.18), radius: 12, x: 0, y: 6)
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused && gramDraft.isEmpty {
                isSettingGrams = false
            }
        }
    }

    private var nonNumericAmountLabel: some View {
        HStack(spacing: 8) {
            Text(LocalizedStringKey(nonNumericAmountText))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(DSColor.textSecondary)
                .lineLimit(1)

            Button("Set grams") {
                gramDraft = ""
                isSettingGrams = true
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(DSColor.accent)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 48)
        .background(DSColor.card.opacity(0.32))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(DSColor.border.opacity(0.3), lineWidth: 1)
        }
    }

    private var isNumericAmount: Bool {
        amountParts != nil
    }

    private var numericBinding: Binding<String> {
        Binding(
            get: { numericValue },
            set: { onChange($0 + unit) }
        )
    }

    private var gramDraftBinding: Binding<String> {
        Binding(
            get: { gramDraft },
            set: { value in
                let sanitizedValue = value.filter { character in
                    character.isNumber || character == "." || character == ","
                }
                gramDraft = sanitizedValue
                if !sanitizedValue.isEmpty {
                    onChange("\(sanitizedValue)g")
                }
            }
        )
    }

    private var numericValue: String {
        let prefix = amount.prefix { character in
            character.isNumber || character == "." || character == ","
        }
        return String(prefix)
    }

    private var unit: String {
        let numericCount = numericValue.count
        return String(amount.dropFirst(numericCount))
    }

    private var nonNumericAmountText: String {
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedAmount.isEmpty ? "to taste" : trimmedAmount
    }

    private var amountParts: (number: Double, suffix: String)? {
        let pattern = #"^\s*([0-9]+(?:[\.,][0-9]+)?)(.*)$"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(amount.startIndex..., in: amount)
        guard let match = expression.firstMatch(in: amount, range: range) else {
            return nil
        }

        guard
            let numberRange = Range(match.range(at: 1), in: amount),
            let suffixRange = Range(match.range(at: 2), in: amount)
        else {
            return nil
        }

        let numberString = amount[numberRange].replacingOccurrences(of: ",", with: ".")
        guard let number = Double(numberString) else {
            return nil
        }

        return (number, String(amount[suffixRange]))
    }
}

private struct IngredientSubstitutionSheet: View {
    @Environment(\.locale) private var locale
    let ingredient: Ingredient
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(IngredientTranslator.displayName(for: ingredient.name, locale: locale))
                        .font(DSTypography.title)
                        .foregroundStyle(DSColor.textPrimary)
                    Text("Possible substitutes")
                        .font(DSTypography.body)
                        .foregroundStyle(DSColor.textSecondary)
                }
                .dsAppear(delay: 0.02)

                VStack(spacing: DSSpacing.md) {
                    ForEach(Array(IngredientSubstitutionProvider.substitutions(for: ingredient.name).enumerated()), id: \.element) { index, substitution in
                        Button {
                            onSelect(substitution)
                        } label: {
                            HStack(spacing: DSSpacing.md) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundStyle(DSColor.accent)
                                    .frame(width: 30, height: 30)
                                    .background(DSColor.accentSurface)
                                    .clipShape(Circle())

                                Text(LocalizedStringKey(substitution))
                                    .font(DSTypography.body)
                                    .foregroundStyle(DSColor.textPrimary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .padding(DSSpacing.md)
                            .dsCard(cornerRadius: 18, showsShadow: false)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Replace with \(substitution)"))
                        .dsAppear(delay: Double(index) * 0.05 + 0.08)
                    }
                }

                Spacer()
            }
            .padding(DSSpacing.lg)
            .appBackground()
            .navigationTitle("Substitutes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
