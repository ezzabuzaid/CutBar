import XCTest
@testable import CutBar

final class FoodEntryDraftTests: XCTestCase {
    func testProteinAndCaloriesParseFromText() {
        var draft = FoodEntryDraft(mealSlot: .meal1)
        draft.proteinGramsText = "35"
        draft.caloriesText = "420"

        XCTAssertEqual(draft.proteinGrams, 35)
        XCTAssertEqual(draft.baseCalories, 420)
    }

    func testMalformedNumbersParseToZero() {
        var draft = FoodEntryDraft(mealSlot: .meal1)
        draft.proteinGramsText = "abc"
        draft.caloriesText = ""

        XCTAssertEqual(draft.proteinGrams, 0)
        XCTAssertEqual(draft.baseCalories, 0)
    }

    func testAdjustedCaloriesRoundsWithBufferMarkup() {
        var draft = FoodEntryDraft(mealSlot: .meal2, calorieBuffer: .plus25)
        draft.caloriesText = "520"

        XCTAssertEqual(draft.adjustedCalories, 650)
    }

    func testCleanedFieldsTrimWhitespace() {
        let draft = FoodEntryDraft(
            mealSlot: .meal1,
            title: "  Zinger  ",
            source: " Stay Healthy ",
            note: "   "
        )

        XCTAssertEqual(draft.cleanedTitle, "Zinger")
        XCTAssertEqual(draft.cleanedSource, "Stay Healthy")
        XCTAssertNil(draft.cleanedNote)
    }

    func testCanSaveRequiresTitleProteinAndCalories() {
        var draft = FoodEntryDraft(mealSlot: .meal1)
        XCTAssertFalse(draft.canSave)

        draft.title = "Zinger"
        XCTAssertFalse(draft.canSave)

        draft.proteinGramsText = "35"
        XCTAssertFalse(draft.canSave)

        draft.caloriesText = "520"
        XCTAssertTrue(draft.canSave)
    }

    func testCanSaveRejectsWhitespaceOnlyTitle() {
        let draft = FoodEntryDraft(
            mealSlot: .meal1,
            title: "   ",
            proteinGramsText: "35",
            caloriesText: "520"
        )

        XCTAssertFalse(draft.canSave)
    }
}
