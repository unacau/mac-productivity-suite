import Cocoa
import AppKit
import SwiftUI
import Combine

public struct AppSwitcherItem: Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public let displayName: String
    public let icon: NSImage
    public var isChromeProfile: Bool = false
    public var profileDir: String? = nil
    public var profileIndex: Int? = nil
    public var badge: String? = nil
    
    public init(name: String, displayName: String, icon: NSImage, isChromeProfile: Bool = false, profileDir: String? = nil, profileIndex: Int? = nil, badge: String? = nil) {
        self.name = name
        self.displayName = displayName
        self.icon = icon
        self.isChromeProfile = isChromeProfile
        self.profileDir = profileDir
        self.profileIndex = profileIndex
        self.badge = badge
    }
}

@MainActor
public final class AppSwitcherEngine: ObservableObject {
    public static var shared = AppSwitcherEngine(
        workspace: SystemWorkspaceProvider(),
        hotkeys: SystemHotkeyProvider(manager: HotkeyManager.shared)
    )
    
    @Published public var isVisible: Bool = false
    @Published public var currentItems: [AppSwitcherItem] = []
    @Published public var selectedIndex: Int = 0
    
    private var dismissTimer: Timer?
    private var activeKey: String?
    private var lastActiveIndices: [String: Int] = [:]
    private var lastKeyPressTime: DispatchTime = DispatchTime(uptimeNanoseconds: 0)
    private var lastPressedKey: String = ""
    private var cancellables = Set<AnyCancellable>()
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    
    public let workspace: WorkspaceProvider
    public let hotkeys: HotkeyProvider
    public let process: ProcessProvider
    public let chromeHelper: ChromeProfileHelper
    
    public init(workspace: WorkspaceProvider = SystemWorkspaceProvider(),
                hotkeys: HotkeyProvider? = nil,
                process: ProcessProvider = SystemProcessProvider(),
                chromeHelper: ChromeProfileHelper? = nil) {
        let hotkeys = hotkeys ?? SystemHotkeyProvider(manager: HotkeyManager.shared)
        self.workspace = workspace
        self.hotkeys = hotkeys
        self.process = process
        self.chromeHelper = chromeHelper ?? ChromeProfileHelper.shared
        
        setupBindings()
        setupHyperKeyIntegration()
        setupActiveAppWatcher()
        
        NotificationCenter.default.publisher(for: NSNotification.Name("AppConfigDidChangeNotification"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupBindings()
            }
            .store(in: &cancellables)
    }
    
    private func setupActiveAppWatcher() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let appName = app.localizedName?.lowercased() else { return }
            
            Task { @MainActor [weak self] in
                guard let engine = self else { return }
                let config = AppConfigManager.shared.config
                for (key, candidates) in config.bindings {
                    if candidates.count > 1 {
                        for (idx, target) in candidates.enumerated() {
                            let lowerTarget = target.lowercased()
                            if appName == lowerTarget || appName.contains(lowerTarget) || lowerTarget.contains(appName) {
                                engine.lastActiveIndices[key.lowercased()] = idx
                                break
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func setupHyperKeyIntegration() {
        HyperKeyEngine.shared.keyBindingHandler = { [weak self] key in
            guard let engine = self else { return false }
            let keyLower = key.lowercased()
            let config = AppConfigManager.shared.config
            
            if let num = Int(keyLower), num >= 1, num <= 9 {
                if engine.isVisible || config.autoDiscoverChromeProfiles || config.bindings[keyLower] != nil {
                    engine.handleKeyPress(key: keyLower)
                    return true
                }
            }
            
            if config.bindings[keyLower] != nil {
                engine.handleKeyPress(key: keyLower)
                return true
            }
            
            return false
        }
    }
    
    public func setupBindings() {
        hotkeys.unregisterAll()
        
        let config = AppConfigManager.shared.config
        let modifiers = KeyCodes.hyperModifiers // Always use Caps Lock (Hyper)
        
        for (key, apps) in config.bindings {
            guard let keyCode = KeyCodes.keyCode(for: key), !apps.isEmpty else { continue }
            
            let keyStr = key.lowercased()
            _ = hotkeys.register(keyCode: keyCode, modifiers: modifiers) { [weak self] in
                guard let engine = self else { return }
                Task { @MainActor in
                    engine.handleKeyPress(key: keyStr)
                }
            }
        }
        
        // Bind Browser Profile Shortcuts (1..9) automatically if enabled
        if config.autoDiscoverChromeProfiles {
            let numberKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
            for (idx, numStr) in numberKeys.enumerated() {
                guard let keyCode = KeyCodes.keyCode(for: numStr) else { continue }
                let profileIndex = idx + 1
                
                // If user explicitly bound this number in config.bindings, let that take precedence unless HUD is open
                if config.bindings[numStr] != nil {
                    continue
                }
                
                _ = hotkeys.register(keyCode: keyCode, modifiers: modifiers) { [weak self] in
                    guard let engine = self else { return }
                    Task { @MainActor in
                        engine.handleNumberPress(profileIndex: profileIndex)
                    }
                }
            }
        }
        
        AppLogger.getLogger(category: .engine).info("Registered \(config.bindings.count) app shortcut bindings using Hyper Key.")
    }
    
    public func handleNumberPress(profileIndex: Int) {
        if isVisible && !currentItems.isEmpty {
            // Priority 1: Match by 1-based card position in HUD (1 selects 1st card, 2 selects 2nd card, etc.)
            let targetIdx = profileIndex - 1
            if targetIdx >= 0 && targetIdx < currentItems.count {
                selectedIndex = targetIdx
                resetDismissTimer()
                return
            }
            // Priority 2: Match by explicit profileIndex if outside direct card count bounds
            if let matchIdx = currentItems.firstIndex(where: { $0.profileIndex == profileIndex }) {
                selectedIndex = matchIdx
                resetDismissTimer()
                return
            }
        }
        
        // If HUD is not currently visible, handle direct Hyper + [1..9] shortcut
        if let p = chromeHelper.profiles.first(where: { $0.index == profileIndex }) {
            let item = AppSwitcherItem(
                name: "chrome-profile:\(p.dir)",
                displayName: p.name,
                icon: p.avatarImage ?? AppDiscoveryService.shared.iconForApp(nameOrBundle: "Google Chrome"),
                isChromeProfile: true,
                profileDir: p.dir,
                profileIndex: p.index,
                badge: "Chrome"
            )
            activeKey = String(profileIndex)
            currentItems = [item]
            selectedIndex = 0
            launchOrFocusTarget(item.name)
            showHUD()
            resetDismissTimer()
        } else {
            chromeHelper.focusProfile(index: profileIndex)
        }
    }
    
    public func buildSwitcherItems(for apps: [String]) -> [AppSwitcherItem] {
        var items: [AppSwitcherItem] = []
        let isSoleChrome = (apps.count == 1 && (apps[0] == "Google Chrome" || apps[0] == "Chrome"))
        
        if isSoleChrome && !chromeHelper.profiles.isEmpty {
            for (idx, profile) in chromeHelper.profiles.enumerated() {
                let icon = profile.avatarImage ?? AppDiscoveryService.shared.iconForApp(nameOrBundle: "Google Chrome")
                items.append(AppSwitcherItem(
                    name: "chrome-profile:\(profile.dir)",
                    displayName: profile.name,
                    icon: icon,
                    isChromeProfile: true,
                    profileDir: profile.dir,
                    profileIndex: idx + 1,
                    badge: "Chrome"
                ))
            }
            return items
        }
        
        let hasExplicitProfiles = apps.contains(where: { $0.hasPrefix("chrome-profile:") })
        
        for target in apps {
            if (target == "Google Chrome" || target == "Chrome") && hasExplicitProfiles {
                // Skip redundant generic Chrome card when explicit profiles are present
                continue
            }
            
            if target.hasPrefix("chrome-profile:") {
                let dir = String(target.dropFirst("chrome-profile:".count))
                let profile = chromeHelper.profiles.first(where: { $0.dir == dir })
                let displayName = profile?.name ?? "Profile (\(dir))"
                let icon = profile?.avatarImage ?? AppDiscoveryService.shared.iconForApp(nameOrBundle: "Google Chrome")
                
                items.append(AppSwitcherItem(
                    name: target,
                    displayName: displayName,
                    icon: icon,
                    isChromeProfile: true,
                    profileDir: dir,
                    profileIndex: profile?.index,
                    badge: "Chrome"
                ))
            } else {
                let icon = AppDiscoveryService.shared.iconForApp(nameOrBundle: target)
                items.append(AppSwitcherItem(name: target, displayName: target, icon: icon))
            }
        }
        
        return items
    }
    
    public func handleKeyPress(key: String) {
        let keyLower = key.lowercased()
        let now = DispatchTime.now()
        let elapsedMs = Double(now.uptimeNanoseconds - lastKeyPressTime.uptimeNanoseconds) / 1_000_000.0
        
        // Prevent duplicate calls for the same key within 35ms (e.g. from simultaneous CGEventTap and Carbon Hotkey)
        if keyLower == lastPressedKey && elapsedMs < 35.0 {
            return
        }
        lastKeyPressTime = now
        lastPressedKey = keyLower
        
        // If HUD is already open and key is a number 1..9, navigate directly to that item/profile
        if isVisible && !currentItems.isEmpty, let num = Int(keyLower), num >= 1, num <= 9 {
            handleNumberPress(profileIndex: num)
            return
        }
        
        let config = AppConfigManager.shared.config
        guard let apps = config.bindings[keyLower], !apps.isEmpty else { return }
        
        let items = buildSwitcherItems(for: apps)
        if items.isEmpty { return }
        
        if isVisible && activeKey == keyLower && currentItems.count == items.count {
            if items.count > 1 {
                selectedIndex = (selectedIndex + 1) % items.count
            }
            resetDismissTimer()
        } else {
            activeKey = keyLower
            
            let frontAppName = workspace.frontmostApplicationName?.lowercased()
            var matchedIndex: Int? = nil
            
            if let front = frontAppName {
                // Pass 1: Exact name or displayName match
                if let idx = items.firstIndex(where: {
                    $0.displayName.lowercased() == front || $0.name.lowercased() == front
                }) {
                    matchedIndex = idx
                }
                
                // Pass 2: Substring matching (e.g. "Google Chrome" contains "Chrome", or "iTerm2" vs "iTerm")
                if matchedIndex == nil {
                    if let idx = items.firstIndex(where: {
                        let nameLower = $0.name.lowercased()
                        let displayLower = $0.displayName.lowercased()
                        return front.contains(nameLower) || nameLower.contains(front) ||
                               front.contains(displayLower) || displayLower.contains(front)
                    }) {
                        matchedIndex = idx
                    }
                }
            }
            
            let targetIndex: Int
            if items.count == 1 {
                targetIndex = 0
            } else if let matched = matchedIndex {
                // Focused window IS in the same shortcut group: select NEXT candidate (think of Cmd+Tab)
                targetIndex = (matched + 1) % items.count
            } else if let lastIdx = lastActiveIndices[keyLower], lastIdx < items.count {
                // Focused window is OTHER than pressed shortcut: select PREVIOUSLY focused candidate
                targetIndex = lastIdx
            } else {
                // Find first candidate that is running or discovered on disk
                let firstAvailable = items.firstIndex(where: { it in
                    if it.isChromeProfile { return true }
                    if workspace.runningApps.contains(where: { $0.localizedName?.lowercased() == it.displayName.lowercased() }) {
                        return true
                    }
                    return AppDiscoveryService.shared.findApp(nameOrBundle: it.name) != nil
                })
                targetIndex = firstAvailable ?? 0
            }
            
            // Atomically update selectedIndex and items BEFORE displaying HUD so it appears already on the target
            self.selectedIndex = targetIndex
            self.currentItems = items
            
            showHUD()
            resetDismissTimer()
        }
    }
    
    public func hideHUDOnly() {
        stopEventMonitoring()
        dismissTimer?.invalidate()
        dismissTimer = nil
        isVisible = false
        activeKey = nil
        HUDOverlayWindow.shared.hide()
    }
    
    public func selectNext() {
        guard isVisible, !currentItems.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % currentItems.count
        resetDismissTimer()
    }
    
    public func selectPrevious() {
        guard isVisible, !currentItems.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + currentItems.count) % currentItems.count
        resetDismissTimer()
    }
    
    public var isHyperModifierHeld: Bool {
        if HyperKeyEngine.shared.isHyperActive { return true }
        
        // 1. Direct hardware HID query for F18 (remapped Caps Lock)
        if CGEventSource.keyState(.hidSystemState, key: CGKeyCode(KeyCodes.kVK_F18)) {
            return true
        }
        
        // 2. Direct hardware HID query for physical Caps Lock
        if CGEventSource.keyState(.hidSystemState, key: 57) {
            return true
        }
        
        // 3. Direct hardware HID query for Hyper combination flags (Cmd + Opt + Ctrl + Shift)
        let hidFlags = CGEventSource.flagsState(.hidSystemState)
        let hyperMask: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift]
        if hidFlags.contains(hyperMask) {
            return true
        }
        
        // 4. Cocoa NSEvent modifier flags fallback
        let flags = NSEvent.modifierFlags
        let required: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
        return flags.isSuperset(of: required)
    }
    
    private func resetDismissTimer() {
        dismissTimer?.invalidate()
        // If Hyper key is held down (Caps Lock or Cmd+Opt+Ctrl+Shift), DO NOT auto-dismiss! Keep HUD open until user releases Hyper key.
        if isHyperModifierHeld {
            dismissTimer = nil
            return
        }
        // Fallback safety timeout if triggered without holding Hyper key
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let engine = self else { return }
            Task { @MainActor in
                engine.commitAndHide()
            }
        }
    }
    
    public func commitAndHide() {
        stopEventMonitoring()
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        if isVisible && !currentItems.isEmpty {
            let selected = currentItems[selectedIndex]
            if let key = activeKey {
                lastActiveIndices[key] = selectedIndex
            }
            launchOrFocusTarget(selected.name)
        }
        
        isVisible = false
        activeKey = nil
        HUDOverlayWindow.shared.hide()
    }
    
    private func showHUD() {
        isVisible = true
        startEventMonitoring()
        HUDOverlayWindow.shared.show()
    }
    
    private func startEventMonitoring() {
        stopEventMonitoring()
        
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let engine = self else { return }
            Task { @MainActor in
                if event.type == .flagsChanged {
                    engine.handleFlagsChanged(event: event)
                } else {
                    engine.handleHUDKeyDown(event: event)
                }
            }
        }
        
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let engine = self else { return event }
            if event.type == .flagsChanged {
                engine.handleFlagsChanged(event: event)
                return event
            }
            if engine.handleHUDKeyDown(event: event) {
                return nil
            }
            return event
        }
    }
    
    private func handleFlagsChanged(event: NSEvent) {
        guard isVisible, !currentItems.isEmpty else { return }
        if !isHyperModifierHeld {
            commitAndHide()
        }
    }
    
    private func stopEventMonitoring() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
    
    @discardableResult
    private func handleHUDKeyDown(event: NSEvent) -> Bool {
        guard isVisible && !currentItems.isEmpty else { return false }
        
        // 1. Direct number key presses (1..9 and numpad 1..9)
        if let chars = event.charactersIgnoringModifiers, let first = chars.first, let num = Int(String(first)), num >= 1, num <= 9 {
            handleNumberPress(profileIndex: num)
            return true
        }
        
        // 2. Navigation, commit, and cancel keys
        switch event.keyCode {
        case 0x7B, 0x7E: // Left Arrow, Up Arrow
            selectedIndex = (selectedIndex - 1 + currentItems.count) % currentItems.count
            resetDismissTimer()
            return true
        case 0x7C, 0x7D: // Right Arrow, Down Arrow
            selectedIndex = (selectedIndex + 1) % currentItems.count
            resetDismissTimer()
            return true
        case 0x30: // Tab / Shift+Tab
            if event.modifierFlags.contains(.shift) {
                selectedIndex = (selectedIndex - 1 + currentItems.count) % currentItems.count
            } else {
                selectedIndex = (selectedIndex + 1) % currentItems.count
            }
            resetDismissTimer()
            return true
        case 0x24, 0x4C, 0x31: // Return, Keypad Enter, Space
            commitAndHide()
            return true
        case 0x35: // Escape
            hideHUDOnly()
            return true
        default:
            return false
        }
    }
    
    public func launchOrFocusTarget(_ target: String) {
        if target.hasPrefix("chrome-profile:") {
            let dir = String(target.dropFirst("chrome-profile:".count))
            chromeHelper.focusProfile(dir: dir)
            return
        }
        
        let nameOrCandidate = target
        
        // Finder is a perpetual macOS system daemon that is always "running".
        // Calling NSRunningApplication.activate() only highlights the menu bar and does NOT open a window if none is open.
        // Using `open -a Finder` forces LaunchServices to both activate Finder and present an open Finder window.
        if nameOrCandidate.lowercased() == "finder" {
            workspace.fallbackOpen(nameOrCandidate: "Finder")
            return
        }
        
        let running = workspace.runningApps
        if let app = running.first(where: {
            $0.localizedName?.lowercased() == nameOrCandidate.lowercased() ||
            $0.bundleIdentifier?.lowercased() == nameOrCandidate.lowercased() ||
            $0.bundleIdentifier?.lowercased().contains(nameOrCandidate.lowercased()) == true
        }) {
            app.activateApp()
            return
        }
        
        if let discovered = AppDiscoveryService.shared.findApp(nameOrBundle: nameOrCandidate) {
            let url = URL(fileURLWithPath: discovered.path)
            workspace.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            return
        }
        
        workspace.fallbackOpen(nameOrCandidate: nameOrCandidate)
    }
}
