import XCTest
@testable import Pump_Kitchen

final class RecipeStepLinkTests: XCTestCase {
    func testDetectsHTTPAndHTTPSLinks() {
        XCTAssertEqual(
            RecipeStepLink.url(from: "https://spoonacular.com/recipes/bowl-1234"),
            URL(string: "https://spoonacular.com/recipes/bowl-1234")
        )
        XCTAssertEqual(
            RecipeStepLink.url(from: "  http://example.com/recipe "),
            URL(string: "http://example.com/recipe")
        )
    }

    func testDetectsWWWLinksAndUpgradesToHTTPS() {
        XCTAssertEqual(
            RecipeStepLink.url(from: "www.example.com/recipe"),
            URL(string: "https://www.example.com/recipe")
        )
    }

    func testIgnoresRegularCookingSteps() {
        XCTAssertNil(RecipeStepLink.url(from: "Cook the rice until tender."))
        XCTAssertNil(RecipeStepLink.url(from: "Visit the market, then start cooking."))
        XCTAssertNil(RecipeStepLink.url(from: ""))
    }

    func testIgnoresLinksMentionedMidSentence() {
        XCTAssertNil(RecipeStepLink.url(from: "Original recipe: https://example.com"))
    }
}
