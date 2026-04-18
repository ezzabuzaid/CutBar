import Foundation

enum DayPhase: String, Codable, Hashable, Identifiable {
    case fasting
    case mealOneWindow
    case gymWindow
    case shakeWindow
    case mealTwoWindow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fasting:
            return "Clean fast"
        case .mealOneWindow:
            return "Meal 1 window"
        case .gymWindow:
            return "Gym block"
        case .shakeWindow:
            return "Shake window"
        case .mealTwoWindow:
            return "Meal 2 window"
        }
    }

    var detail: String {
        switch self {
        case .fasting:
            return "Water, black coffee, or black tea only until 5 PM."
        case .mealOneWindow:
            return "Front-load protein before training."
        case .gymWindow:
            return "Lift after Meal 1 and keep the intake light."
        case .shakeWindow:
            return "Recover with the 40g post-gym shake."
        case .mealTwoWindow:
            return "Finish the day with the biggest protein push."
        }
    }

    var menuBarLabel: String {
        switch self {
        case .fasting:
            return "Fast"
        case .mealOneWindow:
            return "Meal 1"
        case .gymWindow:
            return "Gym"
        case .shakeWindow:
            return "Shake"
        case .mealTwoWindow:
            return "Meal 2"
        }
    }

    var systemImage: String {
        switch self {
        case .fasting:
            return "moon.zzz"
        case .mealOneWindow:
            return "fork.knife"
        case .gymWindow:
            return "figure.strengthtraining.traditional"
        case .shakeWindow:
            return "dumbbell"
        case .mealTwoWindow:
            return "sunset"
        }
    }

    var suggestedSlot: MealSlot? {
        switch self {
        case .mealOneWindow:
            return .meal1
        case .shakeWindow:
            return .shake
        case .mealTwoWindow:
            return .meal2
        case .fasting, .gymWindow:
            return nil
        }
    }
}

struct MealTarget: Codable, Hashable {
    let calories: Int
    let proteinGrams: Int
}

struct DailyTargets: Codable, Hashable {
    let calories: Int
    let proteinGrams: Int
    let fatGrams: Int
    let carbGrams: Int
}

struct CutPlan: Codable, Hashable {
    let dailyTargets: DailyTargets
    let mealTargets: [MealSlot: MealTarget]
    let feedingWindowStartMinutes: Int
    let mealOneCutoffMinutes: Int
    let gymCutoffMinutes: Int
    let shakeCutoffMinutes: Int
    let feedingWindowEndMinutes: Int
    let defaultRestaurantBuffer: CalorieBuffer
    let rules: [String]
    let presetFoods: [FoodPreset]

    static let current = CutPlan(
        dailyTargets: DailyTargets(
            calories: 1850,
            proteinGrams: 175,
            fatGrams: 65,
            carbGrams: 140
        ),
        mealTargets: [
            .meal1: MealTarget(calories: 750, proteinGrams: 65),
            .shake: MealTarget(calories: 250, proteinGrams: 40),
            .meal2: MealTarget(calories: 850, proteinGrams: 70),
        ],
        feedingWindowStartMinutes: 17 * 60,
        mealOneCutoffMinutes: 18 * 60 + 30,
        gymCutoffMinutes: 20 * 60,
        shakeCutoffMinutes: 20 * 60 + 30,
        feedingWindowEndMinutes: 23 * 60,
        defaultRestaurantBuffer: .plus20,
        rules: [
            "FFR 18:6 window from 5 PM to 11 PM.",
            "Train after Meal 1 around 7 PM.",
            "Add 20-25% to restaurant calories to stay safe.",
            "Protein is non-negotiable in every feeding block.",
        ],
        presetFoods: [
            FoodPreset(
                id: "stay-healthy-combo",
                title: "Meal 1 Combo",
                mealSlot: .meal1,
                proteinGrams: 67,
                calories: 870,
                source: "Stay Healthy",
                note: "Adjusted combo from the repo log: zinger plus tuna."
            ),
            FoodPreset(
                id: "post-gym-shake",
                title: "Protein Shake",
                mealSlot: .shake,
                proteinGrams: 40,
                calories: 250,
                source: "Home",
                note: "Default post-gym shake target from the cut plan."
            ),
            FoodPreset(
                id: "stay-healthy-zinger",
                title: "Zinger Sandwich",
                mealSlot: .meal1,
                proteinGrams: 35,
                calories: 520,
                source: "Stay Healthy",
                note: "Conservative adjusted calories from the journal."
            ),
            FoodPreset(
                id: "stay-healthy-tuna",
                title: "Tuna Sandwich",
                mealSlot: .meal1,
                proteinGrams: 32,
                calories: 350,
                source: "Stay Healthy",
                note: "Conservative adjusted calories from the journal."
            ),
        ]
    )

    var fastingWindowText: String {
        "11:00 PM - 5:00 PM"
    }

    var feedingWindowText: String {
        "5:00 PM - 11:00 PM"
    }

    func target(for slot: MealSlot) -> MealTarget {
        mealTargets[slot] ?? MealTarget(calories: 0, proteinGrams: 0)
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
}
