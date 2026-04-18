import Observation
import SwiftUI

struct MealSlotCardView: View {
    @Bindable var model: CutBarModel
    let slot: MealSlot

    var body: some View {
        let target = model.plan.target(for: slot)
        let summary = model.slotSummary(for: slot)
        let proteinProgress = target.proteinGrams == 0 ? 0 : min(1, Double(summary.proteinGrams) / Double(target.proteinGrams))
        let calorieProgress = target.calories == 0 ? 0 : min(1, Double(summary.calories) / Double(target.calories))

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(slot.title, systemImage: slot.systemImage)
                        .font(.appTitle3)
                    Text(slot.windowText)
                        .font(.appSubheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(summary.proteinGrams)/\(target.proteinGrams)g")
                        .font(.appHeadline.monospacedDigit())
                    Text("\(summary.calories)/\(target.calories) kcal")
                        .font(.appSubheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: proteinProgress) {
                Text("Protein progress")
            }
            .progressViewStyle(.linear)
            .tint(Color.themeAccent)

            ProgressView(value: calorieProgress) {
                Text("Calorie progress")
            }
            .progressViewStyle(.linear)
            .tint(Color.themeAccent)

            if !model.presets(for: slot).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick presets")
                        .font(.appSubheadlineMedium)

                    ForEach(model.presets(for: slot)) { preset in
                        Button {
                            model.logPreset(preset)
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.title)
                                        .font(.appSubheadlineMedium)
                                    Text(preset.source)
                                        .font(.appCaption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("\(preset.proteinGrams)g / \(preset.calories) kcal")
                                    .font(.appCaption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(!model.canMutateStorage)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Logged entries")
                        .font(.appSubheadlineMedium)

                    Spacer()

                    Button {
                        model.startCustomEntry(for: slot)
                    } label: {
                        Label("New Entry", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!model.canMutateStorage)
                }

                if model.slotEntries(for: slot).isEmpty {
                    Text("No entries logged for \(slot.shortTitle.lowercased()) yet.")
                        .font(.appSubheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.slotEntries(for: slot)) { entry in
                        LoggedEntryRowView(
                            entry: entry,
                            canMutateStorage: model.canMutateStorage
                        ) {
                            model.delete(entry)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.themeCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct LoggedEntryRowView: View {
    let entry: FoodEntry
    let canMutateStorage: Bool
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var confirmingDelete = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.appSubheadlineMedium)

                Text("\(entry.source) at \(CutBarFormatters.time.string(from: entry.loggedAt))")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)

                if let adjustmentSummary = entry.adjustmentSummary {
                    Text(adjustmentSummary)
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }

                if let note = entry.note {
                    Text(note)
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(entry.proteinGrams)g")
                    .font(.appSubheadline.monospacedDigit())
                Text("\(entry.calories) kcal")
                    .font(.appCaption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .disabled(!canMutateStorage)
                .accessibilityLabel("Delete \(entry.title)")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.themeCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isHovered ? Color.themeHover : Color.clear)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onHover { isHovered = $0 }
        .contextMenu {
            Button(role: .destructive) {
                confirmingDelete = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .disabled(!canMutateStorage)
        }
        .alert("Delete \(entry.title)?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
                .keyboardShortcut(.defaultAction)
        } message: {
            Text("This entry will be removed from today's log. This cannot be undone.")
        }
    }
}
