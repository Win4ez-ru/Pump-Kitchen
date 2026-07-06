import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe
    let isSaved: Bool

    init(recipe: Recipe, isSaved: Bool = false) {
        self.recipe = recipe
        self.isSaved = isSaved
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            FittedRecipeImage(url: recipe.imageURL)

            LinearGradient(
                colors: [.clear, .black.opacity(0.04), .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 10) {
                RecipeTagStrip(tags: recipe.tags, limit: 2, style: .overImage)

                Text(LocalizedStringKey(recipe.title))
                    .font(.system(size: 23, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(18)
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 16, x: 0, y: 9)
    }
}

struct RecipeImageView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAlive = false
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(reduceMotion ? 1 : (isAlive ? 1.035 : 1.005))
                    .transition(.opacity.combined(with: .scale(scale: 1.015)))
            default:
                MealArtView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.spring(duration: 8.5, bounce: 0).repeatForever(autoreverses: true)) {
                isAlive = true
            }
        }
    }
}

struct FittedRecipeImage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAlive = false
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                ZStack {
                    image
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 18)
                        .scaleEffect(reduceMotion ? 1.14 : (isAlive ? 1.18 : 1.14))

                    Color.black.opacity(0.18)

                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(reduceMotion ? 1 : (isAlive ? 1.012 : 1))
                        .transition(.opacity.combined(with: .scale(scale: 1.01)))
                }
            default:
                MealArtView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.spring(duration: 9.5, bounce: 0).repeatForever(autoreverses: true)) {
                isAlive = true
            }
        }
    }
}

private struct MealArtView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DSColor.accentSurface, DSColor.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "fork.knife")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(DSColor.accent)
        }
    }
}
