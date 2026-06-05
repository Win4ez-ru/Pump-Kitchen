import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe

    private var macroFitScore: Int {
        let proteinDensity = recipe.nutrition.protein / max(Double(recipe.nutrition.calories), 1) * 1000
        return min(97, max(78, Int((proteinDensity * 1.25 + 54).rounded())))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            HStack(alignment: .top, spacing: DSSpacing.md) {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(recipe.title)
                        .font(DSTypography.title)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: DSSpacing.sm) {
                        Label("\(recipe.cookingTimeMinutes) min", systemImage: "clock")
                        Label("\(recipe.ingredients.count) items", systemImage: "basket")
                    }
                    .font(DSTypography.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("\(macroFitScore)%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                    Text("fit")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(width: 48, height: 48)
                .background(LinearGradient(colors: [DSColor.matcha, DSColor.matcha.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(Circle())
                .shadow(color: DSColor.matcha.opacity(0.25), radius: 10, x: 0, y: 6)
            }

            HStack(spacing: DSSpacing.sm) {
                NutritionPill(title: "Kcal", value: "\(recipe.nutrition.calories)", tint: DSColor.yuzu)
                NutritionPill(title: "Protein", value: "\(Int(recipe.nutrition.protein))g", tint: DSColor.matcha)
                NutritionPill(title: "Fat", value: "\(Int(recipe.nutrition.fats))g", tint: DSColor.yuzu)
                NutritionPill(title: "Carbs", value: "\(Int(recipe.nutrition.carbs))g", tint: DSColor.matcha)
            }

            if !recipe.tags.isEmpty {
                FlowTags(tags: recipe.tags)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

private struct NutritionPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DSTypography.caption)
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct FlowTags: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DSSpacing.sm) {
                ForEach(tags.prefix(4), id: \.self) { tag in
                    Text(tag)
                        .font(DSTypography.caption)
                        .foregroundStyle(DSColor.matcha)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DSColor.matcha.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
