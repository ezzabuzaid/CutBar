import AppKit
import SwiftUI

enum Theme {
    static let lightAccent = NSColor(hex: 0x3d755d)
    static let lightInk = NSColor(hex: 0x2f312d)
    static let lightSurface = NSColor(hex: 0xf5f3ed)
    static let lightContrast: CGFloat = 0.04

    static let darkAccent = NSColor(hex: 0xe4f222)
    static let darkInk = NSColor(hex: 0xc7e6da)
    static let darkSurface = NSColor(hex: 0x02120c)
    static let darkContrast: CGFloat = 0.05

    static let accent = NSColor(name: "cutbarAccent") { appearance in
        isDarkAppearance(appearance) ? darkAccent : lightAccent
    }

    static let ink = NSColor(name: "cutbarInk") { appearance in
        isDarkAppearance(appearance) ? darkInk : lightInk
    }

    static let surface = NSColor(name: "cutbarSurface") { appearance in
        isDarkAppearance(appearance) ? darkSurface : lightSurface
    }

    static let card = NSColor(name: "cutbarCard") { appearance in
        if isDarkAppearance(appearance) {
            return darkSurface.blended(withFraction: darkContrast, of: darkInk) ?? darkSurface
        } else {
            return lightSurface.blended(withFraction: lightContrast, of: lightInk) ?? lightSurface
        }
    }

    static let hover = NSColor(name: "cutbarHover") { appearance in
        let isHighContrast = isHighContrastAppearance(appearance)
        let alpha: CGFloat
        if isHighContrast {
            alpha = isDarkAppearance(appearance) ? 0.18 : 0.14
        } else {
            alpha = isDarkAppearance(appearance) ? 0.12 : 0.08
        }
        let base = isDarkAppearance(appearance) ? darkInk : lightInk
        return base.withAlphaComponent(alpha)
    }

    static let pressed = NSColor(name: "cutbarPressed") { appearance in
        let isHighContrast = isHighContrastAppearance(appearance)
        let alpha: CGFloat
        if isHighContrast {
            alpha = isDarkAppearance(appearance) ? 0.30 : 0.24
        } else {
            alpha = isDarkAppearance(appearance) ? 0.22 : 0.16
        }
        let base = isDarkAppearance(appearance) ? darkInk : lightInk
        return base.withAlphaComponent(alpha)
    }

    static let warningForeground = NSColor(name: "cutbarWarningForeground") { appearance in
        if isDarkAppearance(appearance) {
            return isHighContrastAppearance(appearance) ? .systemYellow : NSColor(hex: 0xf5e279)
        } else {
            return isHighContrastAppearance(appearance) ? .systemOrange : NSColor(hex: 0x8a4f00)
        }
    }

    static let warningBackground = NSColor(name: "cutbarWarningBackground") { appearance in
        let base: NSColor = isDarkAppearance(appearance) ? .systemYellow : .systemOrange
        let alpha: CGFloat = isHighContrastAppearance(appearance) ? 0.30 : 0.18
        return base.withAlphaComponent(alpha)
    }

    private static func isDarkAppearance(_ appearance: NSAppearance) -> Bool {
        appearance.bestMatch(
            from: [
                .accessibilityHighContrastDarkAqua,
                .darkAqua,
                .vibrantDark,
            ]
        ) != nil
    }

    private static func isHighContrastAppearance(_ appearance: NSAppearance) -> Bool {
        appearance.bestMatch(
            from: [
                .accessibilityHighContrastAqua,
                .accessibilityHighContrastDarkAqua,
            ]
        ) != nil
    }
}

extension Color {
    static let themeAccent = Color(nsColor: Theme.accent)
    static let themeInk = Color(nsColor: Theme.ink)
    static let themeSurface = Color(nsColor: Theme.surface)
    static let themeCard = Color(nsColor: Theme.card)
    static let themeHover = Color(nsColor: Theme.hover)
    static let themePressed = Color(nsColor: Theme.pressed)
    static let themeWarningForeground = Color(nsColor: Theme.warningForeground)
    static let themeWarningBackground = Color(nsColor: Theme.warningBackground)
}

private extension NSColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xff) / 255.0
        let g = CGFloat((hex >> 8) & 0xff) / 255.0
        let b = CGFloat(hex & 0xff) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }
}
