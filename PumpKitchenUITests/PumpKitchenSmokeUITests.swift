import XCTest

final class PumpKitchenSmokeUITests: XCTestCase {
    func testCleanInstallDemoGenerateDetailsFavorite() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-reset-user-defaults",
            "-skip-onboarding"
        ]
        app.launch()

        let demoButton = app.buttons["auth.demoModeButton"]
        XCTAssertTrue(demoButton.waitForExistence(timeout: 8))
        demoButton.tap()

        let ingredientInput = app.textFields["home.ingredientInput"]
        if !ingredientInput.waitForExistence(timeout: 8), demoButton.exists {
            demoButton.tap()
        }

        XCTAssertTrue(ingredientInput.waitForExistence(timeout: 8))

        let chickenButton = app.buttons["home.quickIngredient.Chicken"]
        XCTAssertTrue(chickenButton.waitForExistence(timeout: 4))
        chickenButton.tap()

        let riceButton = app.buttons["home.quickIngredient.Rice"]
        XCTAssertTrue(riceButton.waitForExistence(timeout: 4))
        riceButton.tap()

        let generateButton = app.buttons["home.generateButton"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 8))
        generateButton.tap()

        let firstRecipe = app.buttons["home.recipeResult.first"]
        XCTAssertTrue(firstRecipe.waitForExistence(timeout: 12))
        if !firstRecipe.isHittable {
            app.swipeUp()
            XCTAssertTrue(firstRecipe.waitForExistence(timeout: 4))
        }
        firstRecipe.tap()

        let favoriteButton = app.buttons["recipeDetails.favoriteButton"]
        if !favoriteButton.waitForExistence(timeout: 8), firstRecipe.exists {
            firstRecipe.tap()
        }
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 8))
        favoriteButton.tap()
    }
}
