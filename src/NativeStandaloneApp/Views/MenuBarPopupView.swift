import SwiftUI
import Cocoa

public struct MenuBarPopupView: View {
    @ObservedObject var configManager = AppConfigManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "command.square.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(Color.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mac Productivity Suite")
                        .font(.system(size: 13, weight: .bold))
                    Text("Version \(configManager.config.version)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    SettingsWindowController.shared.show()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open Preferences")
            }
            .padding(16)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("QUICK SWITCHER (Hyper + Key)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(configManager.config.bindings.keys.sorted().prefix(6)), id: \.self) { key in
                            HStack {
                                Text(key.uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .frame(width: 24, height: 24)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                
                                let apps = configManager.config.bindings[key] ?? []
                                if apps.isEmpty {
                                    Text("Unassigned")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(apps.count == 1 ? apps[0] : "\(apps[0]) + \(apps.count - 1) more")
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .frame(maxHeight: 180)
                
                HStack {
                    Spacer()
                    Button("Edit...") {
                        SettingsWindowController.shared.show()
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 11))
                }
                .padding(.horizontal, 16)
            }
            
            Divider()
                .padding(.top, 8)
            
            VStack(spacing: 4) {
                Button(action: {
                    OnboardingWindowController.shared.show()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.accentColor)
                        Text("Setup Wizard & Profiles...")
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                        appDelegate.checkForUpdates()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.secondary)
                        Text("Check for Updates...")
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                            .foregroundStyle(.secondary)
                        Text("Quit Suite")
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
        }
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
