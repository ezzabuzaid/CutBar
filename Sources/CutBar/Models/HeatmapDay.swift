import Foundation

struct HeatmapDay: Hashable, Identifiable {
    let dayKey: String
    let date: Date
    let totals: NutritionSummary?
    let proteinProgress: Double

    var hasEntries: Bool { totals != nil }
    var id: String { dayKey }
}

extension HeatmapDay {
    static let windowSize = 30
    static let progressCap: Double = 1.25

    static func window(
        logs: [DayLog],
        proteinTarget: Int,
        now: Date,
        calendar: Calendar = .current
    ) -> [HeatmapDay] {
        let logsByKey = Dictionary(logs.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let target = max(proteinTarget, 1)
        let startOfToday = calendar.startOfDay(for: now)

        return (0..<windowSize).reversed().compactMap { offset -> HeatmapDay? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: startOfToday) else {
                return nil
            }

            let key = CutBarFormatters.dayKey(for: date)
            let log = logsByKey[key]
            let totals = (log?.entries.isEmpty ?? true) ? nil : log?.totals
            let progress: Double
            if let totals {
                progress = min(progressCap, Double(totals.proteinGrams) / Double(target))
            } else {
                progress = 0
            }

            return HeatmapDay(dayKey: key, date: date, totals: totals, proteinProgress: progress)
        }
    }

    static func streak(in window: [HeatmapDay]) -> Int {
        var count = 0
        let lastIndex = window.count - 1

        for index in stride(from: lastIndex, through: 0, by: -1) {
            let day = window[index]
            let hitGoal = day.hasEntries && day.proteinProgress >= 1.0

            if hitGoal {
                count += 1
            } else if index == lastIndex {
                continue
            } else {
                break
            }
        }

        return count
    }
}
