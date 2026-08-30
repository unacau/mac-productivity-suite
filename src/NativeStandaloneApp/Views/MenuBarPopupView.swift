import SwiftUI
import Cocoa

public struct MenuBarPopupView: View {
    @ObservedObject var configManager = AppConfigManager.shared
    @State private var hasAccessibility: Bool = AXIsProcessTrusted()
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "command.square.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Mac Productivity Suite")
                        .font(.system(size: 13, weight: .bold))
                    Text("Version \(configManager.config.version) • \(configManager.config.mode.displayName)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                Button(action: {
                    SettingsWindowController.shared.show()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open Preferences (⌘,)")
            }
            .padding(.bottom, 2)
            
            Divider()
            
            // Permissions Alert if missing
            if !hasAccessibility {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Accessibility Permission Required")
                            .font(.system(size: 11, weight: .bold))
                    }
                    Text("Global shortcuts & Copy-on-Select require accessibility access.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    
                    Button(action: {
                        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                        AXIsProcessTrustedWithOptions(options)
                    }) {
                        Text("Grant Permission")
                            .font(.system(size: 10, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                
                Divider()
            }
            
            // Quick Feature Toggle: Copy on Select
            Toggle(isOn: $configManager.config.copyOnSelect.enabled) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Copy on Select")
                        .font(.system(size: 12, weight: .medium))
                    Text("Copies highlighted text automatically")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: configManager.config.copyOnSelect.enabled) { _, _ in
                configManager.save()
            }
            
            Divider()
            
            // Dynamic Active Shortcuts List
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("ACTIVE SHORTCUTS (\(configManager.config.mode.shortBadge))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Edit...") {
                        SettingsWindowController.shared.show()
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 10))
                }
                
                let sortedKeys = configManager.config.bindings.keys.sorted()
                let displayKeys = Array(sortedKeys.prefix(7))
                
                if displayKeys.isEmpty {
                    Text("No shortcuts configured yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(displayKeys, id: \.self) { key in
                        let apps = configManager.config.bindings[key] ?? []
                        let appSummary = apps.joined(separator: " / ")
                        ShortcutRow(
                            keys: "\(configManager.config.mode.shortBadge) + \(key.uppercased())",
                            description: appSummary.isEmpty ? "(No apps)" : appSummary
                        )
                    }
                    
                    if sortedKeys.count > 7 {
                        Text("+ \(sortedKeys.count - 7) more shortcuts in Settings")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                }
                
                if configManager.config.autoDiscoverChromeProfiles {
                    ShortcutRow(
                        keys: "\(configManager.config.mode.shortBadge) + 1..4",
                        description: "Chrome / Browser Profiles"
                    )
                }
                
                if configManager.config.productivityShortcuts.finderSplitEnabled {
                    ShortcutRow(
                        keys: "⌥⌘⌃ + F",
                        description: "Finder Dual-Column Split"
                    )
                }
            }
            
            Divider()
            
            // Footer with Settings, Updates, and Quit
            HStack {
                Button("Preferences...") {
                    SettingsWindowController.shared.show()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                
                Spacer()
                
                Button("Check for Updates...") {
                    if let delegate = NSApp.delegate as? AppDelegate {
                        delegate.checkForUpdates()
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.red)
            }
        }
        .padding(14)
        .frame(width: 320)
        .onAppear {
            hasAccessibility = AXIsProcessTrusted()
        }
    }
}

public struct ShortcutRow: View {
    public let keys: String
    public let description: String
    
    public var body: some View {
        HStack {
            Text(keys)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.12))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Spacer()
            
            Text(description)
                .font(.system(size: 11))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}
