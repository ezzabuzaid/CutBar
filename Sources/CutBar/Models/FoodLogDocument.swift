import Foundation

struct DayLog: Codable, Hashable, Identifiable {
    let id: String
    var entries: [FoodEntry]

    var sortedEntries: [FoodEntry] {
        entries.sorted { $0.loggedAt < $1.loggedAt }
    }

    var totals: NutritionSummary {
        NutritionSummary(entries: entries)
    }

    func entries(for slot: MealSlot) -> [FoodEntry] {
        sortedEntries.filter { $0.mealSlot == slot }
    }
}

struct FoodLogDocument: Codable, Hashable {
    var logs: [DayLog]
    var lastUpdatedAt: Date
    var profile: UserProfile

    init(
        logs: [DayLog],
        lastUpdatedAt: Date,
        profile: UserProfile = .seeded()
    ) {
        self.logs = logs
        self.lastUpdatedAt = lastUpdatedAt
        self.profile = profile
    }

    static let empty = FoodLogDocument(logs: [], lastUpdatedAt: .now, profile: .seeded())
}
