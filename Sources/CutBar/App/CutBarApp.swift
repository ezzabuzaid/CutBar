import AppKit
import SwiftUI

private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Intentional menu-bar-first behavior with on-demand windows.
        NSApp.setActivationPolicy(.accessory)
        AppFonts.registerBundled()
        AppLogger.lifecycle.info("CutBar launched as an accessory menu bar app.")
    }
}

@main
struct CutBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = CutBarModel()
    @StateObject private var updater = Updater()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanelView(model: model)
                .tint(Color.themeAccent)
                .foregroundColor(Color.themeInk)
        } label: {
            Image.brandMenuBarIcon
                .accessibilityLabel("CutBar")
        }
        .menuBarExtraStyle(.window)

        WindowGroup("CutBar Dashboard", id: "dashboard") {
            DashboardView(model: model)
                .tint(Color.themeAccent)
                .foregroundColor(Color.themeInk)
        }
        .defaultSize(width: 500, height: 760)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                AboutCommand()
            }
            CommandGroup(replacing: .newItem) {
                NewEntryCommand(model: model)
            }
            CommandGroup(after: .toolbar) {
                RefreshCommand(model: model)
                HistoryCommand()
            }
        }

        Window("Meal History", id: "history") {
            MealHistoryView(model: model)
                .tint(Color.themeAccent)
                .foregroundColor(Color.themeInk)
        }
        .defaultSize(width: 560, height: 680)
        .windowResizability(.contentMinSize)

        Window("About CutBar", id: "about") {
            AboutView(updater: updater)
        }
        .defaultSize(width: 360, height: 360)
        .windowResizability(.contentSize)
    }
}

private struct AboutCommand: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("About CutBar") {
            openWindow(id: "about")
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

private struct NewEntryCommand: View {
    let model: CutBarModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("New Entry") {
            let slot = model.currentPhase.suggestedSlot ?? .meal2
            model.startCustomEntry(for: slot)
            openWindow(id: "dashboard")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("n", modifiers: .command)
        .disabled(!model.canMutateStorage)
    }
}

private struct RefreshCommand: View {
    let model: CutBarModel

    var body: some View {
        Button("Refresh") {
            model.refreshClock()
        }
        .keyboardShortcut("r", modifiers: .command)
    }
}

private struct HistoryCommand: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Meal History") {
            openWindow(id: "history")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("y", modifiers: .command)
    }
}
