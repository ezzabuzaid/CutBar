import Foundation

enum CalorieBuffer: Double, Codable, CaseIterable, Hashable, Identifiable {
    case none = 0
    case plus20 = 0.20
    case plus25 = 0.25

    var id: Double { rawValue }

    var title: String {
        switch self {
        case .none:
            return "No safety buffer"
        case .plus20:
            return "Add 20% restaurant buffer"
        case .plus25:
            return "Add 25% restaurant buffer"
        }
    }

    var shortTitle: String {
        switch self {
        case .none:
            return "Exact"
        case .plus20:
            return "+20%"
        case .plus25:
            return "+25%"
        }
    }

    func apply(to calories: Int) -> Int {
        Int((Double(calories) * (1 + rawValue)).rounded())
    }
}
