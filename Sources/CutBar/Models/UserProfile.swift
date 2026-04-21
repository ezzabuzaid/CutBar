import Foundation

struct SlotWindow: Codable, Hashable {
    var startMinutes: Int
    var endMinutes: Int

    init(startMinutes: Int, endMinutes: Int) {
        self.startMinutes = max(0, min(23 * 60 + 59, startMinutes))
        self.endMinutes = max(0, min(23 * 60 + 59, endMinutes))
    }
}

struct UserProfile: Codable, Hashable {
    var dailyTargets: DailyTargets
    var meal1Target: MealTarget
    var shakeTarget: MealTarget
    var meal2Target: MealTarget
    var meal1Window: SlotWindow
    var shakeWindow: SlotWindow
    var meal2Window: SlotWindow
    var defaultSource: String
    var defaultRestaurantBuffer: CalorieBuffer
    var presets: [FoodPreset]

    static func seeded(from plan: CutPlan = .current) -> UserProfile {
        UserProfile(
            dailyTargets: plan.dailyTargets,
            meal1Target: plan.target(for: .meal1),
            shakeTarget: plan.target(for: .shake),
            meal2Target: plan.target(for: .meal2),
            meal1Window: SlotWindow(
                startMinutes: plan.feedingWindowStartMinutes,
                endMinutes: plan.mealOneCutoffMinutes
            ),
            shakeWindow: SlotWindow(
                startMinutes: plan.gymCutoffMinutes,
                endMinutes: plan.shakeCutoffMinutes
            ),
            meal2Window: SlotWindow(
                startMinutes: plan.shakeCutoffMinutes,
                endMinutes: plan.feedingWindowEndMinutes
            ),
            defaultSource: "Custom",
            defaultRestaurantBuffer: plan.defaultRestaurantBuffer,
            presets: plan.presetFoods.enumerated().map { index, preset in
                var updated = preset
                updated.sortOrder = index
                updated.isPinned = index < 3
                updated.isEnabled = true
                return updated
            }
        )
    }

    var feedingWindowStartMinutes: Int {
        meal1Window.startMinutes
    }

    var mealOneCutoffMinutes: Int {
        meal1Window.endMinutes
    }

    var gymCutoffMinutes: Int {
        shakeWindow.startMinutes
    }

    var shakeCutoffMinutes: Int {
        shakeWindow.endMinutes
    }

    var feedingWindowEndMinutes: Int {
        meal2Window.endMinutes
    }

    var fastingWindowText: String {
        "\(CutBarFormatters.clockTime(for: feedingWindowEndMinutes)) - \(CutBarFormatters.clockTime(for: feedingWindowStartMinutes))"
    }

    var feedingWindowText: String {
        CutBarFormatters.timeRangeText(
            startMinutes: feedingWindowStartMinutes,
            endMinutes: feedingWindowEndMinutes
        )
    }

    var protocolRules: [String] {
        [
            "Feeding window: \(feedingWindowText).",
            "\(MealSlot.meal1.shortTitle): \(windowText(for: .meal1)).",
            "\(MealSlot.shake.shortTitle): \(windowText(for: .shake)).",
            "\(MealSlot.meal2.shortTitle): \(windowText(for: .meal2)).",
            "Default source: \(defaultSource). Restaurant buffer: \(defaultRestaurantBuffer.shortTitle).",
        ]
    }

    func target(for slot: MealSlot) -> MealTarget {
        switch slot {
        case .meal1:
            return meal1Target
        case .shake:
            return shakeTarget
        case .meal2:
            return meal2Target
        }
    }

    mutating func setTarget(_ target: MealTarget, for slot: MealSlot) {
        switch slot {
        case .meal1:
            meal1Target = target
        case .shake:
            shakeTarget = target
        case .meal2:
            meal2Target = target
        }
    }

    func slotWindow(for slot: MealSlot) -> SlotWindow {
        switch slot {
        case .meal1:
            return meal1Window
        case .shake:
            return shakeWindow
        case .meal2:
            return meal2Window
        }
    }

    mutating func setSlotWindow(_ window: SlotWindow, for slot: MealSlot) {
        switch slot {
        case .meal1:
            meal1Window = window
        case .shake:
            shakeWindow = window
        case .meal2:
            meal2Window = window
        }
    }

    func windowText(for slot: MealSlot) -> String {
        let window = slotWindow(for: slot)
        return CutBarFormatters.timeRangeText(
            startMinutes: window.startMinutes,
            endMinutes: window.endMinutes
        )
    }

    func phase(at date: Date, calendar: Calendar = .current) -> DayPhase {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)

        if minutes < feedingWindowStartMinutes || minutes >= feedingWindowEndMinutes {
            return .fasting
        }

        if minutes < mealOneCutoffMinutes {
            return .mealOneWindow
        }

        if minutes < gymCutoffMinutes {
            return .gymWindow
        }

        if minutes < shakeCutoffMinutes {
            return .shakeWindow
        }

        return .mealTwoWindow
    }

    var enabledPresets: [FoodPreset] {
        presets
            .filter(\.isEnabled)
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder {
                    return lhs.sortOrder < rhs.sortOrder
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    var quickPinnedPresets: [FoodPreset] {
        enabledPresets
            .filter(\.isPinned)
            .prefix(3)
            .map { $0 }
    }

    mutating func normalizeForPersistence() {
        normalizeWindows()
        normalizeDefaults()
        normalizePresetSortOrder()
    }

    private mutating func normalizeDefaults() {
        let trimmedSource = defaultSource.trimmingCharacters(in: .whitespacesAndNewlines)
        defaultSource = trimmedSource.isEmpty ? "Custom" : trimmedSource
    }

    private mutating func normalizeWindows() {
        var points = [
            meal1Window.startMinutes,
            meal1Window.endMinutes,
            shakeWindow.startMinutes,
            shakeWindow.endMinutes,
            meal2Window.startMinutes,
            meal2Window.endMinutes,
        ].map { max(0, min(23 * 60 + 59, $0)) }

        points[0] = max(points[0], 0)
        points[1] = max(points[1], points[0] + 1)
        points[2] = max(points[2], points[1])
        points[3] = max(points[3], points[2] + 1)
        points[4] = max(points[4], points[3])
        points[5] = max(points[5], points[4] + 1)

        points[5] = min(points[5], 23 * 60 + 59)
        points[4] = min(points[4], points[5] - 1)
        points[3] = min(points[3], points[4])
        points[2] = min(points[2], points[3] - 1)
        points[1] = min(points[1], points[2])
        points[0] = min(points[0], points[1] - 1)

        points[0] = max(points[0], 0)
        points[1] = max(points[1], points[0] + 1)
        points[2] = max(points[2], points[1])
        points[3] = max(points[3], points[2] + 1)
        points[4] = max(points[4], points[3])
        points[5] = max(points[5], points[4] + 1)
        points[5] = min(points[5], 23 * 60 + 59)

        meal1Window = SlotWindow(startMinutes: points[0], endMinutes: points[1])
        shakeWindow = SlotWindow(startMinutes: points[2], endMinutes: points[3])
        meal2Window = SlotWindow(startMinutes: points[4], endMinutes: points[5])
    }

    mutating func normalizePresetSortOrder() {
        for index in presets.indices where !presets[index].isEnabled {
            presets[index].isPinned = false
        }

        let pinnedIDs = presets
            .filter { $0.isPinned && $0.isEnabled }
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.id)
            .prefix(3)

        let pinnedSet = Set(pinnedIDs)
        for index in presets.indices where presets[index].isPinned && !pinnedSet.contains(presets[index].id) {
            presets[index].isPinned = false
        }

        var nextPinnedOrder = 0
        for pinnedID in pinnedIDs {
            guard let index = presets.firstIndex(where: { $0.id == pinnedID }) else { continue }
            presets[index].sortOrder = nextPinnedOrder
            nextPinnedOrder += 1
        }

        for index in presets.indices where !presets[index].isPinned || !presets[index].isEnabled {
            presets[index].sortOrder = max(nextPinnedOrder, presets[index].sortOrder)
            nextPinnedOrder += 1
        }
    }
}
