import Foundation

struct FoodEntryDraft: Hashable, Identifiable {
    let id: UUID
    var mealSlot: MealSlot
    var title: String
    var proteinGramsText: String
    var caloriesText: String
    var source: String
    var note: String
    var calorieBuffer: CalorieBuffer

    init(
        id: UUID = UUID(),
        mealSlot: MealSlot,
        title: String = "",
        proteinGramsText: String = "",
        caloriesText: String = "",
        source: String = "Custom",
        note: String = "",
        calorieBuffer: CalorieBuffer = .none
    ) {
        self.id = id
        self.mealSlot = mealSlot
        self.title = title
        self.proteinGramsText = proteinGramsText
        self.caloriesText = caloriesText
        self.source = source
        self.note = note
        self.calorieBuffer = calorieBuffer
    }

    var proteinGrams: Int {
        Int(proteinGramsText) ?? 0
    }

    var baseCalories: Int {
        Int(caloriesText) ?? 0
    }

    var adjustedCalories: Int {
        calorieBuffer.apply(to: baseCalories)
    }

    var cleanedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var cleanedSource: String {
        source.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var cleanedNote: String? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var canSave: Bool {
        !cleanedTitle.isEmpty && proteinGrams > 0 && baseCalories > 0
    }
}
