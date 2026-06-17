import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecipeImageView(url: recipe.imageURL)
                .frame(height: 150)

            VStack(alignment: .leading, spacing: DSSpacing.md) {
                HStack(alignment: .top, spacing: DSSpacing.md) {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text(recipe.title)
                            .font(DSTypography.title)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let description = recipe.description, !description.isEmpty {
                            Text(description)
                                .font(DSTypography.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DSColor.matcha)
                }

                HStack(spacing: DSSpacing.md) {
                    Label("\(recipe.cookingTimeMinutes) min", systemImage: "clock")
                    if let difficulty = recipe.difficulty, !difficulty.isEmpty {
                        Label(difficulty.capitalized, systemImage: "chart.bar.fill")
                    }
                }
                .font(DSTypography.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: DSSpacing.sm) {
                    NutritionPill(title: "Kcal", value: "\(recipe.nutrition.calories)", tint: DSColor.yuzu)
                    NutritionPill(title: "Protein", value: "\(Int(recipe.nutrition.protein))g", tint: DSColor.matcha)
                    NutritionPill(title: "Fat", value: "\(Int(recipe.nutrition.fats))g", tint: DSColor.yuzu)
                    NutritionPill(title: "Carbs", value: "\(Int(recipe.nutrition.carbs))g", tint: DSColor.matcha)
                }
            }
            .padding(20)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.16)) }
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

struct RecipeImageView: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            default:
                ZStack {
                    LinearGradient(colors: [DSColor.matcha.opacity(0.8), DSColor.yuzu.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

private struct NutritionPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(DSTypography.caption).foregroundStyle(.primary)
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
