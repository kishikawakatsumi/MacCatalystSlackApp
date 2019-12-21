import AppKit

final class AppKitSupport: NSObject {
    private let windowManager = WindowManager()

    @objc
    var windowIdentifier: String = "" {
        didSet {
            windowManager.sceneBecameActive(identifier: windowIdentifier)
        }
    }
}

class WindowManager {
    private var windows: [Int: NSWindow] = [:]

    func sceneBecameActive(identifier: String) {
        var newWindows: [Int: NSWindow] = [:]
        for window in NSApplication.shared.windows {
            if !windows.keys.contains(window.windowNumber) {
                self.handleWindowAppearance(identifier: identifier, window: window)
            }
            newWindows[window.windowNumber] = window
        }
        windows = newWindows
    }

    func handleWindowAppearance(identifier: String, window: NSWindow) {
        if identifier == "panel" {
            window.setContentSize(NSSize(width: 200, height: 200))

            window.styleMask.insert(.unifiedTitleAndToolbar)
            window.styleMask.insert(.fullSizeContentView)
            window.styleMask.insert(.titled)
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
        }
    }
}
