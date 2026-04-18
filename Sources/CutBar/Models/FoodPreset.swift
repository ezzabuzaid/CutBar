import Foundation

struct FoodPreset: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let mealSlot: MealSlot
    let proteinGrams: Int
    let calories: Int
    let source: String
    let note: String?
}
