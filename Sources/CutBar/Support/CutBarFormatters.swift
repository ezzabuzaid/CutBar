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
}
