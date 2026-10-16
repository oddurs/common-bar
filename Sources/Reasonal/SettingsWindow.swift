import AppKit
import SwiftUI

@MainActor
final class SettingsWindow {
    private var window: NSWindow?

    func show() {
        // A fresh view each time, so Open at login reflects a change made elsewhere.
        let content = NSHostingController(rootView: SettingsView())
        content.sizingOptions = .preferredContentSize

        if let window {
            window.contentViewController = content
        } else {
            let window = NSWindow(contentViewController: content)
            window.styleMask = [.titled, .closable]
            window.title = "Common Bar Settings"
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}
