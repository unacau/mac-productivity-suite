import Cocoa
import AppKit
import UniformTypeIdentifiers
import os

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let logger = Logger(subsystem: "com.almosteleven.xomsky", category: "app")
    private var accessibilityPollTimer: Timer?
    private var appSwitchObserver: Any?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Starting Xomsky...")
        
        // 1. Setup Menu Bar Status Item
        setupStatusItem()
        
        // 2. Wire Engine Actions
        setupEngineCallbacks()
        
        // 3. Check Accessibility & Start Services
        if AXIsProcessTrusted() {
            startServices()
        } else {
            logger.warning("Accessibility permission missing on launch. Prompting user and beginning background polling...")
            promptForAccessibilityPermissions()
            startAccessibilityPolling()
        }
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        logger.info("Terminating Xomsky: cleaning up event taps and restoring HID mapping.")
        stopAccessibilityPolling()
        CapsLockEngine.shared.stop()
        CopyOnSelectEngine.shared.stop()
    }
    
    public func startServices() {
        if !CapsLockEngine.shared.isStarted {
            CapsLockEngine.shared.start()
        }
        if CopyOnSelectEngine.shared.isEnabled && !CopyOnSelectEngine.shared.isStarted {
            CopyOnSelectEngine.shared.start()
        }
        updateDynamicShortcuts()
        updateMenu()
    }
    
    private func startAccessibilityPolling() {
        guard accessibilityPollTimer == nil else { return }
        
        // Polling timer: check every 1.0s
        accessibilityPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                if AXIsProcessTrusted() {
                    self.logger.info("Accessibility permission granted via polling! Initializing services.")
                    self.stopAccessibilityPolling()
                    self.startServices()
                    ChromeProfileEngine.shared.refreshProfiles()
                    AntigravityEngine.shared.refreshItems()
                    for engine in AppGroupEngine.allEngines {
                        engine.refreshItems()
                    }
                }
            }
        }
        
        // Also listen for app activation events (e.g. user toggles setting and switches back)
        appSwitchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if AXIsProcessTrusted() && !CapsLockEngine.shared.isStarted {
                    self.logger.info("Accessibility permission granted via app switch! Initializing services.")
                    self.stopAccessibilityPolling()
                    self.startServices()
                    ChromeProfileEngine.shared.refreshProfiles()
                    AntigravityEngine.shared.refreshItems()
                    for engine in AppGroupEngine.allEngines {
                        engine.refreshItems()
                    }
                }
            }
        }
    }
    
    private func stopAccessibilityPolling() {
        accessibilityPollTimer?.invalidate()
        accessibilityPollTimer = nil
        if let observer = appSwitchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            appSwitchObserver = nil
        }
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
    
    /// Re-evaluates and binds dynamic hotkeys based strictly on the first letter of each pinned application's name.
    public func updateDynamicShortcuts() {
        let groups = AppGroupEngine.pinnedAppsGroupedByLetter()
        var triggers: [UInt32: @MainActor () -> Void] = [:]
        
        // 1. Chrome browser is 'C'
        triggers[KeyCodes.kVK_ANSI_C] = { [weak self] in
            self?.handleChromeTrigger()
        }
        
        // 2. Register every pinned letter's items
        for group in groups {
            let char = group.letter
            if char == "C" { continue } // 'C' is reserved for Chrome profile switcher
            
            if let code = KeyCodes.keyCode(for: char) {
                let items = group.items
                triggers[code] = { [weak self] in
                    self?.handleAppLetterTrigger(char: char, items: items)
                }
            }
        }
        
        CapsLockEngine.shared.dynamicKeyTriggers = triggers
        logger.info("Dynamic app shortcuts updated for pinned apps: \(groups.map { "\($0.letter): \($0.items.map { $0.name })" })")
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
        
        let icon = makeKhomyakStatusIcon()
        button.image = icon
        button.imagePosition = .imageOnly
        button.toolTip = "Xomsky — Tap the Mascot"
        
        updateMenu()
    }
    
    /// Generates a resolution-independent, full-color vector status bar icon of the Khomyak mascot
    /// featuring its signature concentric target eyes, red triangle nose, cheek lobes, and paws.
    private func makeKhomyakStatusIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let cg = NSGraphicsContext.current?.cgContext else { return false }
            
            let s = rect.width / 32.0
            cg.scaleBy(x: s, y: s)

            // Palette (Cadmium Yellow, Cream, Obsidian Dark, Vermilion Red, Pure White)
            let cYellow = NSColor(red: 0.965, green: 0.737, blue: 0.078, alpha: 1.0).cgColor // #F6BC14
            let cCream = NSColor(red: 1.0, green: 0.98, blue: 0.92, alpha: 1.0).cgColor
            let cDark = NSColor(red: 0.086, green: 0.106, blue: 0.149, alpha: 1.0).cgColor   // #161B26
            let cRed = NSColor(red: 0.902, green: 0.224, blue: 0.275, alpha: 1.0).cgColor   // #E63946
            let cWhite = NSColor.white.cgColor

            cg.setLineCap(.round)
            cg.setLineJoin(.round)

            func Y(_ y: CGFloat) -> CGFloat { 32.0 - y }

            // 1. Ears
            func drawEar(cx: CGFloat, svgY: CGFloat) {
                let cy = Y(svgY)
                cg.setFillColor(cYellow)
                cg.setStrokeColor(cDark)
                cg.setLineWidth(1.4)
                cg.addEllipse(in: CGRect(x: cx - 4.2, y: cy - 4.2, width: 8.4, height: 8.4))
                cg.drawPath(using: .fillStroke)

                cg.setFillColor(cCream)
                cg.setStrokeColor(cDark)
                cg.setLineWidth(0.8)
                cg.addEllipse(in: CGRect(x: cx - 2.2, y: cy - 2.2, width: 4.4, height: 4.4))
                cg.drawPath(using: .fillStroke)
            }
            drawEar(cx: 7.5, svgY: 7.5)
            drawEar(cx: 24.5, svgY: 7.5)

            // 2. Cheek Lobes (Backing)
            cg.setFillColor(cYellow)
            cg.setStrokeColor(cDark)
            cg.setLineWidth(1.4)
            cg.addEllipse(in: CGRect(x: 9.0 - 6.2, y: Y(16.5) - 6.2, width: 12.4, height: 12.4))
            cg.drawPath(using: .fillStroke)
            cg.addEllipse(in: CGRect(x: 23.0 - 6.2, y: Y(16.5) - 6.2, width: 12.4, height: 12.4))
            cg.drawPath(using: .fillStroke)

            // 3. Head Center Fill
            let head = CGMutablePath()
            head.move(to: CGPoint(x: 9, y: Y(10)))
            head.addCurve(to: CGPoint(x: 23, y: Y(10)), control1: CGPoint(x: 13, y: Y(8.5)), control2: CGPoint(x: 19, y: Y(8.5)))
            head.addCurve(to: CGPoint(x: 26.5, y: Y(18)), control1: CGPoint(x: 25.5, y: Y(12)), control2: CGPoint(x: 26.5, y: Y(15)))
            head.addCurve(to: CGPoint(x: 16, y: Y(22.5)), control1: CGPoint(x: 26.5, y: Y(21)), control2: CGPoint(x: 21.5, y: Y(22.5)))
            head.addCurve(to: CGPoint(x: 5.5, y: Y(18)), control1: CGPoint(x: 10.5, y: Y(22.5)), control2: CGPoint(x: 5.5, y: Y(21)))
            head.addCurve(to: CGPoint(x: 9, y: Y(10)), control1: CGPoint(x: 5.5, y: Y(15)), control2: CGPoint(x: 6.5, y: Y(12)))
            head.closeSubpath()
            cg.addPath(head)
            cg.setFillColor(cYellow)
            cg.fillPath()

            // 4. White Muzzle
            let muzzle = CGMutablePath()
            muzzle.move(to: CGPoint(x: 12.5, y: Y(9.5)))
            muzzle.addCurve(to: CGPoint(x: 10.5, y: Y(18)), control1: CGPoint(x: 12.5, y: Y(9.5)), control2: CGPoint(x: 10.5, y: Y(14)))
            muzzle.addCurve(to: CGPoint(x: 16, y: Y(22.5)), control1: CGPoint(x: 10.5, y: Y(21.5)), control2: CGPoint(x: 13, y: Y(22.5)))
            muzzle.addCurve(to: CGPoint(x: 21.5, y: Y(18)), control1: CGPoint(x: 19, y: Y(22.5)), control2: CGPoint(x: 21.5, y: Y(21.5)))
            muzzle.addCurve(to: CGPoint(x: 19.5, y: Y(9.5)), control1: CGPoint(x: 21.5, y: Y(14)), control2: CGPoint(x: 19.5, y: Y(9.5)))
            muzzle.closeSubpath()
            cg.addPath(muzzle)
            cg.setFillColor(cWhite)
            cg.fillPath()

            // 5. Signature Concentric Eyes
            func drawEye(cx: CGFloat, svgY: CGFloat, gx: CGFloat, svgGY: CGFloat) {
                let cy = Y(svgY)
                let gy = Y(svgGY)

                // Outer ring
                cg.setFillColor(cWhite)
                cg.setStrokeColor(cDark)
                cg.setLineWidth(1.3)
                cg.addEllipse(in: CGRect(x: cx - 4.2, y: cy - 4.2, width: 8.4, height: 8.4))
                cg.drawPath(using: .fillStroke)

                // Middle ring
                cg.setFillColor(cWhite)
                cg.setStrokeColor(cDark)
                cg.setLineWidth(0.9)
                cg.addEllipse(in: CGRect(x: cx - 3.0, y: cy - 3.0, width: 6.0, height: 6.0))
                cg.drawPath(using: .fillStroke)

                // Pupil
                cg.setFillColor(cDark)
                cg.addEllipse(in: CGRect(x: cx - 1.9, y: cy - 1.9, width: 3.8, height: 3.8))
                cg.fillPath()

                // Glare highlight
                cg.setFillColor(cWhite)
                cg.addEllipse(in: CGRect(x: gx - 0.7, y: gy - 0.7, width: 1.4, height: 1.4))
                cg.fillPath()
            }
            drawEye(cx: 11.2, svgY: 13.8, gx: 12.0, svgGY: 13.0)
            drawEye(cx: 20.8, svgY: 13.8, gx: 21.6, svgGY: 13.0)

            // 6. Red Inverted Triangle Nose
            let nose = CGMutablePath()
            nose.move(to: CGPoint(x: 14.1, y: Y(16.8)))
            nose.addLine(to: CGPoint(x: 17.9, y: Y(16.8)))
            nose.addLine(to: CGPoint(x: 16.0, y: Y(19.2)))
            nose.closeSubpath()
            cg.addPath(nose)
            cg.setFillColor(cRed)
            cg.setStrokeColor(cDark)
            cg.setLineWidth(0.6)
            cg.drawPath(using: .fillStroke)

            // 7. Mouth W
            let mouth = CGMutablePath()
            mouth.move(to: CGPoint(x: 13.8, y: Y(20.0)))
            mouth.addCurve(to: CGPoint(x: 16.0, y: Y(20.0)), control1: CGPoint(x: 14.6, y: Y(20.8)), control2: CGPoint(x: 15.4, y: Y(20.8)))
            mouth.addCurve(to: CGPoint(x: 18.2, y: Y(20.0)), control1: CGPoint(x: 16.6, y: Y(20.8)), control2: CGPoint(x: 17.4, y: Y(20.8)))
            cg.addPath(mouth)
            cg.setStrokeColor(cDark)
            cg.setLineWidth(1.0)
            cg.strokePath()

            // 8. Paws
            func drawPaw(cx: CGFloat, svgY: CGFloat) {
                let cy = Y(svgY)
                cg.setFillColor(cWhite)
                cg.setStrokeColor(cDark)
                cg.setLineWidth(1.1)
                cg.addEllipse(in: CGRect(x: cx - 2.5, y: cy - 2.5, width: 5.0, height: 5.0))
                cg.drawPath(using: .fillStroke)

                cg.setFillColor(cRed)
                cg.addEllipse(in: CGRect(x: cx - 0.8 - 0.35, y: cy - 1.0 - 0.35, width: 0.7, height: 0.7))
                cg.addEllipse(in: CGRect(x: cx - 0.35, y: cy - 1.3 - 0.35, width: 0.7, height: 0.7))
                cg.addEllipse(in: CGRect(x: cx + 0.8 - 0.35, y: cy - 1.0 - 0.35, width: 0.7, height: 0.7))
                cg.fillPath()
            }
            drawPaw(cx: 12.8, svgY: 22.8)
            drawPaw(cx: 19.2, svgY: 22.8)

            return true
        }
        image.isTemplate = false
        return image
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
            let small = NSImage(size: NSSize(width: 18, height: 18))
            small.lockFocus()
            icon.draw(in: NSRect(x: 0, y: 0, width: 18, height: 18))
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
        
        // 1. Chrome / Browser section (caps lock + C)
        let browserName = profileEngine.activeBrowserName
        let chromeIcon: NSImage
        if let candidate = ChromeProfileEngine.supportedBrowsers.first(where: { $0.bundleID == profileEngine.browserBundleID }),
           let appIcon = NSWorkspace.shared.icon(forFile: candidate.appPath) as NSImage? {
            chromeIcon = appIcon
        } else if let appIcon = NSWorkspace.shared.icon(forFile: "/Applications/Google Chrome.app") as NSImage? {
            chromeIcon = appIcon
        } else if let firstAvatar = profileEngine.profiles.first?.avatarImage {
            chromeIcon = firstAvatar
        } else {
            chromeIcon = NSImage(systemSymbolName: "globe", accessibilityDescription: nil) ?? NSImage()
        }
        
        let browserTitle = profileEngine.browserBundleID == "com.google.Chrome" ? "Chrome (Caps-Lock + C)" : "\(browserName) (Caps-Lock + C)"
        let chromeHeader = makeAlignedMenuItem(
            title: browserTitle,
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
        
        // 2. Quick Apps section (Caps-Lock)
        let quickAppsIcon = NSImage(systemSymbolName: "square.grid.2x2.fill", accessibilityDescription: nil)
            ?? NSImage(systemSymbolName: "wrench.and.screwdriver.fill", accessibilityDescription: nil)
            ?? NSImage()
        let quickAppsHeader = makeAlignedMenuItem(
            title: "Quick Apps (Caps-Lock)",
            isHeader: true,
            icon: quickAppsIcon,
            action: nil,
            target: nil
        )
        quickAppsHeader.isEnabled = false
        menu.addItem(quickAppsHeader)
        
        let pinnedGroups = AppGroupEngine.pinnedAppsGroupedByLetter()
        for group in pinnedGroups {
            let char = group.letter
            let charStr = String(char).lowercased()
            
            if group.items.count == 1 {
                let item = group.items[0]
                let rowItem = makeAlignedMenuItem(
                    title: item.name,
                    keyEquivalent: charStr,
                    icon: item.icon,
                    action: #selector(handleCoreAppClick(_:)),
                    target: self,
                    representedObject: item.bundleID
                )
                menu.addItem(rowItem)
            } else {
                let firstName = group.items.first?.name ?? "App"
                let title = "\(firstName) (\(char) • \(group.items.count) apps)"
                let firstIcon = group.items.first?.icon
                let rowItem = makeAlignedMenuItem(
                    title: title,
                    keyEquivalent: "",
                    icon: firstIcon,
                    action: nil,
                    target: nil
                )
                
                let cycleSubmenu = NSMenu(title: title)
                let header = NSMenuItem(title: "Caps-Lock + \(char) to cycle:", action: nil, keyEquivalent: "")
                header.attributedTitle = NSAttributedString(
                    string: "Caps-Lock + \(char) to cycle:",
                    attributes: [.font: NSFont.boldSystemFont(ofSize: 11)]
                )
                header.isEnabled = false
                cycleSubmenu.addItem(header)
                
                for item in group.items {
                    let subItem = makeAlignedMenuItem(
                        title: item.name,
                        icon: item.icon,
                        action: #selector(handleCoreAppClick(_:)),
                        target: self,
                        representedObject: item.bundleID
                    )
                    cycleSubmenu.addItem(subItem)
                }
                
                rowItem.submenu = cycleSubmenu
                menu.addItem(rowItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Change App submenu
        let changeAppItem = NSMenuItem(title: "Change App", action: nil, keyEquivalent: "")
        let changeAppSubmenu = NSMenu(title: "Change App")
        
        let transparentOffImage = NSImage(size: NSSize(width: 14, height: 14))
        
        // 3a. Active Browser Selection (when multiple browsers available)
        if profileEngine.availableBrowsers.count > 1 {
            let browserCatHeader = NSMenuItem(title: "Active Browser:", action: nil, keyEquivalent: "")
            browserCatHeader.attributedTitle = NSAttributedString(
                string: "Active Browser:",
                attributes: [.font: NSFont.boldSystemFont(ofSize: 11)]
            )
            browserCatHeader.isEnabled = false
            changeAppSubmenu.addItem(browserCatHeader)
            
            for b in profileEngine.availableBrowsers {
                let isCurrent = profileEngine.browserBundleID == b.bundleID
                let bItem = makeAlignedMenuItem(
                    title: b.name,
                    icon: NSWorkspace.shared.icon(forFile: b.appPath),
                    action: #selector(handleSelectBrowserClick(_:)),
                    target: self,
                    representedObject: b.bundleID
                )
                bItem.state = isCurrent ? .on : .off
                if !isCurrent {
                    bItem.offStateImage = transparentOffImage
                }
                changeAppSubmenu.addItem(bItem)
            }
            changeAppSubmenu.addItem(NSMenuItem.separator())
        }
        
        // 3b. Chrome / Browser Profiles in Change App
        let chromeCatHeader = NSMenuItem(title: "\(profileEngine.activeBrowserName) Profiles (up to 4):", action: nil, keyEquivalent: "")
        chromeCatHeader.attributedTitle = NSAttributedString(
            string: "\(profileEngine.activeBrowserName) Profiles (up to 4):",
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
            changeAppSubmenu.addItem(pItem)
        }
        
        // 3c. Pinned Quick Apps Header
        changeAppSubmenu.addItem(NSMenuItem.separator())
        let pinnedItems = AppGroupEngine.pinnedAppItems()
        let pinnedTitle = LicenseEngine.shared.isPro ? "Pinned Quick Apps (\(pinnedItems.count)):" : "Pinned Quick Apps (up to 4):"
        let pinnedHeader = NSMenuItem(title: pinnedTitle, action: nil, keyEquivalent: "")
        pinnedHeader.attributedTitle = NSAttributedString(
            string: pinnedTitle,
            attributes: [.font: NSFont.boldSystemFont(ofSize: 11)]
        )
        pinnedHeader.isEnabled = false
        changeAppSubmenu.addItem(pinnedHeader)
        
        for item in pinnedItems {
            let char = Character((item.name.first(where: { $0.isLetter }) ?? "A").uppercased())
            let pItem = makeAlignedMenuItem(
                title: "\(item.name) (\(char))",
                keyEquivalent: String(char).lowercased(),
                icon: item.icon,
                action: #selector(handleUnpinAppClick(_:)),
                target: self,
                representedObject: item.bundleID
            )
            pItem.state = .on
            changeAppSubmenu.addItem(pItem)
        }
        
        // 3d. Catalog Categories in Change App
        let catalogCategories = AppGroupEngine.catalogCategories
        for cat in catalogCategories {
            changeAppSubmenu.addItem(NSMenuItem.separator())
            
            let catHeader = NSMenuItem(title: "\(cat.category):", action: nil, keyEquivalent: "")
            catHeader.attributedTitle = NSAttributedString(
                string: "\(cat.category):",
                attributes: [.font: NSFont.boldSystemFont(ofSize: 11)]
            )
            catHeader.isEnabled = false
            changeAppSubmenu.addItem(catHeader)
            
            for item in cat.items {
                let isPinned = AppGroupEngine.isAppSelected(bundleID: item.bundleID)
                let char = Character((item.name.first(where: { $0.isLetter }) ?? "A").uppercased())
                let menuItem = makeAlignedMenuItem(
                    title: item.name,
                    keyEquivalent: String(char).lowercased(),
                    icon: item.icon,
                    action: #selector(handleTogglePinAppClick(_:)),
                    target: self,
                    representedObject: item.bundleID
                )
                menuItem.state = isPinned ? .on : .off
                if !isPinned {
                    menuItem.offStateImage = transparentOffImage
                }
                changeAppSubmenu.addItem(menuItem)
            }
        }
        
        // 3e. Choose Other App...
        changeAppSubmenu.addItem(NSMenuItem.separator())
        let customAppItem = makeAlignedMenuItem(
            title: "Choose Other App...",
            keyEquivalent: "o",
            modifierMask: [.command],
            action: #selector(handleChooseOtherApp),
            target: self
        )
        changeAppSubmenu.addItem(customAppItem)
        
        changeAppItem.submenu = changeAppSubmenu
        menu.addItem(changeAppItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. Utility & Pro items
        let proItem: NSMenuItem
        if LicenseEngine.shared.isPro {
            proItem = makeAlignedMenuItem(
                title: "Xomsky Pro: Active ✓",
                icon: NSImage(systemSymbolName: "checkmark.seal.fill", accessibilityDescription: nil),
                action: #selector(handleManageLicense),
                target: self
            )
            menu.addItem(proItem)
        } else {
            proItem = makeAlignedMenuItem(
                title: "Upgrade to Xomsky Pro (\(LicenseEngine.proPrice))...",
                icon: NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil),
                action: #selector(handleUpgradeToPro),
                target: self
            )
            menu.addItem(proItem)
            
            let enterKeyItem = makeAlignedMenuItem(
                title: "Enter License Key...",
                icon: NSImage(systemSymbolName: "key.fill", accessibilityDescription: nil),
                action: #selector(handleEnterLicenseKeyFromMenu),
                target: self
            )
            menu.addItem(enterKeyItem)
        }
        
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
            title: "Quit Xomsky",
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
        let profileEngine = ChromeProfileEngine.shared
        if profileEngine.isProfileSelected(dir: dir) {
            profileEngine.deselectProfile(dir: dir)
            updateMenu()
        } else {
            if profileEngine.selectedProfiles.count < 4 {
                profileEngine.selectProfile(dir: dir)
                updateMenu()
            } else {
                promptProfileReplacement(newDir: dir)
            }
        }
    }
    
    private func promptProfileReplacement(newDir: String) {
        let profileEngine = ChromeProfileEngine.shared
        let newProfileName = profileEngine.profiles.first(where: { $0.dir == newDir })?.effectiveName ?? newDir
        
        let alert = NSAlert()
        alert.messageText = "Chrome Profiles Limit Reached (4 of 4)"
        alert.informativeText = "Xomsky supports up to 4 quick profiles (Caps + 1..4).\n\nAll 4 profile slots are currently in use. Choose which profile slot to replace with '\(newProfileName)':"
        alert.alertStyle = .informational
        
        let popUp = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 26))
        for p in profileEngine.selectedProfiles {
            popUp.addItem(withTitle: "Slot \(p.index): \(p.effectiveName)")
            popUp.lastItem?.representedObject = p.dir
            if let avatar = p.avatarImage?.copy() as? NSImage {
                avatar.size = NSSize(width: 16, height: 16)
                popUp.lastItem?.image = avatar
            }
        }
        alert.accessoryView = popUp
        
        alert.addButton(withTitle: "Replace Profile")
        alert.addButton(withTitle: "Cancel")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.window.level = .floating
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let oldDir = popUp.selectedItem?.representedObject as? String {
                profileEngine.replaceProfile(oldDir: oldDir, newDir: newDir)
                updateMenu()
            }
        }
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
    
    @objc private func handleMultiAppCycleClick(_ sender: NSMenuItem) {
        guard let repr = sender.representedObject as? String else { return }
        let bundleIDs = repr.split(separator: ",").map(String.init)
        guard let first = bundleIDs.first else { return }
        self.focusApp(bundleID: first)
    }
    
    @objc private func handleUnpinAppClick(_ sender: NSMenuItem) {
        guard let bundleID = sender.representedObject as? String else { return }
        AppGroupEngine.deselectApp(bundleID: bundleID)
        updateDynamicShortcuts()
        updateMenu()
    }
    
    @objc private func handleTogglePinAppClick(_ sender: NSMenuItem) {
        guard let bundleID = sender.representedObject as? String else { return }
        if AppGroupEngine.isAppSelected(bundleID: bundleID) {
            AppGroupEngine.deselectApp(bundleID: bundleID)
            updateDynamicShortcuts()
            updateMenu()
        } else {
            if AppGroupEngine.canPinMoreApps {
                AppGroupEngine.selectApp(bundleID: bundleID)
                updateDynamicShortcuts()
                updateMenu()
            } else {
                promptAppReplacement(newBundleID: bundleID)
            }
        }
    }
    
    @objc private func handleSelectBrowserClick(_ sender: NSMenuItem) {
        guard let bundleID = sender.representedObject as? String else { return }
        ChromeProfileEngine.shared.selectBrowser(bundleID: bundleID)
        updateMenu()
    }
    
    @objc private func handleUpgradeToPro() {
        if let url = URL(string: LicenseEngine.polarCheckoutUrl) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func handleEnterLicenseKeyFromMenu() {
        promptEnterLicenseKey()
    }
    
    @objc private func handleManageLicense() {
        let alert = NSAlert()
        alert.messageText = "Xomsky Pro Active"
        let keyText = LicenseEngine.shared.activeLicenseKey ?? "Activated via License"
        alert.informativeText = "Status: Pro (\(LicenseEngine.proPrice))\nLicense Key: \(keyText)\n\nYou have unlocked unlimited Quick App slots!"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Deactivate License")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.window.level = .floating
        if alert.runModal() == .alertSecondButtonReturn {
            LicenseEngine.shared.deactivate()
            updateDynamicShortcuts()
            updateMenu()
        }
    }
    
    private func promptEnterLicenseKey(thenPinBundleID: String? = nil) {
        let alert = NSAlert()
        alert.messageText = "Enter Xomsky Pro License Key"
        alert.informativeText = "Please enter your license key to unlock unlimited slots:"
        alert.alertStyle = .informational
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        input.placeholderString = "XOMSKY-PRO-XXXX-XXXX"
        alert.accessoryView = input
        
        alert.addButton(withTitle: "Activate")
        alert.addButton(withTitle: "Cancel")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.window.level = .floating
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let key = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return }
            
            // 1. Offline master key fast-path: activates immediately in 0ms without network
            if LicenseEngine.isOfflineMasterKey(key) {
                if LicenseEngine.shared.activate(key: key) {
                    showActivationSuccess(thenPinBundleID: thenPinBundleID)
                } else {
                    showActivationError(message: "The offline master key provided could not be activated.")
                }
                return
            }
            
            // 2. Key format validation check before making network calls
            guard LicenseEngine.shared.validateLicenseKey(key) else {
                showActivationError(message: "Invalid license key format. Xomsky license keys start with 'XOMSKY-'.")
                return
            }
            
            // 3. Online Polar activation via async Task on MainActor
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let result = await LicenseEngine.shared.activateOnlineDetailed(key: key)
                switch result {
                case .success:
                    self.showActivationSuccess(thenPinBundleID: thenPinBundleID)
                case .invalidKey(let msg):
                    self.showActivationError(message: msg)
                case .activationLimitReached:
                    self.showActivationError(message: "This license key has reached its maximum number of activated devices. Please deactivate another device or contact support.")
                case .networkError(let msg):
                    self.showActivationError(message: "Could not connect to the Polar license server. Please check your internet connection and try again.\n\nDetails: \(msg)")
                }
            }
        }
    }
    
    private func showActivationSuccess(thenPinBundleID: String?) {
        let successAlert = NSAlert()
        successAlert.messageText = "Xomsky Pro Activated!"
        successAlert.informativeText = "Thank you for supporting independent software development. You now have unlimited Quick App slots!"
        successAlert.alertStyle = .informational
        successAlert.addButton(withTitle: "OK")
        successAlert.runModal()
        
        if let pinID = thenPinBundleID {
            AppGroupEngine.selectApp(bundleID: pinID)
        }
        updateDynamicShortcuts()
        updateMenu()
    }
    
    private func showActivationError(message: String) {
        let errorAlert = NSAlert()
        errorAlert.messageText = "Activation Failed"
        errorAlert.informativeText = message
        errorAlert.alertStyle = .warning
        errorAlert.addButton(withTitle: "OK")
        errorAlert.runModal()
    }
    
    private func promptAppReplacement(newBundleID: String) {
        let allDiscovered = AppGroupEngine.allDiscoveredItems()
        let newAppName = allDiscovered.first(where: { $0.bundleID == newBundleID })?.name
            ?? (Bundle(identifier: newBundleID)?.infoDictionary?["CFBundleName"] as? String)
            ?? newBundleID
        
        let alert = NSAlert()
        alert.messageText = "Free Tier Slot Limit Reached (5 of 5 Slots)"
        alert.informativeText = "Xomsky Free includes 5 quick slots (1 Browser Hub + 4 Pinned Apps).\n\nSlots 6 and beyond require Xomsky Pro (\(LicenseEngine.proPrice)).\n\nYou can replace an existing pinned slot or upgrade to Xomsky Pro for unlimited quick app slots:"
        alert.alertStyle = .informational
        
        let popUp = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 26))
        let currentPinned = AppGroupEngine.pinnedAppItems()
        for item in currentPinned {
            let char = item.name.first(where: { $0.isLetter })?.uppercased() ?? "A"
            popUp.addItem(withTitle: "\(item.name) (Caps + \(char))")
            popUp.lastItem?.representedObject = item.bundleID
            if let icon = item.icon.copy() as? NSImage {
                icon.size = NSSize(width: 16, height: 16)
                popUp.lastItem?.image = icon
            }
        }
        alert.accessoryView = popUp
        
        alert.addButton(withTitle: "Replace App")
        alert.addButton(withTitle: "Upgrade to Pro (\(LicenseEngine.proPrice))")
        alert.addButton(withTitle: "Enter License Key...")
        alert.addButton(withTitle: "Cancel")
        
        NSApp.activate(ignoringOtherApps: true)
        alert.window.level = .floating
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let oldBundleID = popUp.selectedItem?.representedObject as? String {
                let oldName = popUp.selectedItem?.title ?? oldBundleID
                logger.info("User explicitly replaced '\(oldName)' with '\(newAppName)'.")
                AppGroupEngine.replaceApp(oldBundleID: oldBundleID, newBundleID: newBundleID)
                updateDynamicShortcuts()
                updateMenu()
            }
        } else if response == .alertSecondButtonReturn {
            handleUpgradeToPro()
        } else if response == .alertThirdButtonReturn {
            promptEnterLicenseKey(thenPinBundleID: newBundleID)
        }
    }
    
    @objc private func handleChooseOtherApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Pin App"
        panel.message = "Choose an application to pin to Xomsky Quick Apps:"
        
        NSApp.activate(ignoringOtherApps: true)
        panel.level = .floating
        if panel.runModal() == .OK, let url = panel.url {
            if let item = AppGroupEngine.registerCustomApp(url: url) {
                if AppGroupEngine.isAppSelected(bundleID: item.bundleID) {
                    return
                }
                if AppGroupEngine.canPinMoreApps {
                    AppGroupEngine.selectApp(bundleID: item.bundleID)
                    updateDynamicShortcuts()
                    updateMenu()
                } else {
                    promptAppReplacement(newBundleID: item.bundleID)
                }
            }
        }
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
        for engine in AppGroupEngine.allEngines {
            engine.refreshItems()
        }
        updateDynamicShortcuts()
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
