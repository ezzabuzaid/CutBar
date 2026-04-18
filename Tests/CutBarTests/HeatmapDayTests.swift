import Foundation
import XCTest
@testable import CutBar

final class HeatmapDayTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testWindowHasThirtyDaysEndingAtToday() {
        let now = fixedDate(year: 2026, month: 4, day: 18)
        let window = HeatmapDay.window(logs: [], proteinTarget: 150, now: now, calendar: calendar)

        XCTAssertEqual(window.count, 30)
        XCTAssertEqual(window.last?.dayKey, "2026-04-18")
        XCTAssertEqual(window.first?.dayKey, "2026-03-20")

        let keysAreAscending = zip(window, window.dropFirst()).allSatisfy { $0.dayKey < $1.dayKey }
        XCTAssertTrue(keysAreAscending)
    }

    func testEmptyLogsYieldNoEntriesAndZeroStreak() {
        let now = fixedDate(year: 2026, month: 4, day: 18)
        let window = HeatmapDay.window(logs: [], proteinTarget: 150, now: now, calendar: calendar)

        XCTAssertTrue(window.allSatisfy { !$0.hasEntries })
        XCTAssertTrue(window.allSatisfy { $0.proteinProgress == 0 })
        XCTAssertEqual(HeatmapDay.streak(in: window), 0)
    }

    func testProteinProgressCapsAtOnePointTwoFive() {
        let now = fixedDate(year: 2026, month: 4, day: 18)
        let overachieved = dayLog(on: now, protein: 300, calories: 2000)

        let window = HeatmapDay.window(
            logs: [overachieved],
            proteinTarget: 150,
            now: now,
            calendar: calendar
        )

        let today = try! XCTUnwrap(window.last)
        XCTAssertEqual(today.proteinProgress, 1.25, accuracy: 0.0001)
    }

    func testStreakCountsConsecutiveGoalDaysEndingToday() {
        let now = fixedDate(year: 2026, month: 4, day: 18)
        let logs = [
            dayLog(offset: -2, from: now, protein: 160),
            dayLog(offset: -1, from: now, protein: 155),
            dayLog(offset: 0, from: now, protein: 150),
        ]

        let window = HeatmapDay.window(logs: logs, proteinTarget: 150, now: now, calendar: calendar)
        XCTAssertEqual(HeatmapDay.streak(in: window), 3)
    }

    func testStreakSkipsTodayWhenNotYetAtGoal() {
        let now = fixedDate(year: 2026, month: 4, day: 18)
        let logs = [
            dayLog(offset: -2, from: now, protein: 160),
            dayLog(offset: -1, from: now, protein: 155),
            dayLog(offset: 0, from: now, protein: 80),
        ]

        let window = HeatmapDay.window(logs: logs, proteinTarget: 150, now: now, calendar: calendar)
        XCTAssertEqual(HeatmapDay.streak(in: window), 2)
    }

    func testStreakStopsAtGap() {
        let now = fixedDate(year: 2026, month: 4, day: 18)
        let logs = [
            dayLog(offset: -4, from: now, protein: 160),
            dayLog(offset: -3, from: now, protein: 155),
            // gap at -2
            dayLog(offset: -1, from: now, protein: 160),
            dayLog(offset: 0, from: now, protein: 155),
        ]

        let window = HeatmapDay.window(logs: logs, proteinTarget: 150, now: now, calendar: calendar)
        XCTAssertEqual(HeatmapDay.streak(in: window), 2)
    }

    func testStreakZeroWhenTodayMissedAndYesterdayMissed() {
        let now = fixedDate(year: 2026, month: 4, day: 18)
        let logs = [
            dayLog(offset: -1, from: now, protein: 80),
            dayLog(offset: 0, from: now, protein: 100),
        ]

        let window = HeatmapDay.window(logs: logs, proteinTarget: 150, now: now, calendar: calendar)
        XCTAssertEqual(HeatmapDay.streak(in: window), 0)
    }

    func testWindowTolerateDuplicateDayKeys() {
        let now = fixedDate(year: 2026, month: 4, day: 18)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let key = CutBarFormatters.dayKey(for: yesterday)
        let duplicate1 = DayLog(id: key, entries: [
            FoodEntry(
                title: "A",
                mealSlot: .meal1,
                proteinGrams: 100,
                calories: 1000,
                baseCalories: 1000,
                calorieBuffer: .none,
                loggedAt: yesterday,
                source: "Test"
            ),
        ])
        let duplicate2 = DayLog(id: key, entries: [
            FoodEntry(
                title: "B",
                mealSlot: .meal2,
                proteinGrams: 50,
                calories: 500,
                baseCalories: 500,
                calorieBuffer: .none,
                loggedAt: yesterday,
                source: "Test"
            ),
        ])

        let window = HeatmapDay.window(
            logs: [duplicate1, duplicate2],
            proteinTarget: 150,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(window.count, 30)
        let yesterdayCell = window[window.count - 2]
        XCTAssertTrue(yesterdayCell.hasEntries)
    }

    func testEmptyDaysDistinguishedFromZeroProgress() {
        let now = fixedDate(year: 2026, month: 4, day: 18)
        let log = dayLog(offset: -1, from: now, protein: 0, calories: 10)

        let window = HeatmapDay.window(logs: [log], proteinTarget: 150, now: now, calendar: calendar)
        let yesterday = window[window.count - 2]
        let twoDaysAgo = window[window.count - 3]

        XCTAssertTrue(yesterday.hasEntries)
        XCTAssertEqual(yesterday.proteinProgress, 0)
        XCTAssertFalse(twoDaysAgo.hasEntries)
    }

    // MARK: - Helpers

    private func fixedDate(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: 12)
        return calendar.date(from: components)!
    }

    private func dayLog(offset: Int, from reference: Date, protein: Int, calories: Int = 1500) -> DayLog {
        let date = calendar.date(byAdding: .day, value: offset, to: reference)!
        return dayLog(on: date, protein: protein, calories: calories)
    }

    private func dayLog(on date: Date, protein: Int, calories: Int = 1500) -> DayLog {
        let key = CutBarFormatters.dayKey(for: date)
        let entry = FoodEntry(
            title: "Test entry",
            mealSlot: .meal1,
            proteinGrams: protein,
            calories: calories,
            baseCalories: calories,
            calorieBuffer: .none,
            loggedAt: date,
            source: "Test"
        )
        return DayLog(id: key, entries: [entry])
    }
}
