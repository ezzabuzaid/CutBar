import Foundation

enum MealSlot: String, Codable, CaseIterable, Hashable, Identifiable {
    case meal1
    case shake
    case meal2

    var id: String { rawValue }

    var title: String {
        switch self {
        case .meal1:
            return "Meal 1"
        case .shake:
            return "Post-Gym Shake"
        case .meal2:
            return "Meal 2"
        }
    }

    var shortTitle: String {
        switch self {
        case .meal1:
            return "Meal 1"
        case .shake:
            return "Shake"
        case .meal2:
            return "Meal 2"
        }
    }

    var windowText: String {
        switch self {
        case .meal1:
            return "5:00 PM - 6:30 PM"
        case .shake:
            return "8:00 PM - 8:30 PM"
        case .meal2:
            return "8:30 PM - 11:00 PM"
        }
    }

    var systemImage: String {
        switch self {
        case .meal1:
            return "fork.knife.circle"
        case .shake:
            return "dumbbell"
        case .meal2:
            return "moon.stars"
        }
    }

    var sortIndex: Int {
        switch self {
        case .meal1:
            return 0
        case .shake:
            return 1
        case .meal2:
            return 2
        }
    }
}
