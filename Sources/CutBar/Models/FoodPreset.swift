import Foundation

struct FoodPreset: Codable, Hashable, Identifiable {
    var id: String
    var title: String
    var mealSlot: MealSlot
    var proteinGrams: Int
    var calories: Int
    var source: String
    var note: String?
    var isPinned: Bool
    var sortOrder: Int
    var isEnabled: Bool

    init(
        id: String,
        title: String,
        mealSlot: MealSlot,
        proteinGrams: Int,
        calories: Int,
        source: String,
        note: String?,
        isPinned: Bool = false,
        sortOrder: Int = 0,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.mealSlot = mealSlot
        self.proteinGrams = proteinGrams
        self.calories = calories
        self.source = source
        self.note = note
        self.isPinned = isPinned
        self.sortOrder = sortOrder
        self.isEnabled = isEnabled
    }
}
