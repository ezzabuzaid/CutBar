import CoreText
import Foundation
import SwiftUI

enum AppFonts {
    static let display = "Jost"
    static let instrumentSans = "Instrument Sans"

    static func registerBundled() {
        let fontNames = [
            "Jost-Variable",
            "InstrumentSans-Variable",
        ]

        let urls = fontNames.compactMap { bundledFontURL(for: $0) }

        guard !urls.isEmpty else {
            AppLogger.lifecycle.error("No bundled font URLs resolved from Resources/Fonts.")
            return
        }

        for url in urls {
            var error: Unmanaged<CFError>?
            let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if !ok {
                let err = error?.takeRetainedValue()
                let message = err.map { "\($0)" } ?? "unknown error"
                AppLogger.lifecycle.error(
                    "Failed to register \(url.lastPathComponent, privacy: .public): \(message, privacy: .public)"
                )
            }
        }

        AppLogger.lifecycle.info("Registered bundled fonts: Jost, Instrument Sans.")
    }

    private static func bundledFontURL(for name: String) -> URL? {
        let bundle = Bundle.module
        let fileManager = FileManager.default
        let bundleRelativePaths = [
            "Fonts/\(name).ttf",
            "Resources/Fonts/\(name).ttf",
            "Contents/Resources/Fonts/\(name).ttf",
        ]

        if let url = bundle.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") {
            return url
        }

        if let url = bundle.url(forResource: name, withExtension: "ttf") {
            return url
        }

        let fallbackURLs = [
            bundle.resourceURL?.appendingPathComponent("Fonts/\(name).ttf"),
            bundle.resourceURL?.appendingPathComponent("Resources/Fonts/\(name).ttf"),
            bundle.bundleURL.appendingPathComponent("Contents/Resources/Fonts/\(name).ttf"),
        ].compactMap { $0 }

        if let resolved = fallbackURLs.first(where: { fileManager.fileExists(atPath: $0.path) }) {
            AppLogger.lifecycle.info("Resolved \(name, privacy: .public).ttf from fallback bundle path.")
            return resolved
        }

        AppLogger.lifecycle.error(
            "Missing bundled font \(name, privacy: .public).ttf. Tried paths: \(bundleRelativePaths.joined(separator: ", "), privacy: .public)."
        )
        return nil
    }
}

extension Font {
    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(AppFonts.display, size: size).weight(weight)
    }

    static func appBodyFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(AppFonts.instrumentSans, size: size).weight(weight)
    }

    static var appLargeTitle: Font { .display(26, weight: .bold) }
    static var appTitle: Font { .display(20, weight: .semibold) }
    static var appTitle3: Font { .display(15, weight: .semibold) }
    static var appHeadline: Font { .display(13, weight: .semibold) }
    static var appSubheadline: Font { .appBodyFont(12, weight: .regular) }
    static var appSubheadlineMedium: Font { .appBodyFont(12, weight: .medium) }
    static var appBody: Font { .appBodyFont(13, weight: .regular) }
    static var appCaption: Font { .appBodyFont(11, weight: .regular) }
    static var appCaption2: Font { .appBodyFont(10, weight: .regular) }
    static var appFootnote: Font { .appBodyFont(11, weight: .regular) }
}
