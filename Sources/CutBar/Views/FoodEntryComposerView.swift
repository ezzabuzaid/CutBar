import SwiftUI

struct FoodEntryComposerView: View {
    @Binding var draft: FoodEntryDraft
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Entry") {
                    TextField("Item name", text: $draft.title)

                    Picker("Meal slot", selection: $draft.mealSlot) {
                        ForEach(MealSlot.allCases) { slot in
                            Text(slot.title).tag(slot)
                        }
                    }

                    TextField("Source", text: $draft.source)
                }

                Section("Macros") {
                    TextField("Protein (g)", text: $draft.proteinGramsText)
                    TextField("Base calories", text: $draft.caloriesText)

                    Picker("Calorie buffer", selection: $draft.calorieBuffer) {
                        ForEach(CalorieBuffer.allCases) { buffer in
                            Text(buffer.title).tag(buffer)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $draft.note)
                }

                Section("Final save") {
                    HStack {
                        Text("Saved calories")
                        Spacer()
                        Text("\(draft.adjustedCalories) kcal")
                            .font(.appHeadline.monospacedDigit())
                    }

                    HStack {
                        Text("Saved protein")
                        Spacer()
                        Text("\(draft.proteinGrams)g")
                            .font(.appHeadline.monospacedDigit())
                    }

                    Text(summaryText)
                        .font(.appFootnote)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Entry")
            .frame(minWidth: 420, minHeight: 380)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(!draft.canSave)
                        .keyboardShortcut("s", modifiers: .command)
                }
            }
        }
    }

    private var summaryText: String {
        if draft.calorieBuffer == .none {
            return "Saving the calories exactly as entered."
        }

        return "The restaurant safety buffer raises \(draft.baseCalories) kcal to \(draft.adjustedCalories) kcal."
    }
}
