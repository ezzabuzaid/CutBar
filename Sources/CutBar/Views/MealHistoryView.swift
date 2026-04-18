import Observation
import SwiftUI

struct MealHistoryView: View {
    @Bindable var model: CutBarModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if model.recentDays.isEmpty {
                    emptyState
                } else {
                    ForEach(model.recentDays) { day in
                        DayHistoryCard(day: day) { entry in
                            model.delete(entry)
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(minWidth: 520, minHeight: 560)
        .background(Color.themeSurface)
        .navigationTitle("Meal History")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Meal History")
                .font(.appLargeTitle)

            Text("\(model.recentDays.count) days logged")
                .font(.appSubheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nothing here yet.")
                .font(.appHeadline)
            Text("Log a meal from the menubar and it will show up here.")
                .font(.appSubheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.themeCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct DayHistoryCard: View {
    let day: DayLog
    let onDelete: (FoodEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(CutBarFormatters.displayDay(for: day.id))
                        .font(.appTitle3)
                    Text("\(day.entries.count) entries")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(day.totals.proteinGrams)g protein")
                        .font(.appHeadline.monospacedDigit())
                    Text("\(day.totals.calories) kcal")
                        .font(.appSubheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(spacing: 6) {
                ForEach(day.sortedEntries) { entry in
                    HistoryEntryRow(entry: entry) {
                        onDelete(entry)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.themeCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct HistoryEntryRow: View {
    let entry: FoodEntry
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var confirmingDelete = false

    var body: some View {
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
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        )
        .onHover { isHovered = $0 }
        .contextMenu {
            Button(role: .destructive) {
                confirmingDelete = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete \(entry.title)?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive, action: onDelete)
                .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This entry will be removed from \(CutBarFormatters.displayDay(for: CutBarFormatters.dayKey(for: entry.loggedAt))). This cannot be undone.")
        }
    }
}
