import SwiftUI

struct SelectedDayDetailCardView: View {
    let day: DayLog
    let onClear: () -> Void

    private var totals: NutritionSummary { day.totals }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                ForEach([MealSlot.meal1, .shake, .meal2], id: \.self) { slot in
                    let entries = day.entries(for: slot)
                    if !entries.isEmpty {
                        slotSection(slot: slot, entries: entries)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.themeCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(CutBarFormatters.displayDay(for: day.id))
                    .font(.appTitle3)
                Text("\(totals.proteinGrams)g protein · \(totals.calories) kcal · \(day.entries.count) entries")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Today", action: onClear)
                .buttonStyle(.borderless)
                .keyboardShortcut(.cancelAction)
                .font(.appSubheadlineMedium)
                .foregroundStyle(Color.themeAccent)
        }
    }

    private func slotSection(slot: MealSlot, entries: [FoodEntry]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(slot.shortTitle)
                .font(.appCaption)
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                ForEach(entries) { entry in
                    row(for: entry)
                }
            }
        }
    }

    private func row(for entry: FoodEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.mealSlot.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.appSubheadlineMedium)
                Text("\(entry.mealSlot.shortTitle) · \(CutBarFormatters.time.string(from: entry.loggedAt)) · \(entry.source)")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                if let note = entry.note {
                    Text(note)
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.proteinGrams)g")
                    .font(.appSubheadline.monospacedDigit())
                Text("\(entry.calories) kcal")
                    .font(.appCaption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.themeSurface)
        )
    }
}
