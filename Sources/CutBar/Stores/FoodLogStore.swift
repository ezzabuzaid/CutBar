import Foundation
import SQLite3

enum FoodLogStoreError: LocalizedError {
    case unreadableDatabase(path: String, reason: String)
    case failedToWriteDatabase(path: String, reason: String)

    var errorDescription: String? {
        switch self {
        case let .unreadableDatabase(path, reason):
            return "CutBar could not read its food log database at \(path): \(reason)"
        case let .failedToWriteDatabase(path, reason):
            return "CutBar could not save its food log database at \(path): \(reason)"
        }
    }

    var userFacingMessage: String {
        errorDescription ?? "CutBar encountered a storage error."
    }
}

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

struct FoodLogStore {
    private let fileManager = FileManager.default
    private let appDirectoryOverride: URL?

    init(appDirectory: URL? = nil) {
        appDirectoryOverride = appDirectory
    }

    private var appDirectory: URL {
        if let appDirectoryOverride {
            if !fileManager.fileExists(atPath: appDirectoryOverride.path) {
                try? fileManager.createDirectory(
                    at: appDirectoryOverride,
                    withIntermediateDirectories: true
                )
            }

            return appDirectoryOverride
        }

        let supportDirectory = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let appDirectory = (supportDirectory ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("CutBar", isDirectory: true)

        if !fileManager.fileExists(atPath: appDirectory.path) {
            try? fileManager.createDirectory(
                at: appDirectory,
                withIntermediateDirectories: true
            )
        }

        return appDirectory
    }

    private var databaseURL: URL {
        appDirectory.appendingPathComponent("food-log.sqlite")
    }

    var path: String {
        databaseURL.path
    }

    func load() -> Result<FoodLogDocument, FoodLogStoreError> {
        do {
            return .success(try withConnection(readOnly: false) { connection in
                try ensureSchema(in: connection)
                return try loadDocument(from: connection)
            })
        } catch {
            AppLogger.storage.error(
                "Failed to read food log database: \(error.localizedDescription, privacy: .public)"
            )
            return .failure(
                .unreadableDatabase(
                    path: databaseURL.path,
                    reason: error.localizedDescription
                )
            )
        }
    }

    func update(
        _ transform: (inout FoodLogDocument) -> Void
    ) -> Result<FoodLogDocument, FoodLogStoreError> {
        do {
            return .success(try withConnection(readOnly: false) { connection in
                try ensureSchema(in: connection)
                try beginImmediateTransaction(in: connection)
                do {
                    var document = try loadDocument(from: connection)
                    transform(&document)
                    document.lastUpdatedAt = .now
                    document.logs.sort { $0.id < $1.id }
                    try replaceEntries(in: connection, with: document)
                    try commitTransaction(in: connection)
                    return document
                } catch {
                    try? rollbackTransaction(in: connection)
                    throw error
                }
            })
        } catch {
            AppLogger.storage.error(
                "Failed to update food log database: \(error.localizedDescription, privacy: .public)"
            )
            return .failure(
                .failedToWriteDatabase(
                    path: databaseURL.path,
                    reason: error.localizedDescription
                )
            )
        }
    }

    func save(
        _ document: FoodLogDocument
    ) -> Result<FoodLogDocument, FoodLogStoreError> {
        do {
            return .success(try withConnection(readOnly: false) { connection in
                try ensureSchema(in: connection)
                try beginImmediateTransaction(in: connection)
                do {
                    var documentToSave = document
                    documentToSave.lastUpdatedAt = .now
                    documentToSave.logs.sort { $0.id < $1.id }
                    try replaceEntries(in: connection, with: documentToSave)
                    try commitTransaction(in: connection)
                    return documentToSave
                } catch {
                    try? rollbackTransaction(in: connection)
                    throw error
                }
            })
        } catch {
            AppLogger.storage.error(
                "Failed to save food log database: \(error.localizedDescription, privacy: .public)"
            )
            return .failure(
                .failedToWriteDatabase(
                    path: databaseURL.path,
                    reason: error.localizedDescription
                )
            )
        }
    }

    private func withConnection<T>(
        readOnly: Bool,
        _ body: (OpaquePointer) throws -> T
    ) throws -> T {
        let flags = readOnly
            ? SQLITE_OPEN_READONLY
            : SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX

        var connection: OpaquePointer?
        let result = sqlite3_open_v2(databaseURL.path, &connection, flags, nil)

        guard result == SQLITE_OK, let connection else {
            defer {
                if let connection {
                    sqlite3_close(connection)
                }
            }
            throw SQLiteStoreFailure(message: sqliteErrorMessage(for: connection))
        }

        defer {
            sqlite3_close(connection)
        }

        return try body(connection)
    }

    private func ensureSchema(in connection: OpaquePointer) throws {
        try execute(
            """
            PRAGMA journal_mode = WAL;
            CREATE TABLE IF NOT EXISTS entries (
              id TEXT PRIMARY KEY CHECK (
                length(id) = 36
                AND substr(id, 9, 1) = '-'
                AND substr(id, 14, 1) = '-'
                AND substr(id, 19, 1) = '-'
                AND substr(id, 24, 1) = '-'
              ),
              day_key TEXT NOT NULL CHECK (
                day_key LIKE '____-__-__'
                AND date(day_key) IS NOT NULL
              ),
              logged_at TEXT NOT NULL CHECK (
                logged_at LIKE '____-__-__T__:__:__%'
                AND (
                  julianday(logged_at) IS NOT NULL
                  OR julianday(substr(logged_at, 1, 19)) IS NOT NULL
                )
              ),
              meal_slot TEXT NOT NULL CHECK (
                meal_slot IN ('meal1', 'shake', 'meal2')
              ),
              title TEXT NOT NULL CHECK (
                length(trim(title)) > 0
              ),
              protein_grams INTEGER NOT NULL CHECK (
                protein_grams > 0
              ),
              calories INTEGER NOT NULL CHECK (
                calories > 0
              ),
              base_calories INTEGER NOT NULL CHECK (
                base_calories > 0
              ),
              calorie_buffer REAL NOT NULL CHECK (
                calorie_buffer IN (0.0, 0.2, 0.25)
              ),
              source TEXT NOT NULL DEFAULT 'Custom' CHECK (
                length(trim(source)) > 0
              ),
              note TEXT CHECK (
                note IS NULL OR length(trim(note)) > 0
              ),
              CHECK (
                day_key = substr(logged_at, 1, 10)
              ),
              CHECK (
                calories = CAST(ROUND(base_calories * (1 + calorie_buffer), 0) AS INTEGER)
              )
            );
            """,
            in: connection
        )

        try ensureEntriesTableConstraints(in: connection)

        try execute(
            """
            CREATE INDEX IF NOT EXISTS idx_entries_day_logged_at
              ON entries(day_key, logged_at);
            CREATE VIEW IF NOT EXISTS cutbar_day_totals AS
            SELECT
              day_key,
              SUM(protein_grams) AS protein_grams,
              SUM(calories) AS calories,
              COUNT(*) AS entry_count
            FROM entries
            GROUP BY day_key
            ORDER BY day_key ASC;
            CREATE VIEW IF NOT EXISTS cutbar_slot_totals AS
            SELECT
              day_key,
              meal_slot,
              SUM(protein_grams) AS protein_grams,
              SUM(calories) AS calories,
              COUNT(*) AS entry_count
            FROM entries
            GROUP BY day_key, meal_slot
            ORDER BY day_key ASC,
                     CASE meal_slot
                       WHEN 'meal1' THEN 0
                       WHEN 'shake' THEN 1
                       WHEN 'meal2' THEN 2
                     END ASC;
            CREATE VIEW IF NOT EXISTS cutbar_entries_read_model AS
            SELECT
              id,
              day_key,
              logged_at,
              meal_slot,
              CASE meal_slot
                WHEN 'meal1' THEN 0
                WHEN 'shake' THEN 1
                WHEN 'meal2' THEN 2
              END AS meal_slot_sort,
              title,
              protein_grams,
              calories,
              base_calories,
              calorie_buffer,
              source,
              note
            FROM entries
            ORDER BY logged_at ASC;
            DROP TRIGGER IF EXISTS entries_validate_logged_at_insert;
            DROP TRIGGER IF EXISTS entries_validate_logged_at_update;
            """,
            in: connection
        )
    }

    private func ensureEntriesTableConstraints(in connection: OpaquePointer) throws {
        if try entriesTableHasCurrentConstraints(in: connection) {
            return
        }

        try beginImmediateTransaction(in: connection)
        do {
            try execute(
                """
                CREATE TABLE entries_new (
                  id TEXT PRIMARY KEY CHECK (
                    length(id) = 36
                    AND substr(id, 9, 1) = '-'
                    AND substr(id, 14, 1) = '-'
                    AND substr(id, 19, 1) = '-'
                    AND substr(id, 24, 1) = '-'
                  ),
                  day_key TEXT NOT NULL CHECK (
                    day_key LIKE '____-__-__'
                    AND date(day_key) IS NOT NULL
                  ),
                  logged_at TEXT NOT NULL CHECK (
                    logged_at LIKE '____-__-__T__:__:__%'
                    AND (
                      julianday(logged_at) IS NOT NULL
                      OR julianday(substr(logged_at, 1, 19)) IS NOT NULL
                    )
                  ),
                  meal_slot TEXT NOT NULL CHECK (
                    meal_slot IN ('meal1', 'shake', 'meal2')
                  ),
                  title TEXT NOT NULL CHECK (
                    length(trim(title)) > 0
                  ),
                  protein_grams INTEGER NOT NULL CHECK (
                    protein_grams > 0
                  ),
                  calories INTEGER NOT NULL CHECK (
                    calories > 0
                  ),
                  base_calories INTEGER NOT NULL CHECK (
                    base_calories > 0
                  ),
                  calorie_buffer REAL NOT NULL CHECK (
                    calorie_buffer IN (0.0, 0.2, 0.25)
                  ),
                  source TEXT NOT NULL DEFAULT 'Custom' CHECK (
                    length(trim(source)) > 0
                  ),
                  note TEXT CHECK (
                    note IS NULL OR length(trim(note)) > 0
                  ),
                  CHECK (
                    day_key = substr(logged_at, 1, 10)
                  ),
                  CHECK (
                    calories = CAST(ROUND(base_calories * (1 + calorie_buffer), 0) AS INTEGER)
                  )
                );
                INSERT INTO entries_new (
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
                )
                SELECT
                  id,
                  substr(logged_at, 1, 10) AS day_key,
                  logged_at,
                  meal_slot,
                  trim(title) AS title,
                  protein_grams,
                  CAST(ROUND(base_calories * (1 + calorie_buffer), 0) AS INTEGER) AS calories,
                  base_calories,
                  calorie_buffer,
                  CASE
                    WHEN length(trim(source)) = 0 THEN 'Custom'
                    ELSE trim(source)
                  END AS source,
                  NULLIF(trim(note), '') AS note
                FROM entries;
                DROP TABLE entries;
                ALTER TABLE entries_new RENAME TO entries;
                """,
                in: connection
            )

            try commitTransaction(in: connection)
        } catch {
            try? rollbackTransaction(in: connection)
            throw error
        }
    }

    private func entriesTableHasCurrentConstraints(in connection: OpaquePointer) throws -> Bool {
        let query = """
            SELECT sql
            FROM sqlite_master
            WHERE type = 'table'
              AND name = 'entries'
            LIMIT 1
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection, query, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteStoreFailure(message: sqliteErrorMessage(for: connection))
        }

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            return false
        }

        guard let sqlText = sqlite3_column_text(statement, 0) else {
            return false
        }

        let createSQL = String(cString: sqlText).lowercased()
        let requiredSnippets = [
            "logged_at text not null check",
            "meal_slot in ('meal1', 'shake', 'meal2')",
            "calorie_buffer in (0.0, 0.2, 0.25)",
            "length(trim(title)) > 0",
            "length(trim(source)) > 0",
            "note is null or length(trim(note)) > 0",
            "day_key = substr(logged_at, 1, 10)",
            "calories = cast(round(base_calories * (1 + calorie_buffer), 0) as integer)",
        ]
        return requiredSnippets.allSatisfy { createSQL.contains($0) }
    }

    private func beginImmediateTransaction(in connection: OpaquePointer) throws {
        try execute("BEGIN IMMEDIATE TRANSACTION;", in: connection)
    }

    private func commitTransaction(in connection: OpaquePointer) throws {
        try execute("COMMIT;", in: connection)
    }

    private func rollbackTransaction(in connection: OpaquePointer) throws {
        try execute("ROLLBACK;", in: connection)
    }

    private func loadDocument(from connection: OpaquePointer) throws -> FoodLogDocument {
        let query = """
            SELECT
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
            FROM entries
            ORDER BY logged_at ASC
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection, query, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteStoreFailure(message: sqliteErrorMessage(for: connection))
        }

        defer {
            sqlite3_finalize(statement)
        }

        var groupedEntries: [String: [FoodEntry]] = [:]
        var dayOrder: [String] = []
        var lastLoggedAt: Date?

        while sqlite3_step(statement) == SQLITE_ROW {
            let dayKey = try readString(column: 1, from: statement)
            let loggedAt = try parseDate(try readString(column: 2, from: statement))
            let mealSlot = try parseMealSlot(try readString(column: 3, from: statement))
            let calorieBuffer = try parseCalorieBuffer(sqlite3_column_double(statement, 8))
            let entryID = try parseUUID(try readString(column: 0, from: statement))

            let entry = FoodEntry(
                id: entryID,
                title: try readString(column: 4, from: statement),
                mealSlot: mealSlot,
                proteinGrams: Int(sqlite3_column_int(statement, 5)),
                calories: Int(sqlite3_column_int(statement, 6)),
                baseCalories: Int(sqlite3_column_int(statement, 7)),
                calorieBuffer: calorieBuffer,
                loggedAt: loggedAt,
                source: try readString(column: 9, from: statement),
                note: readOptionalString(column: 10, from: statement)
            )

            if groupedEntries[dayKey] == nil {
                dayOrder.append(dayKey)
                groupedEntries[dayKey] = []
            }
            groupedEntries[dayKey]?.append(entry)
            lastLoggedAt = loggedAt
        }

        let logs = dayOrder.compactMap { dayKey in
            groupedEntries[dayKey].map { DayLog(id: dayKey, entries: $0) }
        }

        return FoodLogDocument(
            logs: logs,
            lastUpdatedAt: lastLoggedAt ?? .now
        )
    }

    private func replaceEntries(
        in connection: OpaquePointer,
        with document: FoodLogDocument
    ) throws {
        try execute("DELETE FROM entries;", in: connection)

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
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection, insert, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteStoreFailure(message: sqliteErrorMessage(for: connection))
        }

        defer {
            sqlite3_finalize(statement)
        }

        for day in document.logs {
            for entry in day.entries {
                sqlite3_reset(statement)
                sqlite3_clear_bindings(statement)

                guard sqlite3_bind_text(statement, 1, entry.id.uuidString, -1, sqliteTransient) == SQLITE_OK,
                      sqlite3_bind_text(statement, 2, day.id, -1, sqliteTransient) == SQLITE_OK,
                      sqlite3_bind_text(statement, 3, entry.loggedAt.ISO8601Format(), -1, sqliteTransient) == SQLITE_OK,
                      sqlite3_bind_text(statement, 4, entry.mealSlot.rawValue, -1, sqliteTransient) == SQLITE_OK,
                      sqlite3_bind_text(statement, 5, entry.title, -1, sqliteTransient) == SQLITE_OK,
                      sqlite3_bind_int64(statement, 6, sqlite3_int64(entry.proteinGrams)) == SQLITE_OK,
                      sqlite3_bind_int64(statement, 7, sqlite3_int64(entry.calories)) == SQLITE_OK,
                      sqlite3_bind_int64(statement, 8, sqlite3_int64(entry.baseCalories)) == SQLITE_OK,
                      sqlite3_bind_double(statement, 9, entry.calorieBuffer.rawValue) == SQLITE_OK,
                      sqlite3_bind_text(statement, 10, entry.source, -1, sqliteTransient) == SQLITE_OK
                else {
                    throw SQLiteStoreFailure(message: sqliteErrorMessage(for: connection))
                }

                if let note = entry.note {
                    guard sqlite3_bind_text(statement, 11, note, -1, sqliteTransient) == SQLITE_OK else {
                        throw SQLiteStoreFailure(message: sqliteErrorMessage(for: connection))
                    }
                } else {
                    guard sqlite3_bind_null(statement, 11) == SQLITE_OK else {
                        throw SQLiteStoreFailure(message: sqliteErrorMessage(for: connection))
                    }
                }

                guard sqlite3_step(statement) == SQLITE_DONE else {
                    throw SQLiteStoreFailure(message: sqliteErrorMessage(for: connection))
                }
            }
        }
    }

    private func execute(_ sql: String, in connection: OpaquePointer) throws {
        guard sqlite3_exec(connection, sql, nil, nil, nil) == SQLITE_OK else {
            throw SQLiteStoreFailure(message: sqliteErrorMessage(for: connection))
        }
    }

    private func sqliteErrorMessage(for connection: OpaquePointer?) -> String {
        guard let connection, let message = sqlite3_errmsg(connection) else {
            return "Unknown SQLite error"
        }
        return String(cString: message)
    }

    private func readString(column: Int32, from statement: OpaquePointer?) throws -> String {
        guard let value = sqlite3_column_text(statement, column) else {
            throw SQLiteStoreFailure(message: "SQLite returned NULL for a required text column.")
        }
        return String(cString: value)
    }

    private func readOptionalString(column: Int32, from statement: OpaquePointer?) -> String? {
        guard let value = sqlite3_column_text(statement, column) else {
            return nil
        }
        return String(cString: value)
    }

    private func parseUUID(_ rawValue: String) throws -> UUID {
        guard let value = UUID(uuidString: rawValue) else {
            throw SQLiteStoreFailure(message: "Invalid UUID stored in CutBar database.")
        }
        return value
    }

    private func parseDate(_ rawValue: String) throws -> Date {
        let iso8601WithFractionalSeconds = ISO8601DateFormatter()
        iso8601WithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601WithFractionalSeconds.date(from: rawValue) {
            return date
        }

        let iso8601InternetDateTime = ISO8601DateFormatter()
        iso8601InternetDateTime.formatOptions = [.withInternetDateTime]
        if let date = iso8601InternetDateTime.date(from: rawValue) {
            return date
        }

        // Legacy app builds stored local timestamps without timezone offsets.
        let legacyLocalTimestampWithFractionalSeconds = DateFormatter()
        legacyLocalTimestampWithFractionalSeconds.calendar = Calendar(identifier: .gregorian)
        legacyLocalTimestampWithFractionalSeconds.locale = Locale(identifier: "en_US_POSIX")
        legacyLocalTimestampWithFractionalSeconds.timeZone = .current
        legacyLocalTimestampWithFractionalSeconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let date = legacyLocalTimestampWithFractionalSeconds.date(from: rawValue) {
            return date
        }

        let legacyLocalTimestamp = DateFormatter()
        legacyLocalTimestamp.calendar = Calendar(identifier: .gregorian)
        legacyLocalTimestamp.locale = Locale(identifier: "en_US_POSIX")
        legacyLocalTimestamp.timeZone = .current
        legacyLocalTimestamp.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = legacyLocalTimestamp.date(from: rawValue) {
            return date
        }

        throw SQLiteStoreFailure(message: "Invalid logged_at value stored in CutBar database.")
    }

    private func parseMealSlot(_ rawValue: String) throws -> MealSlot {
        guard let slot = MealSlot(rawValue: rawValue) else {
            throw SQLiteStoreFailure(message: "Invalid meal slot stored in CutBar database.")
        }
        return slot
    }

    private func parseCalorieBuffer(_ rawValue: Double) throws -> CalorieBuffer {
        for buffer in CalorieBuffer.allCases where abs(buffer.rawValue - rawValue) < 0.0001 {
            return buffer
        }
        throw SQLiteStoreFailure(message: "Invalid calorie buffer stored in CutBar database.")
    }
}

private struct SQLiteStoreFailure: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
