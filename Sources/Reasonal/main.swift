import AppKit

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let controller = MenuBarController()
    app.setActivationPolicy(.accessory)
    withExtendedLifetime(controller) { app.run() }
}
