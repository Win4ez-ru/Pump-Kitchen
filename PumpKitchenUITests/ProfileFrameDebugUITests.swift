import XCTest

final class ProfileFrameDebugUITests: XCTestCase {
    func testDumpProfileFrames() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-reset-user-defaults",
            "-skip-onboarding",
            "-settings.appLanguage", "russian",
            "-settings.useMockGeneration", "1"
        ]
        app.launch()

        let profileTab = app.buttons["tab.profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 8))
        profileTab.tap()
        sleep(2)

        print("FRAME-DUMP-BEGIN")
        print(app.debugDescription)
        print("FRAME-DUMP-END")
    }
}
