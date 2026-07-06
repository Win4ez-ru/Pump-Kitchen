import XCTest
@testable import Pump_Kitchen

final class IngredientParsingTests: XCTestCase {
    func testParseIngredientsSplitsCommasAndNewlines() {
        let ingredients = Validation.parseIngredients(from: "chicken, rice\n cucumber ")

        XCTAssertEqual(ingredients, ["chicken", "rice", "cucumber"])
    }

    func testParseIngredientsDropsEmptyValues() {
        let ingredients = Validation.parseIngredients(from: "  tomato,,\n\n basil  , ")

        XCTAssertEqual(ingredients, ["tomato", "basil"])
    }
}
