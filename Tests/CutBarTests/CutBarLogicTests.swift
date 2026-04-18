import XCTest
@testable import CutBar

final class CutBarLogicTests: XCTestCase {
    func testFastingPhaseBeforeFivePm() {
        let plan = CutPlan.current
        let fixture = makeDate(hour: 16, minute: 30)

        XCTAssertEqual(plan.phase(at: fixture.date, calendar: fixture.calendar), .fasting)
    }

    func testMealTwoPhaseAfterShakeWindow() {
        let plan = CutPlan.current
        let fixture = makeDate(hour: 21, minute: 5)

        XCTAssertEqual(plan.phase(at: fixture.date, calendar: fixture.calendar), .mealTwoWindow)
    }

    func testCalorieBufferAppliesRoundedMarkup() {
        XCTAssertEqual(CalorieBuffer.plus20.apply(to: 350), 420)
        XCTAssertEqual(CalorieBuffer.plus25.apply(to: 520), 650)
    }

    func testNutritionSummaryAggregatesEntries() {
        let entries = [
            FoodEntry.preset(
                FoodPreset(
                    id: "zinger",
                    title: "Zinger",
                    mealSlot: .meal1,
                    proteinGrams: 35,
                    calories: 520,
                    source: "Stay Healthy",
                    note: nil
                )
            ),
            FoodEntry.preset(
                FoodPreset(
                    id: "shake",
                    title: "Shake",
                    mealSlot: .shake,
                    proteinGrams: 40,
                    calories: 250,
                    source: "Home",
                    note: nil
                )
            ),
        ]

        let summary = NutritionSummary(entries: entries)

        XCTAssertEqual(summary.proteinGrams, 75)
        XCTAssertEqual(summary.calories, 770)
    }

    private func makeDate(hour: Int, minute: Int) -> (date: Date, calendar: Calendar) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let date = calendar.date(
            from: DateComponents(
                calendar: calendar,
                year: 2026,
                month: 4,
                day: 17,
                hour: hour,
                minute: minute
            )
        )!

        return (date, calendar)
    }
}
