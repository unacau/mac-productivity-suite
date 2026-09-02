import Cocoa
import SwiftUI
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var updaterController: SPUStandardUpdaterController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory in menu bar (no dock icon by default)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize Sparkle Auto Updater
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        // 1. Setup Status Item in macOS Menu Bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "command", accessibilityDescription: "Mac Productivity Suite") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "⌘ Suite"
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // 2. Setup Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 460)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: MenuBarPopupView())
        
        // 3. Initialize background productivity engines
        _ = AppConfigManager.shared
        _ = AppDiscoveryService.shared
        _ = ChromeProfileHelper.shared
        _ = AppSwitcherEngine.shared
        
        // 4. Log accessibility permission status
        let isTrusted = AXIsProcessTrusted()
        AppLogger.getLogger(category: .engine).info("Accessibility status: \(isTrusted)")
        
        // 5. Open onboarding wizard only for fresh unconfigured installs
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            let config = AppConfigManager.shared.config
            if !config.hasCompletedOnboarding {
                OnboardingWindowController.shared.show()
            }
        }
    }
    
    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let button = statusItem?.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
    
    @objc public func checkForUpdates() {
        updaterController.checkForUpdates(self)
    }
}

@main
struct AppRunner {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
