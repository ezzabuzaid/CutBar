import Foundation
import XCTest
@testable import CutBar

@MainActor
final class CutBarModelTests: XCTestCase {
    func testMenuBarTitleFallsBackToPhaseWhenNothingLogged() {
        let model = CutBarModel(store: makeStore())

        XCTAssertEqual(model.todayTotals, .zero)
        XCTAssertEqual(model.menuBarTitle, model.currentPhase.menuBarLabel)
    }

    func testMenuBarTitleSwitchesToTotalsOnceLogged() {
        let model = CutBarModel(store: makeStore())

        model.logPreset(samplePreset(id: "shake", slot: .shake, protein: 40, calories: 250))

        XCTAssertEqual(model.todayTotals.proteinGrams, 40)
        XCTAssertEqual(model.todayTotals.calories, 250)
        XCTAssertEqual(model.menuBarTitle, "40P 250k")
    }

    func testRemainingBudgetsClampToZero() {
        let model = CutBarModel(store: makeStore())
        let targets = model.profile.dailyTargets

        model.logPreset(
            samplePreset(
                id: "massive",
                slot: .meal1,
                protein: targets.proteinGrams + 50,
                calories: targets.calories + 500
            )
        )

        XCTAssertEqual(model.remainingProtein, 0)
        XCTAssertEqual(model.remainingCalories, 0)
    }

    func testSaveDraftAppendsEntryAndClearsDraft() {
        let model = CutBarModel(store: makeStore())
        model.startCustomEntry(for: .meal1)
        model.activeDraft?.title = "Chicken bowl"
        model.activeDraft?.proteinGramsText = "45"
        model.activeDraft?.caloriesText = "600"
        model.activeDraft?.calorieBuffer = .plus20

        model.saveDraft()

        XCTAssertNil(model.activeDraft)
        XCTAssertEqual(model.todayEntries.count, 1)
        let saved = model.todayEntries[0]
        XCTAssertEqual(saved.title, "Chicken bowl")
        XCTAssertEqual(saved.proteinGrams, 45)
        XCTAssertEqual(saved.baseCalories, 600)
        XCTAssertEqual(saved.calories, 720)
    }

    func testSaveDraftIgnoresIncompleteDraft() {
        let model = CutBarModel(store: makeStore())
        model.startCustomEntry(for: .meal1)
        model.activeDraft?.title = "Only a title"

        model.saveDraft()

        XCTAssertNotNil(model.activeDraft)
        XCTAssertTrue(model.todayEntries.isEmpty)
    }

    func testDeleteRemovesEntry() {
        let model = CutBarModel(store: makeStore())
        model.logPreset(samplePreset(id: "shake", slot: .shake, protein: 40, calories: 250))
        let entry = try! XCTUnwrap(model.todayEntries.first)

        model.delete(entry)

        XCTAssertTrue(model.todayEntries.isEmpty)
    }

    func testStartCustomEntryBlockedWhenStorageUnavailable() throws {
        let appDirectory = makeTempAppDirectory()
        let store = FoodLogStore(appDirectory: appDirectory)
        try Data("not-a-sqlite-database".utf8).write(to: URL(fileURLWithPath: store.path))
        let model = CutBarModel(store: store)

        XCTAssertFalse(model.canMutateStorage)

        model.startCustomEntry(for: .meal1)

        XCTAssertNil(model.activeDraft)
    }

    func testSaveProfileReturnsFalseWhenStorageUnavailable() throws {
        let appDirectory = makeTempAppDirectory()
        let store = FoodLogStore(appDirectory: appDirectory)
        try Data("not-a-sqlite-database".utf8).write(to: URL(fileURLWithPath: store.path))
        let model = CutBarModel(store: store)

        var updated = model.profile
        updated.defaultSource = "Will Not Save"

        XCTAssertFalse(model.saveProfile(updated))
    }

    func testSaveProfileReturnsTrueWhenPersisted() {
        let model = CutBarModel(store: makeStore())
        var updated = model.profile
        updated.defaultSource = "Office"

        XCTAssertTrue(model.saveProfile(updated))
        XCTAssertEqual(model.profile.defaultSource, "Office")
    }

    func testTotalProgressNormalizesAgainstTargetsAndCaps() {
        let model = CutBarModel(store: makeStore())
        model.logPreset(samplePreset(id: "shake", slot: .shake, protein: 50, calories: 500))

        let progress = model.totalProgress(proteinTarget: 100, calorieTarget: 250)

        XCTAssertEqual(progress.protein, 0.5, accuracy: 0.0001)
        XCTAssertEqual(progress.calories, 1.0, accuracy: 0.0001)
    }

    func testTotalProgressHandlesZeroTargets() {
        let model = CutBarModel(store: makeStore())

        let progress = model.totalProgress(proteinTarget: 0, calorieTarget: 0)

        XCTAssertEqual(progress.protein, 0)
        XCTAssertEqual(progress.calories, 0)
    }

    func testSlotSummaryAggregatesPerMealSlot() {
        let model = CutBarModel(store: makeStore())
        model.logPreset(samplePreset(id: "meal1-a", slot: .meal1, protein: 30, calories: 400))
        model.logPreset(samplePreset(id: "meal1-b", slot: .meal1, protein: 20, calories: 300))
        model.logPreset(samplePreset(id: "shake", slot: .shake, protein: 40, calories: 250))

        let meal1 = model.slotSummary(for: .meal1)
        let shake = model.slotSummary(for: .shake)
        let meal2 = model.slotSummary(for: .meal2)

        XCTAssertEqual(meal1.proteinGrams, 50)
        XCTAssertEqual(meal1.calories, 700)
        XCTAssertEqual(shake.proteinGrams, 40)
        XCTAssertEqual(meal2, .zero)
    }

    func testSelectDayIgnoresTodayKey() {
        let model = CutBarModel(store: makeStore())

        model.selectDay(model.todayKey)

        XCTAssertNil(model.selectedDayKey)
    }

    func testSelectDayIgnoresKeyWithNoLoggedEntries() {
        let model = CutBarModel(store: makeStore())

        model.selectDay("2026-04-10")

        XCTAssertNil(model.selectedDayKey)
    }

    func testSelectDayTogglesOffOnRepeat() throws {
        let model = CutBarModel(store: makeStore())
        model.logPreset(samplePreset(id: "meal1", slot: .meal1, protein: 30, calories: 400))
        let key = try XCTUnwrap(model.recentDays.first?.id)

        // Force-set through the property to simulate selecting a past day without
        // re-testing today-key behavior here.
        model.selectedDayKey = key

        model.selectDay(key)

        XCTAssertNil(model.selectedDayKey)
    }

    func testClearSelectionResetsSelectedDay() {
        let model = CutBarModel(store: makeStore())
        model.selectDay("2026-04-10")

        model.clearSelection()

        XCTAssertNil(model.selectedDayKey)
    }

    func testQuickPresetsUsePinnedOrderAndLimitToThree() {
        let model = CutBarModel(store: makeStore())
        var profile = model.profile
        profile.presets = [
            FoodPreset(id: "a", title: "A", mealSlot: .meal1, proteinGrams: 10, calories: 100, source: "X", note: nil, isPinned: true, sortOrder: 2, isEnabled: true),
            FoodPreset(id: "b", title: "B", mealSlot: .shake, proteinGrams: 10, calories: 100, source: "X", note: nil, isPinned: true, sortOrder: 0, isEnabled: true),
            FoodPreset(id: "c", title: "C", mealSlot: .meal2, proteinGrams: 10, calories: 100, source: "X", note: nil, isPinned: true, sortOrder: 1, isEnabled: true),
            FoodPreset(id: "d", title: "D", mealSlot: .meal2, proteinGrams: 10, calories: 100, source: "X", note: nil, isPinned: true, sortOrder: 3, isEnabled: true),
            FoodPreset(id: "e", title: "E", mealSlot: .meal2, proteinGrams: 10, calories: 100, source: "X", note: nil, isPinned: false, sortOrder: 4, isEnabled: true),
        ]

        _ = model.saveProfile(profile)

        XCTAssertEqual(model.quickPresets.map(\.id), ["b", "c", "a"])
    }

    func testSetPresetPinnedLimitsToThreeFavorites() {
        let model = CutBarModel(store: makeStore())
        var profile = model.profile
        profile.presets = [
            FoodPreset(id: "one", title: "One", mealSlot: .meal1, proteinGrams: 10, calories: 100, source: "X", note: nil, isPinned: false, sortOrder: 0, isEnabled: true),
            FoodPreset(id: "two", title: "Two", mealSlot: .meal1, proteinGrams: 10, calories: 100, source: "X", note: nil, isPinned: false, sortOrder: 1, isEnabled: true),
            FoodPreset(id: "three", title: "Three", mealSlot: .shake, proteinGrams: 10, calories: 100, source: "X", note: nil, isPinned: false, sortOrder: 2, isEnabled: true),
            FoodPreset(id: "four", title: "Four", mealSlot: .meal2, proteinGrams: 10, calories: 100, source: "X", note: nil, isPinned: false, sortOrder: 3, isEnabled: true),
        ]
        _ = model.saveProfile(profile)

        model.setPresetPinned(id: "one", isPinned: true)
        model.setPresetPinned(id: "two", isPinned: true)
        model.setPresetPinned(id: "three", isPinned: true)
        model.setPresetPinned(id: "four", isPinned: true)

        let pinnedIDs = model.profile.presets.filter(\.isPinned).map(\.id)
        XCTAssertEqual(Set(pinnedIDs), Set(["one", "two", "three"]))
        XCTAssertFalse(model.profile.presets.first(where: { $0.id == "four" })?.isPinned ?? true)
    }

    func testStartCustomEntryUsesProfileDefaults() {
        let model = CutBarModel(store: makeStore())
        var profile = model.profile
        profile.defaultSource = "My Kitchen"
        profile.defaultRestaurantBuffer = .plus25

        _ = model.saveProfile(profile)
        model.startCustomEntry(for: .shake)

        XCTAssertEqual(model.activeDraft?.source, "My Kitchen")
        XCTAssertEqual(model.activeDraft?.calorieBuffer, .plus25)
    }

    func testProfileWindowAndTargetsAffectPhaseAndProgress() {
        let model = CutBarModel(store: makeStore())
        var profile = model.profile
        profile.dailyTargets = DailyTargets(calories: 2000, proteinGrams: 150, fatGrams: 70, carbGrams: 150)
        profile.meal1Window = SlotWindow(startMinutes: 10 * 60, endMinutes: 11 * 60)
        profile.shakeWindow = SlotWindow(startMinutes: 12 * 60, endMinutes: 12 * 60 + 30)
        profile.meal2Window = SlotWindow(startMinutes: 13 * 60, endMinutes: 16 * 60)
        _ = model.saveProfile(profile)

        let date = makeLocalDate(hour: 12, minute: 15)
        model.refreshClock(now: date)
        model.logPreset(samplePreset(id: "x", slot: .meal1, protein: 75, calories: 1000))

        XCTAssertEqual(model.currentPhase, .shakeWindow)
        let progress = model.totalProgress(
            proteinTarget: model.profile.dailyTargets.proteinGrams,
            calorieTarget: model.profile.dailyTargets.calories
        )
        XCTAssertEqual(progress.protein, 0.5, accuracy: 0.0001)
        XCTAssertEqual(progress.calories, 0.5, accuracy: 0.0001)
    }

    func testSaveProfileCanonicalizesInvalidWindowOrdering() {
        let model = CutBarModel(store: makeStore())
        var profile = model.profile
        profile.meal1Window = SlotWindow(startMinutes: 23 * 60 + 30, endMinutes: 23 * 60)
        profile.shakeWindow = SlotWindow(startMinutes: 9 * 60, endMinutes: 8 * 60)
        profile.meal2Window = SlotWindow(startMinutes: 6 * 60, endMinutes: 5 * 60)

        XCTAssertTrue(model.saveProfile(profile))

        let saved = model.profile
        XCTAssertLessThan(saved.meal1Window.startMinutes, saved.meal1Window.endMinutes)
        XCTAssertLessThanOrEqual(saved.meal1Window.endMinutes, saved.shakeWindow.startMinutes)
        XCTAssertLessThan(saved.shakeWindow.startMinutes, saved.shakeWindow.endMinutes)
        XCTAssertLessThanOrEqual(saved.shakeWindow.endMinutes, saved.meal2Window.startMinutes)
        XCTAssertLessThan(saved.meal2Window.startMinutes, saved.meal2Window.endMinutes)
    }

    private func samplePreset(id: String, slot: MealSlot, protein: Int, calories: Int) -> FoodPreset {
        FoodPreset(
            id: id,
            title: id,
            mealSlot: slot,
            proteinGrams: protein,
            calories: calories,
            source: "Test",
            note: nil
        )
    }

    private func makeStore() -> FoodLogStore {
        FoodLogStore(appDirectory: makeTempAppDirectory())
    }

    private func makeTempAppDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeLocalDate(hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let today = calendar.dateComponents([.year, .month, .day], from: .now)
        return calendar.date(
            from: DateComponents(
                calendar: calendar,
                year: today.year,
                month: today.month,
                day: today.day,
                hour: hour,
                minute: minute
            )
        )!
    }
}
