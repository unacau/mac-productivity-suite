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
    private var cancellables = Set<AnyCancellable>()
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    
    public let workspace: WorkspaceProvider
    public let hotkeys: HotkeyProvider
    public let chromeHelper: ChromeProfileHelper
    
    public init(workspace: WorkspaceProvider, hotkeys: HotkeyProvider, chromeHelper: ChromeProfileHelper? = nil) {
        self.workspace = workspace
        self.hotkeys = hotkeys
        self.chromeHelper = chromeHelper ?? ChromeProfileHelper.shared
        
        setupBindings()
        
        NotificationCenter.default.publisher(for: NSNotification.Name("AppConfigDidChangeNotification"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupBindings()
            }
            .store(in: &cancellables)
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
            resetSingleDismissTimer()
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
        
        // If HUD is already open and key is a number 1..9, navigate directly to that item/profile
        if isVisible && !currentItems.isEmpty, let num = Int(keyLower), num >= 1, num <= 9 {
            handleNumberPress(profileIndex: num)
            return
        }
        
        let config = AppConfigManager.shared.config
        guard let apps = config.bindings[keyLower], !apps.isEmpty else { return }
        
        let items = buildSwitcherItems(for: apps)
        if items.isEmpty { return }
        
        if items.count == 1 {
            // Single target shortcut: switch immediately AND present HUD visual feedback briefly
            activeKey = keyLower
            currentItems = items
            selectedIndex = 0
            launchOrFocusTarget(items[0].name)
            showHUD()
            resetSingleDismissTimer()
            return
        }
        
        if isVisible && activeKey == keyLower && currentItems.count == items.count {
            selectedIndex = (selectedIndex + 1) % items.count
            resetDismissTimer()
        } else {
            activeKey = keyLower
            currentItems = items
            
            let frontAppName = workspace.frontmostApplicationName?.lowercased()
            if let front = frontAppName, let idx = items.firstIndex(where: { $0.displayName.lowercased() == front }) {
                selectedIndex = (idx + 1) % items.count
            } else {
                selectedIndex = lastActiveIndices[keyLower] ?? 0
                if selectedIndex >= items.count { selectedIndex = 0 }
            }
            
            showHUD()
            resetDismissTimer()
        }
    }
    
    private func resetSingleDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
            guard let engine = self else { return }
            Task { @MainActor in
                engine.hideHUDOnly()
            }
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
    
    private func resetDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { [weak self] _ in
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
        
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let engine = self else { return }
            Task { @MainActor in
                engine.handleHUDKeyDown(event: event)
            }
        }
        
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let engine = self else { return event }
            if engine.handleHUDKeyDown(event: event) {
                return nil
            }
            return event
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
