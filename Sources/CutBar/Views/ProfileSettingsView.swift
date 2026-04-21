import Observation
import SwiftUI

struct ProfileSettingsView: View {
    @Bindable var model: CutBarModel

    @State private var draft = UserProfile.seeded()
    @State private var didLoad = false

    @State private var isPresetEditorPresented = false
    @State private var presetEditorDraft = FoodPreset(
        id: UUID().uuidString.lowercased(),
        title: "",
        mealSlot: .meal1,
        proteinGrams: 30,
        calories: 300,
        source: "Custom",
        note: nil
    )
    @State private var editingPresetID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let storageIssue = model.storageIssue {
                    Label(storageIssue, systemImage: "exclamationmark.triangle.fill")
                        .font(.appSubheadline)
                        .foregroundStyle(Color.themeWarningForeground)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.themeWarningBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                dailyTargetsSection
                slotWindowsSection
                defaultsSection
                presetsSection
                footerActions
            }
            .padding(20)
        }
        .frame(minWidth: 620, minHeight: 700)
        .background(Color.themeSurface)
        .onAppear {
            if !didLoad {
                resetDraft()
                didLoad = true
            }
        }
        .sheet(isPresented: $isPresetEditorPresented) {
            PresetEditorSheet(
                preset: $presetEditorDraft,
                onSave: savePresetFromEditor,
                onCancel: { isPresetEditorPresented = false }
            )
        }
    }

    private var hasUnsavedChanges: Bool {
        draft != model.profile
    }

    private var dailyTargetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Targets")
                .font(.appHeadline)

            targetStepper(
                title: "Calories",
                value: $draft.dailyTargets.calories,
                range: 1_000...5_000,
                step: 10,
                suffix: "kcal"
            )
            targetStepper(
                title: "Protein",
                value: $draft.dailyTargets.proteinGrams,
                range: 60...350,
                step: 5,
                suffix: "g"
            )
            targetStepper(
                title: "Fat",
                value: $draft.dailyTargets.fatGrams,
                range: 20...250,
                step: 5,
                suffix: "g"
            )
            targetStepper(
                title: "Carbs",
                value: $draft.dailyTargets.carbGrams,
                range: 20...400,
                step: 5,
                suffix: "g"
            )
        }
        .padding(16)
        .background(Color.themeCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var slotWindowsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Slot Windows and Targets")
                .font(.appHeadline)

            ForEach(MealSlot.allCases) { slot in
                VStack(alignment: .leading, spacing: 10) {
                    Text(slot.title)
                        .font(.appSubheadlineMedium)

                    HStack {
                        DatePicker(
                            "Start",
                            selection: timeBinding(for: slot, isStart: true),
                            displayedComponents: .hourAndMinute
                        )
                        DatePicker(
                            "End",
                            selection: timeBinding(for: slot, isStart: false),
                            displayedComponents: .hourAndMinute
                        )
                    }
                    .font(.appSubheadline)

                    HStack(spacing: 12) {
                        targetStepper(
                            title: "Target calories",
                            value: targetCaloriesBinding(for: slot),
                            range: 100...2_000,
                            step: 10,
                            suffix: "kcal"
                        )
                        targetStepper(
                            title: "Target protein",
                            value: targetProteinBinding(for: slot),
                            range: 5...150,
                            step: 5,
                            suffix: "g"
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(Color.themeCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var defaultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Defaults")
                .font(.appHeadline)

            TextField("Default source", text: $draft.defaultSource)
                .textFieldStyle(.roundedBorder)
                .font(.appSubheadline)

            Picker("Default restaurant buffer", selection: $draft.defaultRestaurantBuffer) {
                ForEach(CalorieBuffer.allCases) { buffer in
                    Text(buffer.title).tag(buffer)
                }
            }
            .pickerStyle(.menu)
            .font(.appSubheadline)
        }
        .padding(16)
        .background(Color.themeCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Presets")
                    .font(.appHeadline)

                Spacer()

                Button {
                    startAddingPreset()
                } label: {
                    Label("Add Preset", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if draft.presets.isEmpty {
                Text("No presets yet. Add presets and pin favorites for Quick Log.")
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(orderedPresetIndices, id: \.self) { index in
                        presetRow(index: index)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.themeCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var footerActions: some View {
        HStack {
            Button("Reset Changes") {
                resetDraft()
            }
            .buttonStyle(.bordered)
            .disabled(!hasUnsavedChanges)

            Spacer()

            Button("Save Profile") {
                var normalized = draft
                normalized.normalizeForPersistence()
                if model.saveProfile(normalized) {
                    resetDraft()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.canMutateStorage || !hasUnsavedChanges)
        }
    }

    private var orderedPresetIndices: [Int] {
        draft.presets.indices.sorted { lhs, rhs in
            let left = draft.presets[lhs]
            let right = draft.presets[rhs]
            if left.sortOrder != right.sortOrder {
                return left.sortOrder < right.sortOrder
            }
            return left.title.localizedCaseInsensitiveCompare(right.title) == .orderedAscending
        }
    }

    private var pinnedPresetCount: Int {
        draft.presets.filter { $0.isPinned && $0.isEnabled }.count
    }

    private func targetStepper(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int,
        suffix: String
    ) -> some View {
        Stepper(value: value, in: range, step: step) {
            Text("\(title): \(value.wrappedValue) \(suffix)")
                .font(.appSubheadline)
        }
    }

    private func targetCaloriesBinding(for slot: MealSlot) -> Binding<Int> {
        Binding(
            get: { draft.target(for: slot).calories },
            set: { newValue in
                var target = draft.target(for: slot)
                target.calories = newValue
                draft.setTarget(target, for: slot)
            }
        )
    }

    private func targetProteinBinding(for slot: MealSlot) -> Binding<Int> {
        Binding(
            get: { draft.target(for: slot).proteinGrams },
            set: { newValue in
                var target = draft.target(for: slot)
                target.proteinGrams = newValue
                draft.setTarget(target, for: slot)
            }
        )
    }

    private func timeBinding(for slot: MealSlot, isStart: Bool) -> Binding<Date> {
        Binding(
            get: {
                let window = draft.slotWindow(for: slot)
                let minutes = isStart ? window.startMinutes : window.endMinutes
                return timeDate(for: minutes)
            },
            set: { newDate in
                var window = draft.slotWindow(for: slot)
                if isStart {
                    window.startMinutes = minutesSinceMidnight(for: newDate)
                } else {
                    window.endMinutes = minutesSinceMidnight(for: newDate)
                }
                draft.setSlotWindow(window, for: slot)
            }
        )
    }

    private func timeDate(for minutes: Int) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = .current
        return calendar.date(
            from: DateComponents(
                calendar: calendar,
                year: 2001,
                month: 1,
                day: 1,
                hour: minutes / 60,
                minute: minutes % 60
            )
        ) ?? .now
    }

    private func minutesSinceMidnight(for date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func presetRow(index: Int) -> some View {
        let preset = draft.presets[index]

        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(preset.title)
                    .font(.appSubheadlineMedium)
                Text("\(preset.mealSlot.shortTitle) · \(preset.proteinGrams)g / \(preset.calories) kcal · \(preset.source)")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Toggle("Enabled", isOn: Binding(
                    get: { draft.presets[index].isEnabled },
                    set: { isEnabled in
                        draft.presets[index].isEnabled = isEnabled
                        if !isEnabled {
                            draft.presets[index].isPinned = false
                        }
                        draft.normalizePresetSortOrder()
                    }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .help("Enabled")

                Toggle("Pinned", isOn: Binding(
                    get: { draft.presets[index].isPinned },
                    set: { isPinned in
                        if isPinned && !draft.presets[index].isPinned && pinnedPresetCount >= 3 {
                            return
                        }
                        draft.presets[index].isPinned = isPinned
                        if isPinned {
                            let maxPinned = draft.presets
                                .filter(\.isPinned)
                                .map(\.sortOrder)
                                .max() ?? -1
                            draft.presets[index].sortOrder = maxPinned + 1
                        }
                        draft.normalizePresetSortOrder()
                    }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .help("Pinned for Quick Log")
                .disabled(!draft.presets[index].isPinned && pinnedPresetCount >= 3)

                HStack(spacing: 6) {
                    if preset.isPinned {
                        Button {
                            movePinnedPreset(id: preset.id, up: true)
                        } label: {
                            Image(systemName: "arrow.up")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button {
                            movePinnedPreset(id: preset.id, up: false)
                        } label: {
                            Image(systemName: "arrow.down")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Button("Edit") {
                        startEditingPreset(index: index)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(role: .destructive) {
                        draft.presets.removeAll { $0.id == preset.id }
                        draft.normalizePresetSortOrder()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(10)
        .background(Color.themeSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func movePinnedPreset(id: String, up: Bool) {
        var pinned = draft.presets
            .filter { $0.isPinned && $0.isEnabled }
            .sorted { $0.sortOrder < $1.sortOrder }
        guard let index = pinned.firstIndex(where: { $0.id == id }) else { return }
        let destination = up ? index - 1 : index + 1
        guard destination >= 0, destination < pinned.count else { return }
        pinned.swapAt(index, destination)
        for (order, preset) in pinned.enumerated() {
            if let presetIndex = draft.presets.firstIndex(where: { $0.id == preset.id }) {
                draft.presets[presetIndex].sortOrder = order
            }
        }
        draft.normalizePresetSortOrder()
    }

    private func startAddingPreset() {
        editingPresetID = nil
        presetEditorDraft = FoodPreset(
            id: UUID().uuidString.lowercased(),
            title: "",
            mealSlot: .meal1,
            proteinGrams: 30,
            calories: 300,
            source: draft.defaultSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Custom" : draft.defaultSource,
            note: nil,
            isPinned: false,
            sortOrder: draft.presets.count,
            isEnabled: true
        )
        isPresetEditorPresented = true
    }

    private func startEditingPreset(index: Int) {
        editingPresetID = draft.presets[index].id
        presetEditorDraft = draft.presets[index]
        isPresetEditorPresented = true
    }

    private func savePresetFromEditor() {
        isPresetEditorPresented = false

        if let editingPresetID, let index = draft.presets.firstIndex(where: { $0.id == editingPresetID }) {
            draft.presets[index] = presetEditorDraft
        } else {
            draft.presets.append(presetEditorDraft)
        }

        draft.normalizePresetSortOrder()
    }

    private func resetDraft() {
        draft = model.profile
        draft.normalizePresetSortOrder()
    }
}

private struct PresetEditorSheet: View {
    @Binding var preset: FoodPreset
    let onSave: () -> Void
    let onCancel: () -> Void

    private var noteBinding: Binding<String> {
        Binding(
            get: { preset.note ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                preset.note = trimmed.isEmpty ? nil : trimmed
            }
        )
    }

    private var canSave: Bool {
        !preset.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !preset.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            preset.proteinGrams > 0 &&
            preset.calories > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Preset") {
                    TextField("Title", text: $preset.title)
                    Picker("Meal Slot", selection: $preset.mealSlot) {
                        ForEach(MealSlot.allCases) { slot in
                            Text(slot.title).tag(slot)
                        }
                    }
                    TextField("Source", text: $preset.source)
                }

                Section("Macros") {
                    Stepper("Protein: \(preset.proteinGrams)g", value: $preset.proteinGrams, in: 1...200, step: 1)
                    Stepper("Calories: \(preset.calories) kcal", value: $preset.calories, in: 1...2_500, step: 5)
                }

                Section("Flags") {
                    Toggle("Enabled", isOn: $preset.isEnabled)
                    Toggle("Pinned for Quick Log", isOn: $preset.isPinned)
                }

                Section("Notes") {
                    TextField("Optional note", text: noteBinding, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Preset")
            .frame(minWidth: 420, minHeight: 420)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(!canSave)
                }
            }
        }
    }
}
