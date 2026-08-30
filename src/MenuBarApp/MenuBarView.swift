import SwiftUI

struct MenuBarView: View {
    @ObservedObject var modeManager = ModeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mac Productivity Suite")
                        .font(.headline)
                    Text("Activation Mode & Controls")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.bottom, 2)
            
            Divider()
            
            // Mode Selection Section
            VStack(alignment: .leading, spacing: 8) {
                Text("ACTIVATION MODE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                
                // Hyper Mode Option
                ModeOptionCard(
                    title: "Hyper Key Mode",
                    subtitle: "Hold Caps Lock for instant app switcher & profile shortcuts",
                    badge: "Caps Lock",
                    badgeColor: .blue,
                    isSelected: modeManager.currentMode == .hyper,
                    requiresKarabiner: true,
                    isKarabinerInstalled: modeManager.isKarabinerInstalled,
                    onSelect: {
                        modeManager.switchMode(to: .hyper)
                    }
                )
                
                // Classic Mode Option
                ModeOptionCard(
                    title: "Classic Mode",
                    subtitle: "Standard ⌥⌘ (Cmd+Option) keys without requiring Karabiner",
                    badge: "⌥⌘ Key",
                    badgeColor: .orange,
                    isSelected: modeManager.currentMode == .classic,
                    requiresKarabiner: false,
                    isKarabinerInstalled: true,
                    onSelect: {
                        modeManager.switchMode(to: .classic)
                    }
                )
            }
            
            Divider()
            
            // Service Status
            VStack(alignment: .leading, spacing: 6) {
                Text("SERVICES STATUS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                
                HStack {
                    StatusIndicator(
                        title: "Hammerspoon",
                        isRunning: modeManager.isHammerspoonRunning,
                        isInstalled: modeManager.isHammerspoonInstalled,
                        onAction: {
                            modeManager.launchHammerspoon()
                        }
                    )
                    Spacer()
                    if modeManager.currentMode == .hyper {
                        StatusIndicator(
                            title: "Karabiner",
                            isRunning: modeManager.isKarabinerRunning,
                            isInstalled: modeManager.isKarabinerInstalled,
                            onAction: {
                                modeManager.launchKarabiner()
                            }
                        )
                    } else {
                        HStack(spacing: 4) {
                            Circle().fill(Color.gray).frame(width: 8, height: 8)
                            Text("Karabiner: Not needed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Divider()
            
            // Actions
            VStack(spacing: 6) {
                Button(action: {
                    modeManager.reloadHammerspoonConfig()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Reload Hammerspoon Config")
                        Spacer()
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    modeManager.checkEnvironment()
                }) {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                        Text("Refresh Status")
                        Spacer()
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                
                Divider().padding(.vertical, 2)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit Suite Menu")
                        Spacer()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 320)
        .onAppear {
            modeManager.checkEnvironment()
        }
    }
}

struct ModeOptionCard: View {
    let title: String
    let subtitle: String
    let badge: String
    let badgeColor: Color
    let isSelected: Bool
    let requiresKarabiner: Bool
    let isKarabinerInstalled: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.blue : Color.secondary)
                    .font(.system(size: 16))
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badgeColor.opacity(0.15))
                            .foregroundStyle(badgeColor)
                            .clipShape(Capsule())
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if requiresKarabiner && !isKarabinerInstalled {
                        Text("⚠️ Requires Karabiner-Elements installation")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.orange)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct StatusIndicator: View {
    let title: String
    let isRunning: Bool
    let isInstalled: Bool
    let onAction: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isRunning ? Color.green : (isInstalled ? Color.orange : Color.red))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                Text(isRunning ? "Running" : (isInstalled ? "Stopped" : "Not Installed"))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            
            if isInstalled && !isRunning {
                Button(action: onAction) {
                    Text("Start")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else if isRunning {
                Button(action: onAction) {
                    Text("Settings")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
