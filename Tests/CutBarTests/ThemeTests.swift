import AppKit
import XCTest
@testable import CutBar

final class ThemeTests: XCTestCase {
    func testSurfaceDiffersBetweenLightAndDark() {
        XCTAssertNotEqual(
            resolve(Theme.surface, appearance: .aqua),
            resolve(Theme.surface, appearance: .darkAqua)
        )
    }

    func testInkDiffersBetweenLightAndDark() {
        XCTAssertNotEqual(
            resolve(Theme.ink, appearance: .aqua),
            resolve(Theme.ink, appearance: .darkAqua)
        )
    }

    func testWarningForegroundDiffersBetweenLightAndDark() {
        XCTAssertNotEqual(
            resolve(Theme.warningForeground, appearance: .aqua),
            resolve(Theme.warningForeground, appearance: .darkAqua)
        )
    }

    func testWarningBackgroundIsTranslucent() {
        let light = resolve(Theme.warningBackground, appearance: .aqua)
        let dark = resolve(Theme.warningBackground, appearance: .darkAqua)

        XCTAssertLessThan(light.alpha, 1.0)
        XCTAssertLessThan(dark.alpha, 1.0)
        XCTAssertGreaterThan(light.alpha, 0.0)
        XCTAssertGreaterThan(dark.alpha, 0.0)
    }

    func testPressedOverlayIsStrongerThanHover() {
        let hover = resolve(Theme.hover, appearance: .darkAqua)
        let pressed = resolve(Theme.pressed, appearance: .darkAqua)

        XCTAssertGreaterThan(pressed.alpha, hover.alpha)
    }

    func testCardDeviatesFromSurface() {
        XCTAssertNotEqual(
            resolve(Theme.surface, appearance: .aqua),
            resolve(Theme.card, appearance: .aqua)
        )
    }

    private struct ResolvedColor: Equatable {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat
    }

    private func resolve(_ color: NSColor, appearance name: NSAppearance.Name) -> ResolvedColor {
        let appearance = NSAppearance(named: name)!
        var components = ResolvedColor(red: 0, green: 0, blue: 0, alpha: 0)
        appearance.performAsCurrentDrawingAppearance {
            guard let srgb = color.usingColorSpace(.sRGB) else { return }
            components = ResolvedColor(
                red: srgb.redComponent,
                green: srgb.greenComponent,
                blue: srgb.blueComponent,
                alpha: srgb.alphaComponent
            )
        }
        return components
    }
}
