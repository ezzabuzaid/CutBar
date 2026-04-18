import Observation
import SwiftUI

struct DashboardView: View {
    @Bindable var model: CutBarModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let storageIssue = model.storageIssue {
                    storageIssueBanner(storageIssue)
                }
                summaryCard
                protocolCard

                ForEach(MealSlot.allCases) { slot in
                    MealSlotCardView(model: model, slot: slot)
                }
            }
            .padding(20)
        }
        .frame(minWidth: 460, minHeight: 560)
        .background(Color.themeSurface)
        .sheet(isPresented: draftPresented) {
            if let draft = Binding($model.activeDraft) {
                FoodEntryComposerView(
                    draft: draft,
                    onSave: model.saveDraft,
                    onCancel: model.cancelDraft
                )
            }
        }
    }

    private var draftPresented: Binding<Bool> {
        Binding(
            get: { model.activeDraft != nil },
            set: { presented in
                if !presented {
                    model.cancelDraft()
                }
            }
        )
    }

    private var summaryCard: some View {
        let progress = model.totalProgress(
            proteinTarget: model.plan.dailyTargets.proteinGrams,
            calorieTarget: model.plan.dailyTargets.calories
        )

        return VStack(alignment: .leading, spacing: 14) {
            Text("CutBar")
                .font(.appLargeTitle)
            Text("Built around your repo plan: 18:6 feeding window, Meal 1 -> gym -> shake -> Meal 2.")
                .font(.appSubheadline)
                .foregroundStyle(.secondary)

            HStack {
                Label(model.currentPhase.title, systemImage: model.currentPhase.systemImage)
                    .font(.appHeadline)
                Spacer()
                Text(CutBarFormatters.displayDay(for: model.todayKey))
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)
            }

            progressRow(
                title: "Protein",
                current: model.todayTotals.proteinGrams,
                target: model.plan.dailyTargets.proteinGrams,
                progress: progress.protein
            )

            progressRow(
                title: "Calories",
                current: model.todayTotals.calories,
                target: model.plan.dailyTargets.calories,
                progress: progress.calories
            )

            HStack {
                statPill(title: "Remaining protein", value: "\(model.remainingProtein)g")
                statPill(title: "Remaining calories", value: "\(model.remainingCalories)")
            }
        }
        .padding(16)
        .background(Color.themeCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var protocolCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Protocol")
                .font(.appHeadline)

            HStack {
                statPill(title: "Fast", value: model.plan.fastingWindowText)
                statPill(title: "Feed", value: model.plan.feedingWindowText)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(model.plan.rules, id: \.self) { rule in
                    Label(rule, systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.appSubheadline)
        }
        .padding(16)
        .background(Color.themeSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func progressRow(
        title: String,
        current: Int,
        target: Int,
        progress: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.appHeadline)
                Spacer()
                Text("\(current)/\(target)")
                    .font(.appSubheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(Color.themeAccent)
        }
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.appCaption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.appHeadline.monospacedDigit())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.themeCard)
        )
    }

    private func storageIssueBanner(_ storageIssue: String) -> some View {
        Label(storageIssue, systemImage: "exclamationmark.triangle.fill")
            .font(.appSubheadline)
            .foregroundStyle(Color.themeWarningForeground)
            .padding(16)
            .background(Color.themeWarningBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityLabel("Storage issue: \(storageIssue)")
    }
}
