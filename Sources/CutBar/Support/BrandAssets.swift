import AppKit
import SwiftUI

enum BrandAssets {
    nonisolated(unsafe) static let menuBarIcon = loadImageSet(named: "MenuBarIcon", pointSize: NSSize(width: 18, height: 18), template: true)
    nonisolated(unsafe) static let wordmark = loadImageSet(named: "Wordmark", pointSize: NSSize(width: 320, height: 80), template: false)

    private static func loadImageSet(named name: String, pointSize: NSSize, template: Bool) -> NSImage {
        let subdir = "Assets.xcassets/\(name).imageset"
        let bundle = Bundle.module

        let image = NSImage()
        image.size = pointSize
        image.isTemplate = template

        let variants: [(suffix: String, scale: CGFloat)] = [("", 1), ("@2x", 2), ("@3x", 3)]
        for variant in variants {
            let resourceName = name + variant.suffix
            guard
                let url = bundle.url(forResource: resourceName, withExtension: "png", subdirectory: subdir)
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
