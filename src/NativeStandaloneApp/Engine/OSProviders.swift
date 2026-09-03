import Foundation
import Cocoa
import AppKit
import Carbon

// MARK: - Running App Provider
public protocol RunningAppProvider: Sendable {
    var localizedName: String? { get }
    var bundleIdentifier: String? { get }
    var processIdentifier: pid_t { get }
    func activateApp()
}

extension NSRunningApplication: RunningAppProvider {
    public func activateApp() {
        if #available(macOS 14.0, *) {
            self.activate()
        } else {
            self.activate(options: .activateIgnoringOtherApps)
        }
    }
}

// MARK: - Workspace Provider
public protocol WorkspaceProvider: Sendable {
    var frontmostApplicationName: String? { get }
    var runningApps: [RunningAppProvider] { get }
    
    func openApplication(at url: URL, configuration: NSWorkspace.OpenConfiguration)
    func fallbackOpen(nameOrCandidate: String)
}

public final class SystemWorkspaceProvider: WorkspaceProvider {
    public init() {}
    
    public var frontmostApplicationName: String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }
    
    public var runningApps: [RunningAppProvider] {
        NSWorkspace.shared.runningApplications
    }
    
    public func openApplication(at url: URL, configuration: NSWorkspace.OpenConfiguration) {
        NSWorkspace.shared.openApplication(at: url, configuration: configuration)
    }
    
    public func fallbackOpen(nameOrCandidate: String) {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", nameOrCandidate]
        try? task.run()
        task.waitUntilExit()
    }
}

// MARK: - Process Provider
public protocol ProcessProvider: Sendable {
    func runCommand(launchPath: String, arguments: [String]) throws
}

public final class SystemProcessProvider: ProcessProvider {
    public init() {}
    
    public func runCommand(launchPath: String, arguments: [String]) throws {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        try task.run()
        task.waitUntilExit()
    }
}

// MARK: - Hotkey Provider
public protocol HotkeyProvider: Sendable {
    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping @Sendable () -> Void) -> UInt32?
    func unregister(id: UInt32)
    func unregisterAll()
}

public final class SystemHotkeyProvider: HotkeyProvider {
    private let manager: HotkeyManager
    
    public init(manager: HotkeyManager) {
        self.manager = manager
    }
    
    public func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping @Sendable () -> Void) -> UInt32? {
        return manager.register(keyCode: keyCode, modifiers: modifiers, action: handler)
    }
    
    public func unregister(id: UInt32) {
        manager.unregister(id: id)
    }
    
    public func unregisterAll() {
        manager.unregisterAll()
    }
}
