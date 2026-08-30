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
    public static let shared = AppSwitcherEngine()
    
    @Published public var isVisible: Bool = false
    @Published public var currentItems: [AppSwitcherItem] = []
    @Published public var selectedIndex: Int = 0
    
    private var dismissTimer: Timer?
    private var activeKey: String?
    private var lastActiveIndices: [String: Int] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
        
        // Listen for config changes
        NotificationCenter.default.publisher(for: NSNotification.Name("AppConfigDidChangeNotification"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupBindings()
            }
            .store(in: &cancellables)
    }
    
    public func setupBindings() {
        HotkeyManager.shared.unregisterAll()
        
        let config = AppConfigManager.shared.config
        let modifiers = config.mode.carbonModifiers
        
        // 1. Bind application shortcuts from config
        for (key, apps) in config.bindings {
            guard let keyCode = KeyCodes.keyCode(for: key), !apps.isEmpty else { continue }
            
            let keyStr = key.lowercased()
            HotkeyManager.shared.register(keyCode: keyCode, modifiers: modifiers) { [weak self] in
                Task { @MainActor in
                    self?.handleKeyPress(key: keyStr)
                }
            }
        }
        
        // 2. Bind Browser Profile Shortcuts (1..4) if enabled
        if config.autoDiscoverChromeProfiles {
            let numberKeys = ["1", "2", "3", "4"]
            for (idx, numStr) in numberKeys.enumerated() {
                guard let keyCode = KeyCodes.keyCode(for: numStr) else { continue }
                let profileIndex = idx + 1
                
                HotkeyManager.shared.register(keyCode: keyCode, modifiers: modifiers) {
                    Task { @MainActor in
                        ChromeProfileHelper.shared.focusProfile(index: profileIndex)
                    }
                }
            }
        }
        
        // 3. Re-register productivity actions (Finder split, Quick Notes)
        ProductivityActionsHelper.shared.setupActions()
        
        AppLogger.getLogger(category: .engine).info("Registered \(config.bindings.count) app shortcut bindings.")
    }
    
    public func handleKeyPress(key: String) {
        let config = AppConfigManager.shared.config
        guard let apps = config.bindings[key.lowercased()], !apps.isEmpty else { return }
        
        // If single app configured, launch immediately
        if apps.count == 1 {
            launchOrFocusApp(nameOrCandidate: apps[0])
            return
        }
        
        // Build items for multiple applications
        var items: [AppSwitcherItem] = []
        for appName in apps {
            let icon = AppDiscoveryService.shared.iconForApp(nameOrBundle: appName)
            items.append(AppSwitcherItem(name: appName, displayName: appName, icon: icon))
        }
        
        if isVisible && activeKey == key && currentItems.count == items.count {
            // Cycle to next item
            selectedIndex = (selectedIndex + 1) % items.count
            resetDismissTimer()
        } else {
            // Start switching session
            activeKey = key
            currentItems = items
            
            // Check frontmost app to select next candidate
            let frontAppName = NSWorkspace.shared.frontmostApplication?.localizedName?.lowercased()
            if let front = frontAppName, let idx = items.firstIndex(where: { $0.name.lowercased() == front }) {
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
        // Automatically commit 750ms after the user stops tapping
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
            launchOrFocusApp(nameOrCandidate: selected.name)
        }
        
        isVisible = false
        activeKey = nil
        HUDOverlayWindow.shared.hide()
    }
    
    private func showHUD() {
        isVisible = true
        HUDOverlayWindow.shared.show()
    }
    
    public func launchOrFocusApp(nameOrCandidate: String) {
        // 1. Try running app match
        let running = NSWorkspace.shared.runningApplications
        if let app = running.first(where: {
            $0.localizedName?.lowercased() == nameOrCandidate.lowercased() ||
            $0.bundleIdentifier?.lowercased() == nameOrCandidate.lowercased() ||
            $0.bundleIdentifier?.lowercased().contains(nameOrCandidate.lowercased()) == true
        }) {
            app.activate()
            return
        }
        
        // 2. Try AppDiscoveryService
        if let discovered = AppDiscoveryService.shared.findApp(nameOrBundle: nameOrCandidate) {
            let url = URL(fileURLWithPath: discovered.path)
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            return
        }
        
        // 3. Fallback open command
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", nameOrCandidate]
        try? task.run()
    }
}
