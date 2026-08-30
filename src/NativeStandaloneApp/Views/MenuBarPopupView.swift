import SwiftUI
import Cocoa

struct MenuBarPopupView: View {
    @State private var copyOnSelectEnabled: Bool = true
    @State private var hasAccessibility: Bool = AXIsProcessTrusted()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mac Productivity Suite")
                        .font(.headline)
                    Text("Pure Native Standalone Edition")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.bottom, 2)
            
            Divider()
            
            // Permissions Alert if needed
            if !hasAccessibility {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Accessibility Permission Needed")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Text("Required for Global Shortcuts and Copy-on-Select.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    Button(action: {
                        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                        AXIsProcessTrustedWithOptions(options)
                    }) {
                        Text("Grant Accessibility Permission")
                            .font(.system(size: 11, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                
                Divider()
            }
            
            // Features Toggle
            VStack(alignment: .leading, spacing: 8) {
                Text("FEATURES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                
                Toggle(isOn: $copyOnSelectEnabled) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Copy on Select")
                            .font(.system(size: 12, weight: .medium))
                        Text("Instantly copies text when highlighted or double-clicked")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: copyOnSelectEnabled) { _, enabled in
                    CopyOnSelectEngine.shared.setEnabled(enabled)
                }
            }
            
            Divider()
            
            // Shortcut Cheat Sheet
            VStack(alignment: .leading, spacing: 6) {
                Text("ACTIVE SHORTCUTS (⌥⌘)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                
                Group {
                    ShortcutRow(keys: "⌥⌘ + I", description: "iTerm / Terminal")
                    ShortcutRow(keys: "⌥⌘ + S", description: "Spotify / SoundCloud")
                    ShortcutRow(keys: "⌥⌘ + T", description: "Telegram")
                    ShortcutRow(keys: "⌥⌘ + A", description: "Antigravity IDE")
                    ShortcutRow(keys: "⌥⌘ + C", description: "Google Chrome / Calendar")
                    ShortcutRow(keys: "⌥⌘ + 1..4", description: "Chrome Profiles (Igor, Al11, Nastya...)")
                    ShortcutRow(keys: "⌥⌘⌃ + F", description: "Finder Dual-Column Split")
                    ShortcutRow(keys: "⌘⇧ + H", description: "Save Highlighted Text to Note")
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("Zero background daemons")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
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

struct ShortcutRow: View {
    let keys: String
    let description: String
    
    var body: some View {
        HStack {
            Text(keys)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.12))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Spacer()
            
            Text(description)
                .font(.system(size: 11))
                .foregroundStyle(.primary)
        }
    }
}
