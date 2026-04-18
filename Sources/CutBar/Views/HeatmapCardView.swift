import SwiftUI

struct HeatmapCardView: View {
    let model: CutBarModel

    private static let columns = 7
    private static let cellSpacing: CGFloat = 4

    private var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: Self.cellSpacing),
            count: Self.columns
        )
    }

    var body: some View {
        let days = model.heatmapDays
        let leadingPlaceholders = leadingPlaceholderCount(for: days)

        VStack(alignment: .leading, spacing: 14) {
            header

            weekdayHeader

            LazyVGrid(columns: gridColumns, spacing: Self.cellSpacing) {
                ForEach(0..<leadingPlaceholders, id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }

                ForEach(days) { day in
                    HeatmapCell(
                        day: day,
                        isToday: day.dayKey == model.todayKey,
                        isSelected: day.dayKey == model.selectedDayKey,
                        onTap: { model.selectDay(day.dayKey) }
                    )
                }
            }

            legend
        }
        .padding(16)
        .background(Color.themeCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Last 30 days")
                    .font(.appHeadline)
                Text("Protein goal consistency")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.themeAccent)
                Text("\(model.currentStreak)")
                    .font(.appHeadline.monospacedDigit())
                Text(model.currentStreak == 1 ? "day" : "days")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.themeSurface)
            )
            .accessibilityLabel("Streak: \(model.currentStreak) days")
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: Self.cellSpacing) {
            ForEach(Self.weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.appCaption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 6) {
            Text("<50%")
                .font(.appCaption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                ForEach(HeatmapBucket.filledRamp, id: \.self) { bucket in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(bucket.fill)
                        .frame(width: 10, height: 10)
                }
            }

            Text("≥100%")
                .font(.appCaption2)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private func leadingPlaceholderCount(for days: [HeatmapDay]) -> Int {
        guard let first = days.first else { return 0 }
        // Monday = 0, Tuesday = 1, ..., Sunday = 6
        let weekday = Calendar.current.component(.weekday, from: first.date)
        // Calendar weekday: Sunday = 1, Monday = 2, ..., Saturday = 7
        return (weekday + 5) % 7
    }

    private static let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]
}

private enum HeatmapBucket: Hashable {
    case empty
    case low
    case mid
    case high
    case goal

    static let filledRamp: [HeatmapBucket] = [.low, .mid, .high, .goal]

    static func bucket(for day: HeatmapDay) -> HeatmapBucket {
        guard day.hasEntries else { return .empty }
        switch day.proteinProgress {
        case ..<0.5: return .low
        case ..<0.8: return .mid
        case ..<1.0: return .high
        default: return .goal
        }
    }

    var fill: Color {
        switch self {
        case .empty: return .clear
        case .low: return Color.themeAccent.opacity(0.20)
        case .mid: return Color.themeAccent.opacity(0.45)
        case .high: return Color.themeAccent.opacity(0.70)
        case .goal: return Color.themeAccent
        }
    }

    var strokeColor: Color {
        switch self {
        case .empty: return Color.themeInk.opacity(0.2)
        default: return .clear
        }
    }
}

private struct HeatmapCell: View {
    let day: HeatmapDay
    let isToday: Bool
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        let bucket = HeatmapBucket.bucket(for: day)

        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(bucket.fill)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(bucket.strokeColor, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.themeInk, lineWidth: isToday ? 1 : 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.primary, lineWidth: isSelected ? 2 : 0)
            )
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(isHovered ? 1.08 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .onTapGesture { onTap() }
            .help(tooltip)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }

    private var tooltip: String {
        let dateLabel = CutBarFormatters.displayDay(for: day.dayKey)

        guard let totals = day.totals else {
            return "\(dateLabel) · No entries"
        }

        return "\(dateLabel) · \(totals.proteinGrams)g · \(totals.calories) kcal"
    }

    private var accessibilityLabel: String {
        tooltip + (isToday ? " (today)" : "")
    }
}
