import Foundation
import SQLite3
import XCTest
@testable import CutBar

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class CutBarPersistenceTests: XCTestCase {
    @MainActor
    func testProfileTablesAreSeededOnFirstLaunch() {
        let appDirectory = makeTempAppDirectory()
        let store = FoodLogStore(appDirectory: appDirectory)
        let model = CutBarModel(store: store)

        XCTAssertNil(model.storageIssue)
        XCTAssertFalse(model.profile.presets.isEmpty)
        XCTAssertEqual(model.quickPresets.count, 3)
        XCTAssertTrue(tableExists(name: "profile", databaseURL: URL(fileURLWithPath: store.path)))
        XCTAssertTrue(tableExists(name: "profile_presets", databaseURL: URL(fileURLWithPath: store.path)))
    }

    @MainActor
    func testLegacyDatabaseWithoutProfileTablesMigratesAndSeedsProfile() throws {
        let appDirectory = makeTempAppDirectory()
        let store = FoodLogStore(appDirectory: appDirectory)
        let databaseURL = URL(fileURLWithPath: store.path)
        try createLegacyEntriesOnlyDatabase(databaseURL: databaseURL)

        let model = CutBarModel(store: store)

        XCTAssertNil(model.storageIssue)
        XCTAssertEqual(model.todayEntries.count, 1)
        XCTAssertFalse(model.profile.presets.isEmpty)
        XCTAssertTrue(tableExists(name: "profile", databaseURL: databaseURL))
        XCTAssertTrue(tableExists(name: "profile_presets", databaseURL: databaseURL))
    }

    @MainActor
    func testProfileRoundTripPersistsTargetsAndPinnedPresetOrder() {
        let appDirectory = makeTempAppDirectory()
        let store = FoodLogStore(appDirectory: appDirectory)

        switch store.update({ document in
            var profile = document.profile
            profile.dailyTargets = DailyTargets(calories: 2100, proteinGrams: 180, fatGrams: 70, carbGrams: 160)
            profile.defaultSource = "Office"
            profile.defaultRestaurantBuffer = .plus25
            profile.presets = [
                FoodPreset(id: "first", title: "First", mealSlot: .meal1, proteinGrams: 40, calories: 500, source: "Custom", note: nil, isPinned: true, sortOrder: 1, isEnabled: true),
                FoodPreset(id: "second", title: "Second", mealSlot: .shake, proteinGrams: 35, calories: 250, source: "Custom", note: nil, isPinned: true, sortOrder: 0, isEnabled: true),
                FoodPreset(id: "off", title: "Off", mealSlot: .meal2, proteinGrams: 25, calories: 300, source: "Custom", note: nil, isPinned: false, sortOrder: 2, isEnabled: false),
            ]
            document.profile = profile
        }) {
        case .success:
            break
        case let .failure(error):
            XCTFail("Failed to update profile: \(error.userFacingMessage)")
        }

        switch store.load() {
        case let .success(document):
            XCTAssertEqual(document.profile.dailyTargets.calories, 2100)
            XCTAssertEqual(document.profile.defaultSource, "Office")
            XCTAssertEqual(document.profile.defaultRestaurantBuffer, .plus25)
            XCTAssertEqual(document.profile.quickPinnedPresets.map(\.id), ["second", "first"])
            XCTAssertEqual(document.profile.presets.first(where: { $0.id == "off" })?.isEnabled, false)
        case let .failure(error):
            XCTFail("Failed to reload profile: \(error.userFacingMessage)")
        }
    }

    @MainActor
    func testModelDisablesWritesWhenDatabaseIsUnreadable() throws {
        let appDirectory = makeTempAppDirectory()
        let store = FoodLogStore(appDirectory: appDirectory)
        let databaseURL = URL(fileURLWithPath: store.path)
        try Data("not-a-sqlite-database".utf8).write(to: databaseURL)
        let model = CutBarModel(store: store)

        XCTAssertNotNil(model.storageIssue)
        XCTAssertFalse(model.canMutateStorage)

        model.logPreset(
            FoodPreset(
                id: "shake",
                title: "Protein Shake",
                mealSlot: .shake,
                proteinGrams: 40,
                calories: 250,
                source: "Home",
                note: nil
            )
        )

        let contents = try Data(contentsOf: databaseURL)
        XCTAssertEqual(contents, Data("not-a-sqlite-database".utf8))
    }

    @MainActor
    func testLocalSavePreservesEntriesAddedAfterLaunch() throws {
        let appDirectory = makeTempAppDirectory()
        let store = FoodLogStore(appDirectory: appDirectory)
        let now = Date.now
        let dayKey = CutBarFormatters.dayKey(for: now)

        let breakfast = FoodEntry(
            title: "Breakfast",
            mealSlot: .meal1,
            proteinGrams: 30,
            calories: 400,
            baseCalories: 400,
            calorieBuffer: .none,
            loggedAt: now.addingTimeInterval(-600),
            source: "Home"
        )

        switch store.save(
            FoodLogDocument(
                logs: [DayLog(id: dayKey, entries: [breakfast])],
                lastUpdatedAt: now
            )
        ) {
        case .success:
            break
        case let .failure(error):
            XCTFail("Failed to seed store: \(error.userFacingMessage)")
        }

        let model = CutBarModel(store: store)

        let externalLunch = FoodEntry(
            title: "External Lunch",
            mealSlot: .meal2,
            proteinGrams: 45,
            calories: 650,
            baseCalories: 650,
            calorieBuffer: .none,
            loggedAt: now.addingTimeInterval(-300),
            source: "Service"
        )

        switch store.update({ document in
            document.logs[0].entries.append(externalLunch)
        }) {
        case .success:
            break
        case let .failure(error):
            XCTFail("Failed to simulate external write: \(error.userFacingMessage)")
        }

        model.logPreset(
            FoodPreset(
                id: "shake",
                title: "Protein Shake",
                mealSlot: .shake,
                proteinGrams: 40,
                calories: 250,
                source: "Home",
                note: nil
            )
        )

        switch store.load() {
        case let .success(document):
            let titles = Set(
                document.logs
                    .first(where: { $0.id == dayKey })?
                    .entries
                    .map(\.title) ?? []
            )

            XCTAssertEqual(
                titles,
                ["Breakfast", "External Lunch", "Protein Shake"]
            )
        case let .failure(error):
            XCTFail("Failed to reload store: \(error.userFacingMessage)")
        }
    }

    @MainActor
    func testModelLoadsLegacyLocalTimestampWithoutTimezone() throws {
        let appDirectory = makeTempAppDirectory()
        let store = FoodLogStore(appDirectory: appDirectory)
        let now = Date.now
        let dayKey = CutBarFormatters.dayKey(for: now)

        let legacyEntry = FoodEntry(
            title: "Legacy Entry",
            mealSlot: .meal1,
            proteinGrams: 32,
            calories: 420,
            baseCalories: 420,
            calorieBuffer: .none,
            loggedAt: now,
            source: "Home"
        )

        switch store.save(
            FoodLogDocument(
                logs: [DayLog(id: dayKey, entries: [legacyEntry])],
                lastUpdatedAt: now
            )
        ) {
        case .success:
            break
        case let .failure(error):
            XCTFail("Failed to seed store: \(error.userFacingMessage)")
        }

        try overwriteLoggedAt(
            value: makeLegacyLocalTimestamp(from: now),
            databaseURL: URL(fileURLWithPath: store.path)
        )

        let model = CutBarModel(store: store)

        XCTAssertNil(model.storageIssue)
        XCTAssertTrue(model.canMutateStorage)
        XCTAssertEqual(model.document.logs.flatMap(\.entries).count, 1)
        XCTAssertEqual(model.document.logs.first?.entries.first?.title, "Legacy Entry")
    }

    @MainActor
    func testRefreshClockUpdatesCurrentPhase() throws {
        let model = CutBarModel(store: FoodLogStore(appDirectory: makeTempAppDirectory()))
        let fastingFixture = makeLocalDate(hour: 16, minute: 30)
        let mealTwoFixture = makeLocalDate(hour: 21, minute: 5)

        model.refreshClock(now: fastingFixture)
        XCTAssertEqual(model.currentPhase, .fasting)

        model.refreshClock(now: mealTwoFixture)
        XCTAssertEqual(model.currentPhase, .mealTwoWindow)
    }

    @MainActor
    func testSQLiteRejectsMalformedLoggedAtValues() throws {
        let appDirectory = makeTempAppDirectory()
        let store = FoodLogStore(appDirectory: appDirectory)
        let now = Date.now
        let dayKey = CutBarFormatters.dayKey(for: now)

        let entry = FoodEntry(
            title: "Validation Probe",
            mealSlot: .meal1,
            proteinGrams: 25,
            calories: 350,
            baseCalories: 350,
            calorieBuffer: .none,
            loggedAt: now,
            source: "Home"
        )

        switch store.save(
            FoodLogDocument(
                logs: [DayLog(id: dayKey, entries: [entry])],
                lastUpdatedAt: now
            )
        ) {
        case .success:
            break
        case let .failure(error):
            XCTFail("Failed to seed store: \(error.userFacingMessage)")
        }

        XCTAssertThrowsError(
            try overwriteLoggedAt(
                value: "totally-not-a-date",
                databaseURL: URL(fileURLWithPath: store.path)
            )
        )
    }

    @MainActor
    func testSQLiteRejectsDomainViolationsForDirectSQLWrites() throws {
        let appDirectory = makeTempAppDirectory()
        let store = FoodLogStore(appDirectory: appDirectory)
        let now = Date.now
        let dayKey = CutBarFormatters.dayKey(for: now)
        let databaseURL = URL(fileURLWithPath: store.path)

        let entry = FoodEntry(
            title: "Constraint Probe",
            mealSlot: .meal1,
            proteinGrams: 30,
            calories: 420,
            baseCalories: 420,
            calorieBuffer: .none,
            loggedAt: now,
            source: "Home"
        )

        switch store.save(
            FoodLogDocument(
                logs: [DayLog(id: dayKey, entries: [entry])],
                lastUpdatedAt: now
            )
        ) {
        case .success:
            break
        case let .failure(error):
            XCTFail("Failed to seed store: \(error.userFacingMessage)")
        }

        XCTAssertThrowsError(
            try overwriteInt(
                sql: "UPDATE entries SET calories = ?;",
                value: 421,
                databaseURL: databaseURL
            )
        )

        XCTAssertThrowsError(
            try overwriteText(
                sql: "UPDATE entries SET meal_slot = ?;",
                value: "snack",
                databaseURL: databaseURL
            )
        )

        XCTAssertThrowsError(
            try overwriteText(
                sql: "UPDATE entries SET day_key = ?;",
                value: "1999-01-01",
                databaseURL: databaseURL
            )
        )
    }

    @MainActor
    func testSQLiteRejectsInvalidProfileWindowOrderingForDirectSQLWrites() throws {
        let appDirectory = makeTempAppDirectory()
        let store = FoodLogStore(appDirectory: appDirectory)
        _ = CutBarModel(store: store)
        let databaseURL = URL(fileURLWithPath: store.path)

        XCTAssertThrowsError(
            try overwriteInt(
                sql: "UPDATE profile SET shake_start_minutes = ?;",
                value: 100,
                databaseURL: databaseURL
            )
        )
    }

    private func makeTempAppDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeLocalDate(hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        return calendar.date(
            from: DateComponents(
                calendar: calendar,
                year: 2026,
                month: 4,
                day: 17,
                hour: hour,
                minute: minute
            )
        )!
    }

    private func makeLegacyLocalTimestamp(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.string(from: date)
    }

    private func overwriteLoggedAt(value: String, databaseURL: URL) throws {
        try overwriteText(
            sql: "UPDATE entries SET logged_at = ?;",
            value: value,
            databaseURL: databaseURL
        )
    }

    private func overwriteText(sql: String, value: String, databaseURL: URL) throws {
        try withWritableConnection(databaseURL: databaseURL) { connection in
            var statement: OpaquePointer?
            let statementResult = sqlite3_prepare_v2(
                connection,
                sql,
                -1,
                &statement,
                nil
            )
            guard statementResult == SQLITE_OK else {
                throw sqliteError(connection, fallback: "Unable to prepare SQLite update statement.")
            }

            defer {
                sqlite3_finalize(statement)
            }

            guard sqlite3_bind_text(statement, 1, value, -1, sqliteTransient) == SQLITE_OK else {
                throw sqliteError(connection, fallback: "Unable to bind SQLite text value.")
            }

            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw sqliteError(connection, fallback: "Unable to write SQLite text value.")
            }
        }
    }

    private func overwriteInt(sql: String, value: Int, databaseURL: URL) throws {
        try withWritableConnection(databaseURL: databaseURL) { connection in
            var statement: OpaquePointer?
            let statementResult = sqlite3_prepare_v2(
                connection,
                sql,
                -1,
                &statement,
                nil
            )
            guard statementResult == SQLITE_OK else {
                throw sqliteError(connection, fallback: "Unable to prepare SQLite update statement.")
            }

            defer {
                sqlite3_finalize(statement)
            }

            guard sqlite3_bind_int64(statement, 1, sqlite3_int64(value)) == SQLITE_OK else {
                throw sqliteError(connection, fallback: "Unable to bind SQLite integer value.")
            }

            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw sqliteError(connection, fallback: "Unable to write SQLite integer value.")
            }
        }
    }

    private func withWritableConnection(
        databaseURL: URL,
        _ body: (OpaquePointer) throws -> Void
    ) throws {
        var connection: OpaquePointer?
        let openResult = sqlite3_open_v2(
            databaseURL.path,
            &connection,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        )
        guard openResult == SQLITE_OK else {
            defer {
                if let connection {
                    sqlite3_close(connection)
                }
            }
            throw sqliteError(connection, fallback: "Unable to open SQLite database.")
        }

        guard let connection else {
            throw NSError(
                domain: "CutBarTests.SQLite",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to open SQLite database."]
            )
        }

        defer {
            sqlite3_close(connection)
        }
        try body(connection)
    }

    private func sqliteError(_ connection: OpaquePointer?, fallback: String) -> NSError {
        let message: String
        if let connection, let rawMessage = sqlite3_errmsg(connection) {
            message = String(cString: rawMessage)
        } else {
            message = fallback
        }

        return NSError(
            domain: "CutBarTests.SQLite",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    private func createLegacyEntriesOnlyDatabase(databaseURL: URL) throws {
        var connection: OpaquePointer?
        let openResult = sqlite3_open_v2(
            databaseURL.path,
            &connection,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        )
        guard openResult == SQLITE_OK, let connection else {
            throw NSError(
                domain: "CutBarTests.SQLite",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to create legacy SQLite database."]
            )
        }

        defer {
            sqlite3_close(connection)
        }

        let createSQL = """
            CREATE TABLE entries (
              id TEXT PRIMARY KEY,
              day_key TEXT NOT NULL,
              logged_at TEXT NOT NULL,
              meal_slot TEXT NOT NULL,
              title TEXT NOT NULL,
              protein_grams INTEGER NOT NULL,
              calories INTEGER NOT NULL,
              base_calories INTEGER NOT NULL,
              calorie_buffer REAL NOT NULL,
              source TEXT NOT NULL,
              note TEXT
            );
            """

        guard sqlite3_exec(connection, createSQL, nil, nil, nil) == SQLITE_OK else {
            throw sqliteError(connection, fallback: "Unable to create legacy entries table.")
        }

        let now = Date.now
        let insert = """
            INSERT INTO entries (
              id,
              day_key,
              logged_at,
              meal_slot,
              title,
              protein_grams,
              calories,
              base_calories,
              calorie_buffer,
              source,
              note
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL);
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection, insert, -1, &statement, nil) == SQLITE_OK else {
            throw sqliteError(connection, fallback: "Unable to prepare legacy insert statement.")
        }

        defer {
            sqlite3_finalize(statement)
        }

        let loggedAt = now.ISO8601Format()
        let dayKey = String(loggedAt.prefix(10))
        guard sqlite3_bind_text(statement, 1, UUID().uuidString, -1, sqliteTransient) == SQLITE_OK,
              sqlite3_bind_text(statement, 2, dayKey, -1, sqliteTransient) == SQLITE_OK,
              sqlite3_bind_text(statement, 3, loggedAt, -1, sqliteTransient) == SQLITE_OK,
              sqlite3_bind_text(statement, 4, "meal1", -1, sqliteTransient) == SQLITE_OK,
              sqlite3_bind_text(statement, 5, "Legacy Meal", -1, sqliteTransient) == SQLITE_OK,
              sqlite3_bind_int(statement, 6, 30) == SQLITE_OK,
              sqlite3_bind_int(statement, 7, 400) == SQLITE_OK,
              sqlite3_bind_int(statement, 8, 400) == SQLITE_OK,
              sqlite3_bind_double(statement, 9, 0.0) == SQLITE_OK,
              sqlite3_bind_text(statement, 10, "Home", -1, sqliteTransient) == SQLITE_OK
        else {
            throw sqliteError(connection, fallback: "Unable to bind legacy row.")
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw sqliteError(connection, fallback: "Unable to insert legacy row.")
        }
    }

    private func tableExists(name: String, databaseURL: URL) -> Bool {
        do {
            var exists = false
            try withWritableConnection(databaseURL: databaseURL) { connection in
                let query = """
                    SELECT 1
                    FROM sqlite_master
                    WHERE type = 'table'
                      AND name = ?
                    LIMIT 1
                    """

                var statement: OpaquePointer?
                guard sqlite3_prepare_v2(connection, query, -1, &statement, nil) == SQLITE_OK else {
                    throw sqliteError(connection, fallback: "Unable to query sqlite_master.")
                }

                defer {
                    sqlite3_finalize(statement)
                }

                guard sqlite3_bind_text(statement, 1, name, -1, sqliteTransient) == SQLITE_OK else {
                    throw sqliteError(connection, fallback: "Unable to bind table name.")
                }

                exists = sqlite3_step(statement) == SQLITE_ROW
            }
            return exists
        } catch {
            return false
        }
    }
}
