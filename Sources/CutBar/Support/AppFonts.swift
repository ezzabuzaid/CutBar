import CoreText
import Foundation
import SwiftUI

enum AppFonts {
    static let display = "Jost"
    static let body = "Instrument Sans"

    static func registerBundled() {
        let fontNames = [
            "Jost-Variable",
            "InstrumentSans-Variable",
        ]

        let urls = fontNames.compactMap { name in
            Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
        }

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
}

extension Font {
    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(AppFonts.display, size: size).weight(weight)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(AppFonts.body, size: size).weight(weight)
    }

    static var appLargeTitle: Font { .display(26, weight: .bold) }
    static var appTitle: Font { .display(20, weight: .semibold) }
    static var appTitle3: Font { .display(15, weight: .semibold) }
    static var appHeadline: Font { .display(13, weight: .semibold) }
    static var appSubheadline: Font { .body(12, weight: .regular) }
    static var appSubheadlineMedium: Font { .body(12, weight: .medium) }
    static var appBody: Font { .body(13, weight: .regular) }
    static var appCaption: Font { .body(11, weight: .regular) }
    static var appCaption2: Font { .body(10, weight: .regular) }
    static var appFootnote: Font { .body(11, weight: .regular) }
}
