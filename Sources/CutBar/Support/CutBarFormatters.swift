import Foundation

enum CutBarFormatters {
    static let dayKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let dayDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = .current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static func dayKey(for date: Date) -> String {
        dayKey.string(from: date)
    }

    static func displayDay(for key: String) -> String {
        guard let date = dayKey.date(from: key) else {
            return key
        }

        return dayDisplay.string(from: date)
    }

    static func clockTime(for minutes: Int) -> String {
        var calendar = Calendar.current
        calendar.timeZone = .current
        let boundedMinutes = max(0, min(23 * 60 + 59, minutes))
        let components = DateComponents(
            calendar: calendar,
            year: 2001,
            month: 1,
            day: 1,
            hour: boundedMinutes / 60,
            minute: boundedMinutes % 60
        )

        guard let date = calendar.date(from: components) else {
            return "--:--"
        }

        return time.string(from: date)
    }

    static func timeRangeText(startMinutes: Int, endMinutes: Int) -> String {
        "\(clockTime(for: startMinutes)) - \(clockTime(for: endMinutes))"
    }
}
