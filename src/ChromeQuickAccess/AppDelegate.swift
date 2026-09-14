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
    
    private enum ActiveSwitcherMode: Equatable {
        case none
        case chrome
        case appLetter(Character)
        case antigravity
        case terminal
        case notes
        case ide
    }
    
    private var isCyclingHUDActive = false
    private var activeMode: ActiveSwitcherMode = .none
    
    private func handleSingleAppTrigger(
        engine: AppGroupEngine,
        mode: ActiveSwitcherMode,
        switcherMode: SwitcherMode,
        keyName: String
    ) {
        logger.info("Caps-Lock + \(keyName) triggered.")
        guard let item = engine.selectedItem else { return }
        
        if !isCyclingHUDActive || activeMode != mode {
            isCyclingHUDActive = true
            activeMode = mode
            MinimalHUDWindow.shared.showAppGroup(mode: switcherMode, items: [item], selectedIndex: 0)
        }
    }
    
    private func handleAppLetterTrigger(char: Character, items: [AntigravityItem]) {
        logger.info("Caps-Lock + \(char) triggered for \(items.map { $0.name }).")
        guard !items.isEmpty else { return }
        
        let targetMode = ActiveSwitcherMode.appLetter(char)
        if !isCyclingHUDActive || activeMode != targetMode {
            isCyclingHUDActive = true
            activeMode = targetMode
            
            var initialIdx = 0
            if items.count > 1 {
                let frontBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
                if let currentIdx = items.firstIndex(where: { $0.bundleID == frontBundleID }) {
                    initialIdx = (currentIdx + 1) % items.count
                }
            }
            
            MinimalHUDWindow.shared.showAppGroup(mode: .antigravity, items: items, selectedIndex: initialIdx)
        } else {
            MinimalHUDWindow.shared.selectNext()
        }
    }
    
    private func focusApp(bundleID: String) {
        AppGroupEngine.focusItem(bundleID: bundleID)
    }
    
    private func handleChromeTrigger() {
        let profileEngine = ChromeProfileEngine.shared
        logger.info("Caps-Lock + C triggered.")
        
        let profiles = profileEngine.selectedProfiles
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
    
    /// Re-evaluates and binds dynamic hotkeys based strictly on the first letter of each selected application's name.
    public func updateDynamicShortcuts() {
        var letterToItems: [Character: [AntigravityItem]] = [:]
        
        let engines = [
            AppGroupEngine.terminal,
            AppGroupEngine.aiAgent,
            AppGroupEngine.ide,
            AppGroupEngine.notes
        ]
        
        for engine in engines {
            if let item = engine.selectedItem {
                let char = engine.activeShortcutChar
                if letterToItems[char] == nil {
                    letterToItems[char] = []
                }
                if !letterToItems[char]!.contains(where: { $0.bundleID == item.bundleID }) {
                    letterToItems[char]!.append(item)
                }
            }
        }
        
        var triggers: [UInt32: @MainActor () -> Void] = [:]
        
        // 1. Chrome browser is 'C'
        triggers[KeyCodes.kVK_ANSI_C] = { [weak self] in
            self?.handleChromeTrigger()
        }
        
        // 2. Register every letter's items
        for (char, items) in letterToItems {
            // 'C' is already handled by Chrome profile switcher
            if char == "C" { continue }
            
            if let code = KeyCodes.keyCode(for: char) {
                triggers[code] = { [weak self] in
                    self?.handleAppLetterTrigger(char: char, items: items)
                }
            }
        }
        
        CapsLockEngine.shared.dynamicKeyTriggers = triggers
        logger.info("Dynamic app shortcuts updated: \(letterToItems.map { "\($0.key): \($0.value.map { $0.name })" })")
    }
    
    private func setupEngineCallbacks() {
        let profileEngine = ChromeProfileEngine.shared
        let aiAgentEngine = AppGroupEngine.aiAgent
        let terminalEngine = AppGroupEngine.terminal
        let notesEngine = AppGroupEngine.notes
        let ideEngine = AppGroupEngine.ide
        let capsEngine = CapsLockEngine.shared
        
        updateDynamicShortcuts()
        
        capsEngine.onChromeTrigger = { [weak self] in
            self?.handleChromeTrigger()
        }
        
        capsEngine.onAntigravityTrigger = { [weak self] in
            guard let self = self else { return }
            self.handleSingleAppTrigger(
                engine: aiAgentEngine,
                mode: .antigravity,
                switcherMode: .antigravity,
                keyName: String(aiAgentEngine.activeShortcutChar)
            )
        }
        
        capsEngine.onTerminalTrigger = { [weak self] in
            guard let self = self else { return }
            self.handleSingleAppTrigger(
                engine: terminalEngine,
                mode: .terminal,
                switcherMode: .terminal,
                keyName: String(terminalEngine.activeShortcutChar)
            )
        }
        
        capsEngine.onNotesTrigger = { [weak self] in
            guard let self = self else { return }
            self.handleSingleAppTrigger(
                engine: notesEngine,
                mode: .notes,
                switcherMode: .notes,
                keyName: String(notesEngine.activeShortcutChar)
            )
        }
        
        capsEngine.onIdeTrigger = { [weak self] in
            guard let self = self else { return }
            self.handleSingleAppTrigger(
                engine: ideEngine,
                mode: .ide,
                switcherMode: .ide,
                keyName: String(ideEngine.activeShortcutChar)
            )
        }
        
        capsEngine.onProfileTrigger = { [weak self] digit in
            guard let self = self else { return }
            self.logger.info("Caps-Lock + \(digit) triggered.")
            
            let profiles = profileEngine.selectedProfiles
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
            
            switch mode {
            case .chrome:
                let targetProfile = ChromeSwitcherState.shared.selectedProfile
                if let target = targetProfile {
                    self.logger.info("Caps-Lock released: switching to profile '\(target.effectiveName)' (\(target.dir)).")
                    profileEngine.focusProfile(dir: target.dir)
                } else {
                    profileEngine.focusChrome()
                }
            case .appLetter(let char):
                if let target = ChromeSwitcherState.shared.selectedAppItem {
                    self.logger.info("Caps-Lock released: switching to '\(target.name)' (\(target.bundleID)) for key \(char).")
                    self.focusApp(bundleID: target.bundleID)
                }
            case .antigravity:
                if let target = aiAgentEngine.selectedItem {
                    self.logger.info("Caps-Lock released: switching to AI Agent '\(target.name)' (\(target.bundleID)).")
                    aiAgentEngine.focusItem(bundleID: target.bundleID)
                }
            case .terminal:
                if let target = terminalEngine.selectedItem {
                    self.logger.info("Caps-Lock released: switching to Terminal app '\(target.name)' (\(target.bundleID)).")
                    terminalEngine.focusItem(bundleID: target.bundleID)
                }
            case .notes:
                if let target = notesEngine.selectedItem {
                    self.logger.info("Caps-Lock released: switching to Notes app '\(target.name)' (\(target.bundleID)).")
                    notesEngine.focusItem(bundleID: target.bundleID)
                }
            case .ide:
                if let target = ideEngine.selectedItem {
                    self.logger.info("Caps-Lock released: switching to IDE app '\(target.name)' (\(target.bundleID)).")
                    ideEngine.focusItem(bundleID: target.bundleID)
                }
            case .none:
                break
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
        let menu = buildStatusMenu()
        statusItem?.menu = menu
    }
    
    private func makeAlignedMenuItem(
        title: String,
        keyEquivalent: String = "",
        modifierMask: NSEvent.ModifierFlags = [],
        isHeader: Bool = false,
        icon: NSImage? = nil,
        action: Selector? = nil,
        target: AnyObject? = nil,
        representedObject: Any? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.keyEquivalentModifierMask = modifierMask
        item.target = target
        item.representedObject = representedObject
        
        if isHeader {
            let attr = NSMutableAttributedString(string: title)
            attr.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 13), range: NSRange(location: 0, length: (title as NSString).length))
            item.attributedTitle = attr
        }
        
        if let icon = icon {
            let small = NSImage(size: NSSize(width: 16, height: 16))
            small.lockFocus()
            icon.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
            small.unlockFocus()
            item.image = small
        }
        
        return item
    }
    
    @discardableResult
    public func buildStatusMenu() -> NSMenu {
        updateDynamicShortcuts()
        let menu = NSMenu()
        
        let profileEngine = ChromeProfileEngine.shared
        let selectedList = profileEngine.selectedProfiles
        
        // 1. Chrome section (caps lock + C)
        let chromeIcon: NSImage
        if let appIcon = NSWorkspace.shared.icon(forFile: "/Applications/Google Chrome.app") as NSImage? {
            chromeIcon = appIcon
        } else if let firstAvatar = profileEngine.profiles.first?.avatarImage {
            chromeIcon = firstAvatar
        } else {
            chromeIcon = NSImage(systemSymbolName: "globe", accessibilityDescription: nil) ?? NSImage()
        }
        
        let chromeHeader = makeAlignedMenuItem(
            title: "Chrome (Caps-Lock + C)",
            isHeader: true,
            icon: chromeIcon,
            action: nil,
            target: nil
        )
        chromeHeader.isEnabled = false
        menu.addItem(chromeHeader)
        
        if !selectedList.isEmpty {
            for p in selectedList {
                let pItem = makeAlignedMenuItem(
                    title: p.effectiveName,
                    keyEquivalent: "\(p.index)",
                    icon: p.avatarImage,
                    action: #selector(handleProfileClick(_:)),
                    target: self,
                    representedObject: p.dir
                )
                pItem.toolTip = "Slot #\(p.index): \(p.effectiveName). Click to switch, ⌥-click to deselect."
                menu.addItem(pItem)
            }
        } else if let firstProfile = profileEngine.profiles.first {
            let pItem = makeAlignedMenuItem(
                title: firstProfile.effectiveName,
                keyEquivalent: "1",
                icon: firstProfile.avatarImage,
                action: #selector(handleProfileClick(_:)),
                target: self,
                representedObject: firstProfile.dir
            )
            menu.addItem(pItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. Toolkit section (caps lock)
        let toolkitIcon = NSImage(systemSymbolName: "wrench.and.screwdriver.fill", accessibilityDescription: nil) ?? NSImage()
        let toolkitHeader = makeAlignedMenuItem(
            title: "Toolkit (Caps-Lock)",
            isHeader: true,
            icon: toolkitIcon,
            action: nil,
            target: nil
        )
        toolkitHeader.isEnabled = false
        menu.addItem(toolkitHeader)
        
        let toolkitConfigs: [(category: String, engine: AppGroupEngine)] = [
            ("Terminal", AppGroupEngine.terminal),
            ("IDE", AppGroupEngine.ide),
            ("AI Agent", AppGroupEngine.aiAgent),
            ("Notes", AppGroupEngine.notes)
        ]
        
        for config in toolkitConfigs {
            let engine = config.engine
            if let item = engine.selectedItem {
                let char = engine.activeShortcutChar
                let rowItem = makeAlignedMenuItem(
                    title: item.name,
                    keyEquivalent: String(char).lowercased(),
                    icon: item.icon,
                    action: #selector(handleCoreAppClick(_:)),
                    target: self,
                    representedObject: item.bundleID
                )
                rowItem.toolTip = "\(config.category): \(item.name) (Caps-Lock + \(char)). Click to switch."
                menu.addItem(rowItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Change App submenu
        let changeAppItem = NSMenuItem(title: "Change App", action: nil, keyEquivalent: "")
        let changeAppSubmenu = NSMenu(title: "Change App")
        
        let transparentOffImage = NSImage(size: NSSize(width: 14, height: 14))
        
        // 3a. Chrome Profiles in Change App
        let chromeCatHeader = NSMenuItem(title: "Chrome Profiles (up to 4):", action: nil, keyEquivalent: "")
        chromeCatHeader.attributedTitle = NSAttributedString(
            string: "Chrome Profiles (up to 4):",
            attributes: [.font: NSFont.boldSystemFont(ofSize: 11)]
        )
        chromeCatHeader.isEnabled = false
        changeAppSubmenu.addItem(chromeCatHeader)
        
        for p in profileEngine.profiles {
            let isSelected = selectedList.contains(where: { $0.dir == p.dir })
            let slot = selectedList.first(where: { $0.dir == p.dir })?.index
            let pItem = makeAlignedMenuItem(
                title: p.effectiveName,
                keyEquivalent: slot != nil ? "\(slot!)" : "",
                icon: p.avatarImage,
                action: #selector(handleChangeProfileClick(_:)),
                target: self,
                representedObject: p.dir
            )
            pItem.state = isSelected ? .on : .off
            if !isSelected {
                pItem.offStateImage = transparentOffImage
            }
            pItem.toolTip = isSelected ? "Active slot #\(slot!). Click to deselect." : "Click to select into active slots."
            changeAppSubmenu.addItem(pItem)
        }
        
        // 3b. Toolkit categories in Change App
        for config in toolkitConfigs {
            changeAppSubmenu.addItem(NSMenuItem.separator())
            
            let catHeader = NSMenuItem(title: "\(config.category):", action: nil, keyEquivalent: "")
            catHeader.attributedTitle = NSAttributedString(
                string: "\(config.category):",
                attributes: [.font: NSFont.boldSystemFont(ofSize: 11)]
            )
            catHeader.isEnabled = false
            changeAppSubmenu.addItem(catHeader)
            
            let engine = config.engine
            for item in engine.items {
                let isSelected = engine.isSelected(bundleID: item.bundleID)
                let char = Character((item.name.first(where: { $0.isLetter }) ?? "A").uppercased())
                let menuItem = makeAlignedMenuItem(
                    title: item.name,
                    keyEquivalent: String(char).lowercased(),
                    icon: item.icon,
                    action: #selector(handleChangeAppItemClick(_:)),
                    target: self,
                    representedObject: "\(engine.category):\(item.bundleID)"
                )
                menuItem.state = isSelected ? .on : .off
                if !isSelected {
                    menuItem.offStateImage = transparentOffImage
                }
                menuItem.toolTip = "Set \(item.name) as active \(config.category) (Caps-Lock + \(char))."
                changeAppSubmenu.addItem(menuItem)
            }
        }
        
        changeAppItem.submenu = changeAppSubmenu
        menu.addItem(changeAppItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. Utility / options items
        let copyStatusTitle = CopyOnSelectEngine.shared.isEnabled ? "Copy-on-Select: Active ✓" : "Copy-on-Select: Disabled"
        let copyStatusItem = NSMenuItem(
            title: copyStatusTitle,
            action: #selector(handleToggleCopyOnSelect),
            keyEquivalent: ""
        )
        copyStatusItem.target = self
        menu.addItem(copyStatusItem)
        
        let refreshItem = makeAlignedMenuItem(
            title: "Refresh Profiles & Apps",
            keyEquivalent: "r",
            modifierMask: [.command],
            action: #selector(handleRefreshProfiles),
            target: self
        )
        menu.addItem(refreshItem)
        
        let permItem = NSMenuItem(
            title: AXIsProcessTrusted() ? "Accessibility: Granted ✓" : "Accessibility: Not Granted ⚠",
            action: #selector(handleOpenAccessibilitySettings),
            keyEquivalent: ""
        )
        permItem.target = self
        menu.addItem(permItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = makeAlignedMenuItem(
            title: "Quit Quick Access",
            keyEquivalent: "q",
            modifierMask: [.command],
            action: #selector(handleQuit),
            target: self
        )
        menu.addItem(quitItem)
        
        return menu
    }
    
    @objc private func handleChangeProfileClick(_ sender: NSMenuItem) {
        guard let dir = sender.representedObject as? String else { return }
        ChromeProfileEngine.shared.toggleProfileSelection(dir: dir)
        updateMenu()
    }
    
    @objc private func handleProfileClick(_ sender: NSMenuItem) {
        guard let dir = sender.representedObject as? String else { return }
        let isOptionClick = NSEvent.modifierFlags.contains(.option)
        if isOptionClick {
            ChromeProfileEngine.shared.toggleProfileSelection(dir: dir)
        } else {
            ChromeProfileEngine.shared.selectProfile(dir: dir)
            ChromeProfileEngine.shared.focusProfile(dir: dir)
        }
        updateMenu()
    }
    
    @objc private func handleCoreAppClick(_ sender: NSMenuItem) {
        guard let bundleID = sender.representedObject as? String else { return }
        self.focusApp(bundleID: bundleID)
    }
    
    @objc private func handleChangeAppItemClick(_ sender: NSMenuItem) {
        guard let repr = sender.representedObject as? String else { return }
        let parts = repr.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return }
        let category = parts[0]
        let bundleID = parts[1]
        
        let engines = [
            AppGroupEngine.terminal,
            AppGroupEngine.aiAgent,
            AppGroupEngine.ide,
            AppGroupEngine.notes
        ]
        
        if let engine = engines.first(where: { $0.category == category }) {
            engine.select(bundleID: bundleID)
            engine.focusItem(bundleID: bundleID)
            updateDynamicShortcuts()
            updateMenu()
        }
    }
    
    @objc private func handleAppItemClick(_ sender: NSMenuItem) {
        handleCoreAppClick(sender)
    }
    
    @objc private func handleTerminalClick(_ sender: NSMenuItem) {
        handleAppItemClick(sender)
    }
    
    @objc private func handleAiAgentClick(_ sender: NSMenuItem) {
        handleAppItemClick(sender)
    }
    
    @objc private func handleAntigravityClick(_ sender: NSMenuItem) {
        handleAppItemClick(sender)
    }
    
    @objc private func handleIdeClick(_ sender: NSMenuItem) {
        handleAppItemClick(sender)
    }
    
    @objc private func handleNotesClick(_ sender: NSMenuItem) {
        handleAppItemClick(sender)
    }
    
    @objc private func handleRefreshProfiles() {
        if AXIsProcessTrusted() {
            if !CapsLockEngine.shared.isStarted {
                CapsLockEngine.shared.start()
            }
            if !CopyOnSelectEngine.shared.isStarted && CopyOnSelectEngine.shared.isEnabled {
                CopyOnSelectEngine.shared.start()
            }
        }
        ChromeProfileEngine.shared.refreshProfiles()
        AntigravityEngine.shared.refreshItems()
        AppGroupEngine.aiAgent.refreshItems()
        AppGroupEngine.terminal.refreshItems()
        AppGroupEngine.notes.refreshItems()
        AppGroupEngine.ide.refreshItems()
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
