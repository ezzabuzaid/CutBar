import Foundation

struct FoodEntry: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let mealSlot: MealSlot
    let proteinGrams: Int
    let calories: Int
    let baseCalories: Int
    let calorieBuffer: CalorieBuffer
    let loggedAt: Date
    let source: String
    let note: String?

    init(
        id: UUID = UUID(),
        title: String,
        mealSlot: MealSlot,
        proteinGrams: Int,
        calories: Int,
        baseCalories: Int,
        calorieBuffer: CalorieBuffer,
        loggedAt: Date = .now,
        source: String,
        note: String? = nil
    ) {
        self.id = id
        self.title = title
        self.mealSlot = mealSlot
        self.proteinGrams = proteinGrams
        self.calories = calories
        self.baseCalories = baseCalories
        self.calorieBuffer = calorieBuffer
        self.loggedAt = loggedAt
        self.source = source
        self.note = note
    }

    static func preset(_ preset: FoodPreset, loggedAt: Date = .now) -> FoodEntry {
        FoodEntry(
            title: preset.title,
            mealSlot: preset.mealSlot,
            proteinGrams: preset.proteinGrams,
            calories: preset.calories,
            baseCalories: preset.calories,
            calorieBuffer: .none,
            loggedAt: loggedAt,
            source: preset.source,
            note: preset.note
        )
    }

    var adjustmentSummary: String? {
        guard calorieBuffer != .none else {
            return nil
        }

        return "\(baseCalories) kcal base, saved as \(calories) kcal"
    }
}
