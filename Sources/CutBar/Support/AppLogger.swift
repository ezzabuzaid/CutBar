import os

enum AppLogger {
    static let lifecycle = Logger(
        subsystem: "com.ezz.study.CutBar",
        category: "lifecycle"
    )
    static let storage = Logger(
        subsystem: "com.ezz.study.CutBar",
        category: "storage"
    )
    static let actions = Logger(
        subsystem: "com.ezz.study.CutBar",
        category: "actions"
    )
}
