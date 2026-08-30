import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory in menu bar (no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // 1. Setup Status Item in macOS Menu Bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use standard SF Symbol with fallback
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
        _ = AppSwitcherEngine.shared
        _ = CopyOnSelectEngine.shared
        _ = ProductivityActionsHelper.shared
        
        // 4. Check & prompt accessibility immediately if not trusted
        if !AXIsProcessTrusted() {
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options)
        }
        
        // 5. Automatically open the welcome/controls popover on first launch so the user sees it immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.showPopover()
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
