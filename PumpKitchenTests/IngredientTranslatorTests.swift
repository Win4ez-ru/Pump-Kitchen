import XCTest
@testable import Pump_Kitchen

final class IngredientTranslatorTests: XCTestCase {
    private let russian = Locale(identifier: "ru")
    private let english = Locale(identifier: "en")

    // MARK: - Search terms (RU -> EN)

    func testEnglishInputPassesThroughUnchanged() {
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "chicken 250g"), "chicken 250g")
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "Greek yogurt"), "Greek yogurt")
    }

    func testExactRussianNameIsTranslated() {
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "курица"), "chicken")
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "Помидоры"), "tomatoes")
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "гречка"), "buckwheat")
    }

    func testColloquialSynonymsAreTranslated() {
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "курочка"), "chicken")
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "картошка"), "potatoes")
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "куриное филе"), "chicken breast")
    }

    func testTyposAreFuzzyMatched() {
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "куирца"), "chicken")
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "памидоры"), "tomatoes")
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "куринная грудка"), "chicken breast")
    }

    func testQuantityIsPreservedAndUnitTranslated() {
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "курица 250г"), "chicken 250g")
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "рис 150 г"), "rice 150g")
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "яйца 3"), "eggs 3")
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "молоко 200мл"), "milk 200ml")
    }

    func testPhraseWithExtraWordsFindsKnownIngredient() {
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "свежая курица"), "chicken")
    }

    func testUnknownRussianWordFallsBackToOriginal() {
        XCTAssertEqual(IngredientTranslator.searchTerm(for: "пангасиус"), "пангасиус")
    }

    // MARK: - Display names (EN -> RU)

    func testDisplayNameTranslatesForRussianLocale() {
        XCTAssertEqual(IngredientTranslator.displayName(for: "Chicken breast raw", locale: russian), "Куриная грудка")
        XCTAssertEqual(IngredientTranslator.displayName(for: "Olive oil extra virgin", locale: russian), "Оливковое масло")
        XCTAssertEqual(IngredientTranslator.displayName(for: "eggs", locale: russian), "Яйца")
    }

    func testDisplayNamePrefersLongestMatch() {
        XCTAssertEqual(IngredientTranslator.displayName(for: "cottage cheese", locale: russian), "Творог")
        XCTAssertEqual(IngredientTranslator.displayName(for: "sour cream", locale: russian), "Сметана")
    }

    func testDisplayNameKeepsOriginalForEnglishLocale() {
        XCTAssertEqual(IngredientTranslator.displayName(for: "Chicken breast raw", locale: english), "Chicken breast raw")
    }

    func testDisplayNameKeepsUnknownAndCyrillicNames() {
        XCTAssertEqual(IngredientTranslator.displayName(for: "dragon fruit puree", locale: russian), "dragon fruit puree")
        XCTAssertEqual(IngredientTranslator.displayName(for: "Куриная грудка", locale: russian), "Куриная грудка")
    }

    // MARK: - Levenshtein

    func testLevenshteinDistance() {
        XCTAssertEqual(IngredientTranslator.levenshteinDistance("курица", "курица"), 0)
        XCTAssertEqual(IngredientTranslator.levenshteinDistance("курица", "куирца"), 2)
        XCTAssertEqual(IngredientTranslator.levenshteinDistance("", "abc"), 3)
    }
}
