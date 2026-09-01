import Cocoa
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
    
    public let workspace: WorkspaceProvider
    public let hotkeys: HotkeyProvider
    
    public init(workspace: WorkspaceProvider, hotkeys: HotkeyProvider) {
        self.workspace = workspace
        self.hotkeys = hotkeys
        
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
            hotkeys.register(keyCode: keyCode, modifiers: modifiers) { [weak self] in
                Task { @MainActor in
                    self?.handleKeyPress(key: keyStr)
                }
            }
        }
        
        // Bind Browser Profile Shortcuts (1..9) automatically if enabled
        if config.autoDiscoverChromeProfiles {
            let numberKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
            for (idx, numStr) in numberKeys.enumerated() {
                guard let keyCode = KeyCodes.keyCode(for: numStr) else { continue }
                let profileIndex = idx + 1
                
                hotkeys.register(keyCode: keyCode, modifiers: modifiers) {
                    Task { @MainActor in
                        ChromeProfileHelper.shared.focusProfile(index: profileIndex)
                    }
                }
            }
        }
        
        AppLogger.getLogger(category: .engine).info("Registered \(config.bindings.count) app shortcut bindings using Hyper Key.")
    }
    
    public func handleKeyPress(key: String) {
        let config = AppConfigManager.shared.config
        guard let apps = config.bindings[key.lowercased()], !apps.isEmpty else { return }
        
        if apps.count == 1 {
            launchOrFocusTarget(apps[0])
            return
        }
        
        var items: [AppSwitcherItem] = []
        for target in apps {
            if target.hasPrefix("chrome-profile:") {
                let dir = String(target.dropFirst("chrome-profile:".count))
                if let profile = ChromeProfileHelper.shared.profiles.first(where: { $0.dir == dir }) {
                    let icon = profile.avatarImage ?? AppDiscoveryService.shared.iconForApp(nameOrBundle: "Google Chrome")
                    items.append(AppSwitcherItem(
                        name: target,
                        displayName: profile.name,
                        icon: icon,
                        isChromeProfile: true,
                        profileDir: profile.dir,
                        badge: "Chrome"
                    ))
                }
            } else {
                let icon = AppDiscoveryService.shared.iconForApp(nameOrBundle: target)
                items.append(AppSwitcherItem(name: target, displayName: target, icon: icon))
            }
        }
        
        if isVisible && activeKey == key && currentItems.count == items.count {
            selectedIndex = (selectedIndex + 1) % items.count
            resetDismissTimer()
        } else {
            activeKey = key
            currentItems = items
            
            let frontAppName = workspace.frontmostApplicationName?.lowercased()
            if let front = frontAppName, let idx = items.firstIndex(where: { $0.displayName.lowercased() == front }) {
                selectedIndex = (idx + 1) % items.count
            } else {
                selectedIndex = lastActiveIndices[key] ?? 0
                if selectedIndex >= items.count { selectedIndex = 0 }
            }
            
            showHUD()
            resetDismissTimer()
        }
    }
    
    private func resetDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.commitAndHide()
            }
        }
    }
    
    public func commitAndHide() {
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
        HUDOverlayWindow.shared.show()
    }
    
    public func launchOrFocusTarget(_ target: String) {
        if target.hasPrefix("chrome-profile:") {
            let dir = String(target.dropFirst("chrome-profile:".count))
            ChromeProfileHelper.shared.focusProfile(dir: dir)
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
