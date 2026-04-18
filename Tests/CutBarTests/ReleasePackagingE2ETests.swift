import Foundation
import XCTest

final class ReleasePackagingE2ETests: XCTestCase {
    func testPackageOnlyReleaseEmbedsSparkleFrameworkAndRPath() throws {
        let rootDirectory = repositoryRoot()
        let prebuiltBinPath = try findPrebuiltSwiftPMBinPath(rootDirectory: rootDirectory)
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("cutbar-release-e2e-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)

        let home = tempRoot.appendingPathComponent("home", isDirectory: true)
        let clangCache = tempRoot.appendingPathComponent("clang-module-cache", isDirectory: true)
        let swiftPMCache = tempRoot.appendingPathComponent("swiftpm-cache", isDirectory: true)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: clangCache, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: swiftPMCache, withIntermediateDirectories: true)

        let releaseRun = try runCommand(
            executable: "/bin/zsh",
            arguments: [
                "-lc",
                "RELEASE_MODE=package-only RELEASE_BUILD_BIN_PATH='\(shellSingleQuoted(prebuiltBinPath.path))' ./scripts/release.sh 0.0.0-e2e",
            ],
            currentDirectory: rootDirectory,
            environment: [
                "HOME": home.path,
                "CLANG_MODULE_CACHE_PATH": clangCache.path,
                "SWIFTPM_CACHE_DIR": swiftPMCache.path,
            ]
        )

        XCTAssertEqual(
            releaseRun.exitCode,
            0,
            "release packaging failed:\nSTDOUT:\n\(releaseRun.stdout)\nSTDERR:\n\(releaseRun.stderr)"
        )

        let appBundle = rootDirectory.appendingPathComponent("dist/CutBar.app", isDirectory: true)
        let appBinary = appBundle.appendingPathComponent("Contents/MacOS/CutBar")
        let sparkleFramework = appBundle.appendingPathComponent(
            "Contents/Frameworks/Sparkle.framework",
            isDirectory: true
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: appBinary.path), "Missing app binary at \(appBinary.path)")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: sparkleFramework.path),
            "Missing embedded Sparkle.framework at \(sparkleFramework.path)"
        )

        let linkedLibraries = try runCommand(
            executable: "/usr/bin/otool",
            arguments: ["-L", appBinary.path],
            currentDirectory: rootDirectory
        )
        XCTAssertEqual(linkedLibraries.exitCode, 0, "otool -L failed:\n\(linkedLibraries.stderr)")
        XCTAssertTrue(
            linkedLibraries.stdout.contains("@rpath/Sparkle.framework/Versions/B/Sparkle"),
            "Expected Sparkle @rpath dependency in app binary:\n\(linkedLibraries.stdout)"
        )

        let loadCommands = try runCommand(
            executable: "/usr/bin/otool",
            arguments: ["-l", appBinary.path],
            currentDirectory: rootDirectory
        )
        XCTAssertEqual(loadCommands.exitCode, 0, "otool -l failed:\n\(loadCommands.stderr)")
        XCTAssertTrue(
            loadCommands.stdout.contains("@executable_path/../Frameworks"),
            "Expected @executable_path/../Frameworks rpath in app binary load commands."
        )
    }

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func findPrebuiltSwiftPMBinPath(rootDirectory: URL) throws -> URL {
        let candidates = [
            rootDirectory.appendingPathComponent(".build/arm64-apple-macosx/debug", isDirectory: true),
            rootDirectory.appendingPathComponent(".build/x86_64-apple-macosx/debug", isDirectory: true),
            rootDirectory.appendingPathComponent(".build/debug", isDirectory: true),
        ]

        for candidate in candidates {
            let binary = candidate.appendingPathComponent("CutBar")
            if FileManager.default.fileExists(atPath: binary.path) {
                return candidate
            }
        }

        throw NSError(
            domain: "ReleasePackagingE2ETests",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "Could not find a prebuilt SwiftPM bin path containing CutBar."
            ]
        )
    }

    private func shellSingleQuoted(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "'\"'\"'")
    }

    private func runCommand(
        executable: String,
        arguments: [String],
        currentDirectory: URL,
        environment: [String: String] = [:]
    ) throws -> (exitCode: Int32, stdout: String, stderr: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectory

        var mergedEnvironment = ProcessInfo.processInfo.environment
        for (key, value) in environment {
            mergedEnvironment[key] = value
        }
        process.environment = mergedEnvironment

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        return (process.terminationStatus, stdout, stderr)
    }
}
