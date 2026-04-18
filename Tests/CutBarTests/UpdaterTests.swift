import XCTest
@testable import CutBar

@MainActor
final class UpdaterTests: XCTestCase {
    func testStartsIdle() {
        let updater = Updater()

        XCTAssertEqual(updater.status, .idle)
    }

    func testCheckForUpdatesMovesStatusToChecking() {
        let updater = Updater()

        updater.checkForUpdates()

        XCTAssertEqual(updater.status, .checking)
    }

    func testStatusEnumEqualityTreatsDistinctFailuresAsUnequal() {
        XCTAssertEqual(Updater.Status.failed("network down"), .failed("network down"))
        XCTAssertNotEqual(Updater.Status.failed("network down"), .failed("timeout"))
        XCTAssertNotEqual(Updater.Status.failed("network down"), .upToDate)
    }
}
