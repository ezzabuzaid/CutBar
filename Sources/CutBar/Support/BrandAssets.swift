import AppKit
import SwiftUI

enum BrandAssets {
    nonisolated(unsafe) static let menuBarIcon = loadImage(named: "MenuBarIcon", pointSize: NSSize(width: 18, height: 18), template: true)
    nonisolated(unsafe) static let wordmark = loadImage(named: "Wordmark", pointSize: NSSize(width: 320, height: 80), template: false)

    private static func loadImage(named name: String, pointSize: NSSize, template: Bool) -> NSImage {
        let bundle = Bundle.module

        // Compiled asset catalog path (xcodebuild multi-arch builds emit Assets.car).
        if let image = bundle.image(forResource: name) {
            image.size = pointSize
            image.isTemplate = template
            return image
        }

        // Flat SPM resource bundle (native `swift build`) keeps loose imageset PNGs.
        let image = NSImage()
        image.size = pointSize
        image.isTemplate = template
        let subdir = "Assets.xcassets/\(name).imageset"
        for suffix in ["", "@2x", "@3x"] {
            guard
                let url = bundle.url(forResource: name + suffix, withExtension: "png", subdirectory: subdir)
            else { continue }
            for rep in NSBitmapImageRep.imageReps(withContentsOf: url) ?? [] {
                rep.size = pointSize
                image.addRepresentation(rep)
            }
        }
        if image.representations.isEmpty {
            AppLogger.lifecycle.error("Missing brand asset '\(name, privacy: .public)' in bundle.")
        }
        return image
    }
}

extension Image {
    static var brandMenuBarIcon: Image {
        Image(nsImage: BrandAssets.menuBarIcon)
    }

    static var brandWordmark: Image {
        Image(nsImage: BrandAssets.wordmark)
    }
}
