import Foundation

struct NutritionSummary: Codable, Hashable {
    let proteinGrams: Int
    let calories: Int

    static let zero = NutritionSummary(proteinGrams: 0, calories: 0)

    init(proteinGrams: Int, calories: Int) {
        self.proteinGrams = proteinGrams
        self.calories = calories
    }

    init(entries: [FoodEntry]) {
        proteinGrams = entries.reduce(0) { $0 + $1.proteinGrams }
        calories = entries.reduce(0) { $0 + $1.calories }
    }
}
