import Cocoa
import AppKit
import os

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let logger = Logger(subsystem: "com.unacau.chromequickaccess", category: "app")
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Starting Chrome Quick Access...")
        
        // 1. Setup Menu Bar Status Item
        setupStatusItem()
        
        // 2. Wire Engine Actions
        setupEngineCallbacks()
        
        // 3. Start Caps Lock Engine & Event Tap
        CapsLockEngine.shared.start()
        
        // 4. Start Copy-on-Select Engine
        CopyOnSelectEngine.shared.start()
        
        // 5. Check Accessibility
        if !AXIsProcessTrusted() {
            promptForAccessibilityPermissions()
        }
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        logger.info("Terminating Chrome Quick Access: cleaning up event taps and restoring HID mapping.")
        CapsLockEngine.shared.stop()
        CopyOnSelectEngine.shared.stop()
    }
    
    private enum ActiveSwitcherMode {
        case none
        case chrome
        case antigravity
    }
    
    private var isCyclingHUDActive = false
    private var activeMode: ActiveSwitcherMode = .none
    
    private func setupEngineCallbacks() {
        let profileEngine = ChromeProfileEngine.shared
        let antigravityEngine = AntigravityEngine.shared
        let capsEngine = CapsLockEngine.shared
        
        capsEngine.onChromeTrigger = { [weak self] in
            guard let self = self else { return }
            self.logger.info("Caps-Lock + C triggered.")
            
            let profiles = profileEngine.profiles
            guard !profiles.isEmpty else {
                profileEngine.focusChrome()
                return
            }
            
            if !self.isCyclingHUDActive || self.activeMode != .chrome {
                self.isCyclingHUDActive = true
                self.activeMode = .chrome
                
                let frontApp = NSWorkspace.shared.frontmostApplication
                let isChromeFront = frontApp?.bundleIdentifier == profileEngine.browserBundleID
                
                let activeDir = profileEngine.getActiveProfileDir()
                let currentIdx = profiles.firstIndex(where: { $0.dir == activeDir }) ?? 0
                
                let initialIdx: Int
                if isChromeFront {
                    initialIdx = (currentIdx + 1) % profiles.count
                } else {
                    initialIdx = currentIdx
                }
                
                MinimalHUDWindow.shared.show(profiles: profiles, selectedIndex: initialIdx)
            } else {
                MinimalHUDWindow.shared.selectNext()
            }
        }
        
        capsEngine.onAntigravityTrigger = { [weak self] in
            guard let self = self else { return }
            self.logger.info("Caps-Lock + A triggered.")
            
            let items = antigravityEngine.items
            guard !items.isEmpty else { return }
            
            if !self.isCyclingHUDActive || self.activeMode != .antigravity {
                self.isCyclingHUDActive = true
                self.activeMode = .antigravity
                
                let frontIdx = antigravityEngine.getActiveAppIndex()
                let initialIdx: Int
                if let current = frontIdx {
                    // Toggle to the other Antigravity app when one is frontmost
                    initialIdx = (current + 1) % items.count
                } else {
                    // Activate last active Antigravity app
                    initialIdx = max(0, min(antigravityEngine.lastActiveIndex, items.count - 1))
                }
                
                MinimalHUDWindow.shared.showAntigravity(items: items, selectedIndex: initialIdx)
            } else {
                MinimalHUDWindow.shared.selectNext()
            }
        }
        
        capsEngine.onProfileTrigger = { [weak self] digit in
            guard let self = self else { return }
            self.logger.info("Caps-Lock + \(digit) triggered.")
            
            if self.activeMode == .antigravity {
                let items = antigravityEngine.items
                guard !items.isEmpty else { return }
                let targetIdx = max(0, min(digit - 1, items.count - 1))
                if !self.isCyclingHUDActive {
                    self.isCyclingHUDActive = true
                    MinimalHUDWindow.shared.showAntigravity(items: items, selectedIndex: targetIdx)
                } else {
                    MinimalHUDWindow.shared.updateSelection(to: targetIdx)
                }
            } else {
                let profiles = profileEngine.profiles
                guard !profiles.isEmpty else { return }
                let targetIdx = max(0, min(digit - 1, profiles.count - 1))
                if !self.isCyclingHUDActive {
                    self.isCyclingHUDActive = true
                    self.activeMode = .chrome
                    MinimalHUDWindow.shared.show(profiles: profiles, selectedIndex: targetIdx)
                } else {
                    MinimalHUDWindow.shared.updateSelection(to: targetIdx)
                }
            }
        }
        
        capsEngine.onNavigateLeft = { [weak self] in
            guard let self = self, self.isCyclingHUDActive else { return }
            MinimalHUDWindow.shared.selectPrevious()
        }
        
        capsEngine.onNavigateRight = { [weak self] in
            guard let self = self, self.isCyclingHUDActive else { return }
            MinimalHUDWindow.shared.selectNext()
        }
        
        capsEngine.onCancelTrigger = { [weak self] in
            guard let self = self else { return }
            self.logger.info("Escape pressed: cancelling switcher HUD.")
            self.isCyclingHUDActive = false
            self.activeMode = .none
            MinimalHUDWindow.shared.hideImmediate()
        }
        
        capsEngine.onModifierReleased = { [weak self] in
            guard let self = self else { return }
            guard self.isCyclingHUDActive else { return }
            
            let mode = self.activeMode
            self.isCyclingHUDActive = false
            self.activeMode = .none
            
            // RULE 9: ALWAYS hide HUD before triggering application focus!
            MinimalHUDWindow.shared.hideImmediate()
            
            if mode == .antigravity {
                if let target = ChromeSwitcherState.shared.selectedAntigravityItem {
                    self.logger.info("Caps-Lock released: switching to Antigravity app '\(target.name)' (\(target.bundleID)).")
                    antigravityEngine.focusItem(bundleID: target.bundleID)
                }
            } else {
                let targetProfile = ChromeSwitcherState.shared.selectedProfile
                if let target = targetProfile {
                    self.logger.info("Caps-Lock released: switching to profile '\(target.effectiveName)' (\(target.dir)).")
                    profileEngine.focusProfile(dir: target.dir)
                } else {
                    profileEngine.focusChrome()
                }
            }
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        
        if let image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Chrome Quick Access") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "⚡C"
        }
        
        updateMenu()
    }
    
    public func updateMenu() {
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "Chrome Quick Access", action: nil, keyEquivalent: "")
        titleItem.attributedTitle = NSAttributedString(
            string: "Chrome Quick Access",
            attributes: [.font: NSFont.boldSystemFont(ofSize: 13)]
        )
        menu.addItem(titleItem)
        
        let capsStatusItem = NSMenuItem(
            title: "Caps-Lock: Active (ESC on tap)",
            action: nil,
            keyEquivalent: ""
        )
        capsStatusItem.isEnabled = false
        menu.addItem(capsStatusItem)
        
        let copyStatusTitle = CopyOnSelectEngine.shared.isEnabled ? "Copy-on-Select: Active ✓" : "Copy-on-Select: Disabled"
        let copyStatusItem = NSMenuItem(
            title: copyStatusTitle,
            action: #selector(handleToggleCopyOnSelect),
            keyEquivalent: ""
        )
        copyStatusItem.target = self
        menu.addItem(copyStatusItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let profilesHeader = NSMenuItem(title: "Discovered Profiles:", action: nil, keyEquivalent: "")
        profilesHeader.isEnabled = false
        menu.addItem(profilesHeader)
        
        let profiles = ChromeProfileEngine.shared.profiles
        for p in profiles {
            let item = NSMenuItem(
                title: "\(p.index): \(p.effectiveName)",
                action: #selector(handleProfileClick(_:)),
                keyEquivalent: "\(p.index)"
            )
            item.target = self
            item.representedObject = p.dir
            if let avatar = p.avatarImage {
                let small = NSImage(size: NSSize(width: 16, height: 16))
                small.lockFocus()
                avatar.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
                small.unlockFocus()
                item.image = small
            }
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let antigravityHeader = NSMenuItem(title: "Antigravity (Caps-Lock + A):", action: nil, keyEquivalent: "")
        antigravityHeader.isEnabled = false
        menu.addItem(antigravityHeader)
        
        let antiItems = AntigravityEngine.shared.items
        for item in antiItems {
            let menuItem = NSMenuItem(
                title: "\(item.index): \(item.name)",
                action: #selector(handleAntigravityClick(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = item.bundleID
            let small = NSImage(size: NSSize(width: 16, height: 16))
            small.lockFocus()
            item.icon.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
            small.unlockFocus()
            menuItem.image = small
            menu.addItem(menuItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let refreshItem = NSMenuItem(title: "Refresh Profiles & Apps", action: #selector(handleRefreshProfiles), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        let permItem = NSMenuItem(
            title: AXIsProcessTrusted() ? "Accessibility: Granted ✓" : "Accessibility: Not Granted ⚠",
            action: #selector(handleOpenAccessibilitySettings),
            keyEquivalent: ""
        )
        permItem.target = self
        menu.addItem(permItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Quick Access", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func handleProfileClick(_ sender: NSMenuItem) {
        guard let dir = sender.representedObject as? String else { return }
        ChromeProfileEngine.shared.focusProfile(dir: dir)
    }
    
    @objc private func handleAntigravityClick(_ sender: NSMenuItem) {
        guard let bundleID = sender.representedObject as? String else { return }
        AntigravityEngine.shared.focusItem(bundleID: bundleID)
    }
    
    @objc private func handleRefreshProfiles() {
        ChromeProfileEngine.shared.refreshProfiles()
        AntigravityEngine.shared.refreshItems()
        updateMenu()
    }
    
    @objc private func handleToggleCopyOnSelect() {
        CopyOnSelectEngine.shared.isEnabled.toggle()
        if CopyOnSelectEngine.shared.isEnabled {
            CopyOnSelectEngine.shared.start()
        } else {
            CopyOnSelectEngine.shared.stop()
        }
        updateMenu()
    }
    
    @objc private func handleOpenAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
    
    private func promptForAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
