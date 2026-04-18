import Foundation
import XCTest
@testable import CutBar

@MainActor
final class CutBarEndToEndTests: XCTestCase {
    func testLoggingFlowPersistsAcrossRelaunchAndDelete() throws {
        let appDirectory = makeTempAppDirectory()
        let store = FoodLogStore(appDirectory: appDirectory)
        let initialModel = CutBarModel(store: store)

        initialModel.logPreset(
            FoodPreset(
                id: "e2e-shake",
                title: "E2E Shake",
                mealSlot: .shake,
                proteinGrams: 40,
                calories: 250,
                source: "Home",
                note: "Post workout"
            )
        )

        initialModel.startCustomEntry(for: .meal2)
        initialModel.activeDraft?.title = "  Chicken Bowl  "
        initialModel.activeDraft?.proteinGramsText = "50"
        initialModel.activeDraft?.caloriesText = "600"
        initialModel.activeDraft?.calorieBuffer = .plus20
        initialModel.activeDraft?.source = "  Local Spot  "
        initialModel.activeDraft?.note = "  extra pickles  "
        initialModel.saveDraft()

        XCTAssertNil(initialModel.activeDraft)
        XCTAssertNil(initialModel.storageIssue)
        XCTAssertEqual(initialModel.todayTotals, NutritionSummary(proteinGrams: 90, calories: 970))
        XCTAssertEqual(initialModel.menuBarTitle, "90P 970k")
        XCTAssertEqual(
            Set(initialModel.todayEntries.map(\.title)),
            ["E2E Shake", "Chicken Bowl"]
        )

        let relaunchedModel = CutBarModel(store: FoodLogStore(appDirectory: appDirectory))
        XCTAssertNil(relaunchedModel.storageIssue)
        XCTAssertEqual(relaunchedModel.todayTotals, NutritionSummary(proteinGrams: 90, calories: 970))

        let restoredDraftEntry = try XCTUnwrap(
            relaunchedModel.todayEntries.first(where: { $0.title == "Chicken Bowl" })
        )
        XCTAssertEqual(restoredDraftEntry.baseCalories, 600)
        XCTAssertEqual(restoredDraftEntry.calories, 720)
        XCTAssertEqual(restoredDraftEntry.calorieBuffer, .plus20)
        XCTAssertEqual(restoredDraftEntry.source, "Local Spot")
        XCTAssertEqual(restoredDraftEntry.note, "extra pickles")

        relaunchedModel.delete(restoredDraftEntry)

        let afterDeleteModel = CutBarModel(store: FoodLogStore(appDirectory: appDirectory))
        XCTAssertNil(afterDeleteModel.storageIssue)
        XCTAssertEqual(afterDeleteModel.todayEntries.map(\.title), ["E2E Shake"])
        XCTAssertEqual(afterDeleteModel.todayTotals, NutritionSummary(proteinGrams: 40, calories: 250))
    }

    private func makeTempAppDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
