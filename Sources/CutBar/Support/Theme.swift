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
        appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil ? darkAccent : lightAccent
    }

    static let ink = NSColor(name: "cutbarInk") { appearance in
        appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil ? darkInk : lightInk
    }

    static let surface = NSColor(name: "cutbarSurface") { appearance in
        appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil ? darkSurface : lightSurface
    }

    static let card = NSColor(name: "cutbarCard") { appearance in
        if appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil {
            return darkSurface.blended(withFraction: darkContrast, of: darkInk) ?? darkSurface
        } else {
            return lightSurface.blended(withFraction: lightContrast, of: lightInk) ?? lightSurface
        }
    }
}

extension Color {
    static let themeAccent = Color(nsColor: Theme.accent)
    static let themeInk = Color(nsColor: Theme.ink)
    static let themeSurface = Color(nsColor: Theme.surface)
    static let themeCard = Color(nsColor: Theme.card)
}

private extension NSColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xff) / 255.0
        let g = CGFloat((hex >> 8) & 0xff) / 255.0
        let b = CGFloat(hex & 0xff) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }
}
