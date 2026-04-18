import Foundation
import Observation

@MainActor
@Observable
final class CutBarModel {
    let plan: CutPlan

    private let store: FoodLogStore
    private(set) var document: FoodLogDocument
    private(set) var now: Date
    private var clockTimer: Timer?

    var activeDraft: FoodEntryDraft?
    var storageIssue: String?
    var selectedDayKey: String?

    init(
        plan: CutPlan = .current,
        store: FoodLogStore = FoodLogStore()
    ) {
        self.plan = plan
        self.store = store
        now = .now

        switch store.load() {
        case let .success(document):
            self.document = document
            storageIssue = nil
        case let .failure(error):
            self.document = .empty
            storageIssue = error.userFacingMessage
        }

        startClock()
    }

    var canMutateStorage: Bool {
        storageIssue == nil
    }

    var todayKey: String {
        CutBarFormatters.dayKey(for: now)
    }

    var todayLog: DayLog {
        document.logs.first(where: { $0.id == todayKey }) ?? DayLog(id: todayKey, entries: [])
    }

    var todayEntries: [FoodEntry] {
        todayLog.sortedEntries
    }

    var todayTotals: NutritionSummary {
        todayLog.totals
    }

    var currentPhase: DayPhase {
        plan.phase(at: now)
    }

    var menuBarTitle: String {
        if todayTotals.proteinGrams == 0 && todayTotals.calories == 0 {
            return currentPhase.menuBarLabel
        }

        return "\(todayTotals.proteinGrams)P \(todayTotals.calories)k"
    }

    var remainingProtein: Int {
        max(0, plan.dailyTargets.proteinGrams - todayTotals.proteinGrams)
    }

    var remainingCalories: Int {
        max(0, plan.dailyTargets.calories - todayTotals.calories)
    }

    var recentDays: [DayLog] {
        document.logs
            .filter { !$0.entries.isEmpty }
            .sorted { $0.id > $1.id }
    }

    var heatmapDays: [HeatmapDay] {
        HeatmapDay.window(
            logs: document.logs,
            proteinTarget: plan.dailyTargets.proteinGrams,
            now: now
        )
    }

    var currentStreak: Int {
        HeatmapDay.streak(in: heatmapDays)
    }

    var selectedDayLog: DayLog? {
        guard let key = selectedDayKey else { return nil }
        return document.logs.first { $0.id == key }
    }

    func selectDay(_ key: String) {
        if key == todayKey || key == selectedDayKey {
            selectedDayKey = nil
            return
        }

        let hasEntries = document.logs.contains { $0.id == key && !$0.entries.isEmpty }
        guard hasEntries else { return }

        selectedDayKey = key
    }

    func clearSelection() {
        selectedDayKey = nil
    }

    func totalProgress(proteinTarget: Int, calorieTarget: Int) -> (protein: Double, calories: Double) {
        let proteinProgress = proteinTarget == 0 ? 0 : min(1, Double(todayTotals.proteinGrams) / Double(proteinTarget))
        let calorieProgress = calorieTarget == 0 ? 0 : min(1, Double(todayTotals.calories) / Double(calorieTarget))
        return (proteinProgress, calorieProgress)
    }

    func slotEntries(for slot: MealSlot) -> [FoodEntry] {
        todayLog.entries(for: slot)
    }

    func slotSummary(for slot: MealSlot) -> NutritionSummary {
        NutritionSummary(entries: slotEntries(for: slot))
    }

    func presets(for slot: MealSlot) -> [FoodPreset] {
        plan.presetFoods.filter { $0.mealSlot == slot }
    }

    var quickPresets: [FoodPreset] {
        Array(plan.presetFoods.prefix(3))
    }

    func startCustomEntry(for slot: MealSlot) {
        guard canMutateStorage else {
            return
        }

        activeDraft = FoodEntryDraft(
            mealSlot: slot,
            source: slot == .shake ? "Home" : "Restaurant",
            calorieBuffer: slot == .shake ? .none : plan.defaultRestaurantBuffer
        )
        AppLogger.actions.info("Opened custom entry draft for \(slot.rawValue, privacy: .public).")
    }

    func cancelDraft() {
        activeDraft = nil
    }

    func saveDraft() {
        guard canMutateStorage, let draft = activeDraft, draft.canSave else {
            return
        }

        let source = draft.cleanedSource.isEmpty ? "Custom" : draft.cleanedSource
        let entry = FoodEntry(
            title: draft.cleanedTitle,
            mealSlot: draft.mealSlot,
            proteinGrams: draft.proteinGrams,
            calories: draft.adjustedCalories,
            baseCalories: draft.baseCalories,
            calorieBuffer: draft.calorieBuffer,
            source: source,
            note: draft.cleanedNote
        )

        append(entry)
    }

    func logPreset(_ preset: FoodPreset) {
        guard canMutateStorage else {
            return
        }

        append(.preset(preset))
    }

    func delete(_ entry: FoodEntry) {
        guard canMutateStorage else {
            return
        }

        switch store.update({ document in
            document.logs = document.logs.compactMap { day in
                var updatedDay = day
                updatedDay.entries.removeAll { $0.id == entry.id }
                return updatedDay.entries.isEmpty ? nil : updatedDay
            }
        }) {
        case let .success(document):
            self.document = document
            storageIssue = nil
            AppLogger.actions.info("Deleted entry \(entry.title, privacy: .public).")
        case let .failure(error):
            storageIssue = error.userFacingMessage
            AppLogger.actions.error("Failed to delete entry: \(error.userFacingMessage, privacy: .public)")
        }
    }

    private func append(_ entry: FoodEntry) {
        let entryDayKey = CutBarFormatters.dayKey(for: entry.loggedAt)

        switch store.update({ document in
            if let dayIndex = document.logs.firstIndex(where: { $0.id == entryDayKey }) {
                document.logs[dayIndex].entries.append(entry)
            } else {
                document.logs.append(DayLog(id: entryDayKey, entries: [entry]))
            }
        }) {
        case let .success(document):
            self.document = document
            storageIssue = nil
            activeDraft = nil
            AppLogger.actions.info("Saved entry \(entry.title, privacy: .public).")
        case let .failure(error):
            storageIssue = error.userFacingMessage
            AppLogger.actions.error("Failed to save entry: \(error.userFacingMessage, privacy: .public)")
        }
    }

    func refreshClock(now: Date = .now) {
        self.now = now

        switch store.load() {
        case let .success(document):
            self.document = document
            storageIssue = nil
        case let .failure(error):
            storageIssue = error.userFacingMessage
        }
    }

    private func startClock() {
        let calendar = Calendar.current
        let current = now
        let nextMinuteBoundary = calendar.nextDate(
            after: current,
            matching: DateComponents(second: 0),
            matchingPolicy: .nextTime
        ) ?? current.addingTimeInterval(60)

        let timer = Timer(
            fire: nextMinuteBoundary,
            interval: 60,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshClock()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        clockTimer = timer
    }
}
