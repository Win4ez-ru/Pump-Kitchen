import XCTest

/// Walks through every main screen in Russian and saves full-screen captures
/// to /tmp/pumpkitchen-ui-shots for visual QA.
final class PumpKitchenScreenshotUITests: XCTestCase {
    private let shotsDirectory = URL(fileURLWithPath: "/tmp/pumpkitchen-ui-shots", isDirectory: true)

    func testCaptureAllScreensInRussian() throws {
        try? FileManager.default.removeItem(at: shotsDirectory)
        try? FileManager.default.createDirectory(at: shotsDirectory, withIntermediateDirectories: true)

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-reset-user-defaults",
            "-skip-onboarding",
            "-settings.appLanguage", "russian",
            "-settings.useMockGeneration", "1"
        ]
        app.launch()

        let ingredientInput = app.textFields["home.ingredientInput"]
        if !ingredientInput.waitForExistence(timeout: 6) {
            let demoButton = app.buttons["auth.demoModeButton"]
            if demoButton.waitForExistence(timeout: 4) {
                demoButton.tap()
            }
            XCTAssertTrue(ingredientInput.waitForExistence(timeout: 8))
        }
        sleep(2)
        save(app, "01-home-idle")

        // Featured recipe details
        let featured = app.buttons["home.featuredRecipe"]
        XCTAssertTrue(featured.waitForExistence(timeout: 6))
        featured.tap()
        sleep(2)
        save(app, "02-details-top")
        app.swipeUp(velocity: .slow)
        sleep(1)
        save(app, "03-details-nutrition")
        app.swipeUp(velocity: .slow)
        sleep(1)
        save(app, "04-details-steps")

        let backButton = app.buttons["recipeDetails.backButton"]
        if backButton.waitForExistence(timeout: 4) {
            backButton.tap()
        }
        sleep(1)

        // Search results
        let chicken = app.buttons["home.quickIngredient.Chicken"]
        if chicken.waitForExistence(timeout: 5) {
            chicken.tap()
            let generate = app.buttons["home.generateButton"]
            XCTAssertTrue(generate.waitForExistence(timeout: 6))
            generate.tap()
            _ = app.buttons["home.recipeResult.first"].waitForExistence(timeout: 12)
            sleep(2)
            save(app, "05-results")
        }

        // Tabs
        openTab(app, "favorites")
        save(app, "06-favorites")
        openTab(app, "history")
        save(app, "07-history")
        openTab(app, "profile")
        save(app, "08-profile")
        app.swipeUp(velocity: .slow)
        sleep(1)
        save(app, "09-profile-bottom")
    }

    private func openTab(_ app: XCUIApplication, _ tab: String) {
        let button = app.buttons["tab.\(tab)"]
        XCTAssertTrue(button.waitForExistence(timeout: 6), "Tab \(tab) not found")
        button.tap()
        sleep(2)
    }

    private func save(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let fileURL = shotsDirectory.appendingPathComponent("\(name).png")
        do {
            try screenshot.pngRepresentation.write(to: fileURL)
        } catch {
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
