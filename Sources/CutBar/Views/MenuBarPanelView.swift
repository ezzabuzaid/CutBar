import AppKit
import Observation
import SwiftUI

struct MenuBarPanelView: View {
    @Bindable var model: CutBarModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let storageIssue = model.storageIssue {
                storageIssueBanner(storageIssue)
            }
            headerCard
            slotSummarySection
            quickLogSection
            recentEntriesSection
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 360)
        .background(Color.themeSurface)
    }

    private var headerCard: some View {
        let progress = model.totalProgress(
            proteinTarget: model.plan.dailyTargets.proteinGrams,
            calorieTarget: model.plan.dailyTargets.calories
        )

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.currentPhase.title)
                        .font(.appTitle3)
                    Text(model.currentPhase.detail)
                        .font(.appSubheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(model.todayTotals.proteinGrams)g")
                        .font(.appHeadline.monospacedDigit())
                    Text("\(model.todayTotals.calories) kcal")
                        .font(.appSubheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            metricRow(
                title: "Protein",
                current: model.todayTotals.proteinGrams,
                target: model.plan.dailyTargets.proteinGrams,
                progress: progress.protein
            )

            metricRow(
                title: "Calories",
                current: model.todayTotals.calories,
                target: model.plan.dailyTargets.calories,
                progress: progress.calories
            )

            Text("\(model.remainingProtein)g protein left, \(model.remainingCalories) kcal left")
                .font(.appFootnote)
                .foregroundStyle(.secondary)
        }
    }

    private var slotSummarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.appHeadline)

            ForEach(MealSlot.allCases) { slot in
                let totals = model.slotSummary(for: slot)
                let target = model.plan.target(for: slot)

                HStack(spacing: 10) {
                    Image(systemName: slot.systemImage)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.shortTitle)
                            .font(.appSubheadlineMedium)
                        Text(slot.windowText)
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(totals.proteinGrams)/\(target.proteinGrams)g")
                        .font(.appCaption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Quick Log")
                    .font(.appHeadline)

                Spacer()

                Button {
                    let suggestedSlot = model.currentPhase.suggestedSlot ?? .meal2
                    model.startCustomEntry(for: suggestedSlot)
                    openDashboard()
                } label: {
                    Label("New Entry", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                        .font(.appBodyFont(11, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!model.canMutateStorage)
            }

            ForEach(model.quickPresets) { preset in
                Button {
                    model.logPreset(preset)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.title)
                                .font(.appSubheadlineMedium)
                            Text("\(preset.proteinGrams)g protein, \(preset.calories) kcal")
                                .font(.appCaption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.tint)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .disabled(!model.canMutateStorage)
            }
        }
    }

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.appHeadline)

            if model.todayEntries.isEmpty {
                Text("Nothing logged yet today.")
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(model.todayEntries.suffix(3).reversed())) { entry in
                    RecentEntryRow(
                        entry: entry,
                        onSelect: openDashboard
                    ) {
                        model.delete(entry)
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 2) {
            footerRow("Open Dashboard", systemImage: "macwindow") {
                openDashboard()
            }

            footerRow("Meal History", systemImage: "clock.arrow.circlepath") {
                openWindow(id: "history")
                NSApp.activate(ignoringOtherApps: true)
            }

            footerRow("Refresh", systemImage: "arrow.clockwise") {
                model.refreshClock()
            }
            .accessibilityLabel("Refresh totals")

            footerRow("Quit", systemImage: "power") {
                NSApplication.shared.terminate(nil)
            }
        }
        .font(.appSubheadline)
    }

    private func footerRow(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        FooterRowButton(title: title, systemImage: systemImage, action: action)
    }

    private func metricRow(
        title: String,
        current: Int,
        target: Int,
        progress: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.appSubheadlineMedium)
                Spacer()
                Text("\(current)/\(target)")
                    .font(.appCaption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(Color.themeAccent)
                .animation(.spring(response: 0.5, dampingFraction: 0.9), value: progress)
        }
    }

    private func openDashboard() {
        openWindow(id: "dashboard")
        NSApp.activate(ignoringOtherApps: true)
    }

    private func storageIssueBanner(_ storageIssue: String) -> some View {
        Label(storageIssue, systemImage: "exclamationmark.triangle.fill")
            .font(.appFootnote)
            .foregroundStyle(Color.themeWarningForeground)
            .padding(12)
            .background(Color.themeWarningBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityLabel("Storage issue: \(storageIssue)")
    }
}

private struct FooterRowButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .frame(width: 16)
                    .foregroundStyle(.secondary)
                Text(title)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered ? Color.themeHover : Color.clear)
            )
        }
        .buttonStyle(.pressable)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}

private struct RecentEntryRow: View {
    let entry: FoodEntry
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.appSubheadlineMedium)
                    Text("\(entry.source) · \(entry.mealSlot.shortTitle) at \(CutBarFormatters.time.string(from: entry.loggedAt))")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(entry.proteinGrams)g / \(entry.calories) kcal")
                    .font(.appCaption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.themeHover : Color.clear)
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .accessibilityHint("Opens the dashboard")
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
