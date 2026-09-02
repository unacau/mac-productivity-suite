import Cocoa
import SwiftUI
import Sparkle

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var updaterController: SPUStandardUpdaterController!
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
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
        
        // 4. Check and watch accessibility permissions
        setupAccessibilityWatcher()
        
        // 5. Open onboarding wizard only for fresh unconfigured installs
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            let currentConfig = AppConfigManager.shared.config
            if !currentConfig.hasCompletedOnboarding {
                OnboardingWindowController.shared.show()
            }
        }
    }
    
    private var accessibilityWatcherTimer: Timer?
    
    public func startProductivityEngines() {
        let config = AppConfigManager.shared.config
        if config.remapCapsLockToHyper {
            HyperKeyEngine.shared.escapeOnTapEnabled = config.escapeOnTap
            HyperKeyEngine.shared.start()
        }
        
        if config.copyOnSelectEnabled {
            CopyOnSelectEngine.shared.isEnabled = true
            CopyOnSelectEngine.shared.start()
        }
    }
    
    private func setupAccessibilityWatcher() {
        let isTrusted = AXIsProcessTrusted()
        AppLogger.getLogger(category: .engine).info("Initial accessibility status: \(isTrusted)")
        
        if isTrusted {
            startProductivityEngines()
        } else {
            // Prompt user for accessibility permissions
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            
            // Watch for user granting permission in System Settings
            accessibilityWatcherTimer?.invalidate()
            accessibilityWatcherTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                Task { @MainActor in
                    if AXIsProcessTrusted() {
                        AppLogger.getLogger(category: .engine).info("Accessibility granted! Initializing HyperKey and CopyOnSelect engines.")
                        timer.invalidate()
                        self.accessibilityWatcherTimer = nil
                        self.startProductivityEngines()
                    }
                }
            }
        }
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        HyperKeyEngine.shared.stop()
        CopyOnSelectEngine.shared.stop()
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
