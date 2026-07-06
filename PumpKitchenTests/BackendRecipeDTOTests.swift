import XCTest
@testable import Pump_Kitchen

final class BackendRecipeDTOTests: XCTestCase {
    func testSearchResultDTOMapsToCompactRecipeCard() throws {
        let data = """
        {
          "spoonacular_id": 715538,
          "title": "Chicken Rice Bowl",
          "image_url": "https://example.com/bowl.jpg",
          "used_ingredients": 3,
          "missed_ingredients": 1
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(RecipeSearchResultDTO.self, from: data)
        let recipe = Recipe(searchResultDTO: dto)

        XCTAssertEqual(recipe.id, Recipe.stableUUID(for: 715538))
        XCTAssertEqual(recipe.backendIdentifier, "715538")
        XCTAssertEqual(recipe.title, "Chicken Rice Bowl")
        XCTAssertEqual(recipe.imageURL?.absoluteString, "https://example.com/bowl.jpg")
        XCTAssertEqual(recipe.ingredients, [])
        XCTAssertEqual(recipe.instructions, [])
        XCTAssertEqual(recipe.nutrition.calories, 0)
        XCTAssertEqual(recipe.tags, ["3 used", "1 missing"])
    }

    func testFullRecipeDTOMapsFullRecipePayload() throws {
        let data = """
        {
          "id": "recipe-abc",
          "spoonacular_id": 12345,
          "title": "Protein Pasta",
          "description": "Balanced pasta",
          "image_url": "https://example.com/pasta.jpg",
          "ready_in_minutes": 25,
          "difficulty": "easy",
          "ingredients": [
            { "name": "Chicken", "amount": "200", "unit": "g" },
            { "name": "Pasta", "amount": 90, "unit": "g" }
          ],
          "instructions": [
            "Cook the pasta.",
            "Sear the chicken."
          ],
          "nutrition": {
            "calories": 540,
            "protein": 48,
            "fat": 14,
            "carbs": 58
          },
          "why_fits_goal": "High protein",
          "tags": ["Dinner"],
          "gluten_free": false,
          "dairy_free": true,
          "servings": 2
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(FullRecipeDTO.self, from: data)
        let recipe = Recipe(fullRecipeDTO: dto)

        XCTAssertEqual(recipe.id, Recipe.stableUUID(for: "recipe-abc"))
        XCTAssertEqual(recipe.backendIdentifier, "recipe-abc")
        XCTAssertEqual(recipe.title, "Protein Pasta")
        XCTAssertEqual(recipe.cookingTimeMinutes, 25)
        XCTAssertEqual(recipe.ingredients.map(\.name), ["Chicken", "Pasta"])
        XCTAssertEqual(recipe.ingredients.map(\.amount), ["200 g", "90 g"])
        XCTAssertEqual(recipe.instructions, ["Cook the pasta.", "Sear the chicken."])
        XCTAssertEqual(recipe.nutrition.calories, 540)
        XCTAssertEqual(recipe.nutrition.protein, 48, accuracy: 0.001)
        XCTAssertEqual(recipe.nutrition.fats, 14, accuracy: 0.001)
        XCTAssertEqual(recipe.nutrition.carbs, 58, accuracy: 0.001)
        XCTAssertTrue(recipe.tips.contains("High protein"))
        XCTAssertTrue(recipe.tags.contains("Dairy Free"))
        XCTAssertTrue(recipe.tags.contains("2 servings"))
        XCTAssertTrue(recipe.tags.contains("Easy"))
    }

    func testSearchResponsePrefersFullRecipeDTOsOverCompactCards() throws {
        let data = """
        {
          "recipes": [
            {
              "id": "live-1",
              "title": "Chicken Rice Eggs",
              "image_url": "https://example.com/live.jpg",
              "ready_in_minutes": 20,
              "ingredients": [
                { "name": "Chicken", "amount": "250", "unit": "g" },
                { "name": "Rice", "amount": "150", "unit": "g" },
                { "name": "Eggs", "amount": 3, "unit": "pcs" }
              ],
              "steps": ["Cook rice.", "Sear chicken.", "Add eggs."],
              "nutrition": {
                "calories": 720,
                "protein": 62,
                "fat": 18,
                "carbs": 74
              },
              "tags": ["Top Pick"]
            }
          ]
        }
        """.data(using: .utf8)!

        let recipes = try BackendRecipeGenerationService.decodeRecipes(from: data)

        XCTAssertEqual(recipes.count, 1)
        XCTAssertEqual(recipes[0].backendIdentifier, "live-1")
        XCTAssertEqual(recipes[0].ingredients.map(\.name), ["Chicken", "Rice", "Eggs"])
        XCTAssertEqual(recipes[0].ingredients.map(\.amount), ["250 g", "150 g", "3 pcs"])
        XCTAssertEqual(recipes[0].instructions, ["Cook rice.", "Sear chicken.", "Add eggs."])
        XCTAssertEqual(recipes[0].nutrition.calories, 720)
        XCTAssertEqual(recipes[0].nutrition.fats, 18, accuracy: 0.001)
    }
}
