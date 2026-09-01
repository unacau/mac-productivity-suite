import SwiftUI
import Cocoa

public struct SettingsView: View {
    @ObservedObject var configManager = AppConfigManager.shared
    @ObservedObject var profileHelper = ChromeProfileHelper.shared
    @ObservedObject var discovery = AppDiscoveryService.shared
    
    @State private var selectedTab: SettingsTab = .shortcuts
    @State private var showingAddKeySheet: Bool = false
    @State private var showingAppPickerForKey: String? = nil
    @State private var showingResetAlert: Bool = false
    
    public enum SettingsTab: String, CaseIterable, Identifiable {
        case shortcuts = "Shortcuts & Apps"
        case profiles = "Browser Profiles"
        case backup = "Backup & Reset"
        
        public var id: String { rawValue }
        
        public var iconName: String {
            switch self {
            case .shortcuts: return "keyboard"
            case .profiles: return "person.crop.circle"
            case .backup: return "arrow.triangle.2.circlepath"
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(SettingsTab.allCases) { tab in
                    Button(action: { selectedTab = tab }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.iconName)
                            Text(tab.rawValue)
                        }
                        .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .regular))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .shortcuts:
                        ShortcutsTabContent(
                            configManager: configManager,
                            showingAddKeySheet: $showingAddKeySheet,
                            showingAppPickerForKey: $showingAppPickerForKey
                        )
                    case .profiles:
                        ProfilesTabContent(
                            configManager: configManager,
                            profileHelper: profileHelper
                        )
                    case .backup:
                        BackupTabContent(
                            configManager: configManager,
                            showingResetAlert: $showingResetAlert
                        )
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            HStack {
                Text("Changes are applied instantly")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Done") {
                    SettingsWindowController.shared.close()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 720, height: 540)
        .sheet(isPresented: $showingAddKeySheet) {
            AddKeySheet(isPresented: $showingAddKeySheet) { newKey in
                configManager.updateBinding(key: newKey, apps: [])
                showingAppPickerForKey = newKey
            }
        }
        .sheet(item: $showingAppPickerForKey) { key in
            AppPickerSheet(isPresented: Binding(
                get: { showingAppPickerForKey != nil },
                set: { if !$0 { showingAppPickerForKey = nil } }
            )) { selectedAppName in
                var current = configManager.config.bindings[key] ?? []
                if !current.contains(selectedAppName) {
                    current.append(selectedAppName)
                    configManager.updateBinding(key: key, apps: current)
                }
            }
        }
        .alert("Reset to Defaults?", isPresented: $showingResetAlert) {
            Button("Reset Everything", role: .destructive) {
                configManager.resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore default shortcuts and settings. Your customized bindings will be overwritten.")
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct ShortcutsTabContent: View {
    @ObservedObject var configManager: AppConfigManager
    @Binding var showingAddKeySheet: Bool
    @Binding var showingAppPickerForKey: String?
    @State private var hasAccessibility: Bool = AXIsProcessTrusted()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !hasAccessibility {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.orange)
                    VStack(alignment: .leading) {
                        Text("Accessibility Permission Required")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Required for global application switching. Please enable in System Settings > Privacy & Security.")
                            .font(.caption)
                    }
                    Spacer()
                    Button("Grant Access...") {
                        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                        AXIsProcessTrustedWithOptions(options)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("App Switcher Bindings")
                        .font(.title3.bold())
                    Text("Press Caps Lock (Hyper) + key to switch or cycle between designated apps or Chrome profiles.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                Button(action: {
                    let smart = AppDiscoveryService.shared.generateSmartBindings()
                    configManager.config.bindings = smart
                    configManager.save()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                        Text("Auto-Detect")
                    }
                    .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Menu {
                    ForEach(ConfigPreset.allCases) { preset in
                        Button(preset.rawValue) {
                            configManager.applyPreset(preset)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                        Text("Presets")
                    }
                    .font(.system(size: 11))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                
                Button(action: { showingAddKeySheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Key")
                    }
                    .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            Divider()
            
            let sortedKeys = configManager.config.bindings.keys.sorted()
            
            if sortedKeys.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "keyboard.badge.ellipsis")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No shortcuts configured")
                        .font(.headline)
                    Text("Click 'Auto-Detect My Apps' or 'Add Key' to set up your workflow.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(sortedKeys, id: \.self) { key in
                        KeyBindingRow(
                            key: key,
                            apps: configManager.config.bindings[key] ?? [],
                            onAddApp: {
                                showingAppPickerForKey = key
                            },
                            onRemoveApp: { index in
                                var list = configManager.config.bindings[key] ?? []
                                if index < list.count {
                                    list.remove(at: index)
                                    configManager.updateBinding(key: key, apps: list)
                                }
                            },
                            onMoveApp: { from, to in
                                var list = configManager.config.bindings[key] ?? []
                                let item = list.remove(at: from)
                                list.insert(item, at: to)
                                configManager.updateBinding(key: key, apps: list)
                            },
                            onDeleteKey: {
                                configManager.removeBinding(key: key)
                            }
                        )
                    }
                }
            }
        }
        .onAppear {
            hasAccessibility = AXIsProcessTrusted()
        }
    }
}

struct KeyBindingRow: View {
    let key: String
    let apps: [String]
    let onAddApp: () -> Void
    let onRemoveApp: (Int) -> Void
    let onMoveApp: (Int, Int) -> Void
    let onDeleteKey: () -> Void
    
    func targetName(for target: String) -> String {
        if target.hasPrefix("chrome-profile:") {
            let dir = String(target.dropFirst("chrome-profile:".count))
            if let profile = ChromeProfileHelper.shared.profiles.first(where: { $0.dir == dir }) {
                return "Chrome (\(profile.name))"
            }
            return "Chrome (\(dir))"
        }
        return target
    }
    
    func icon(for target: String) -> NSImage {
        if target.hasPrefix("chrome-profile:") {
            let dir = String(target.dropFirst("chrome-profile:".count))
            if let profile = ChromeProfileHelper.shared.profiles.first(where: { $0.dir == dir }), let img = profile.avatarImage {
                return img
            }
            return AppDiscoveryService.shared.iconForApp(nameOrBundle: "Google Chrome")
        }
        return AppDiscoveryService.shared.iconForApp(nameOrBundle: target)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack {
                Text(key.uppercased())
                    .font(.system(size: 16, weight: .heavy, design: .monospaced))
                    .frame(width: 38, height: 38)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
            }
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 6) {
                if apps.isEmpty {
                    Text("No apps assigned yet. Click '+' to add an application.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(Array(apps.enumerated()), id: \.offset) { index, target in
                            HStack(spacing: 6) {
                                Image(nsImage: icon(for: target))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                                    .clipShape(target.hasPrefix("chrome-profile:") ? AnyShape(Circle()) : AnyShape(Rectangle()))
                                
                                Text(targetName(for: target))
                                    .font(.system(size: 12, weight: .medium))
                                
                                if index > 0 {
                                    Button(action: { onMoveApp(index, index - 1) }) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 9))
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                if index < apps.count - 1 {
                                    Button(action: { onMoveApp(index, index + 1) }) {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 9))
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Button(action: { onRemoveApp(index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onAddApp) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 15))
                }
                .buttonStyle(.plain)
                .help("Add application to this key")
                
                Button(action: onDeleteKey) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Delete key shortcut")
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > width, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        height = currentY + lineHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            view.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

struct ProfilesTabContent: View {
    @ObservedObject var configManager: AppConfigManager
    @ObservedObject var profileHelper: ChromeProfileHelper
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Browser Profiles (Keys 1..9)")
                        .font(.title3.bold())
                    Text("Automatically detected from Google Chrome, Brave, Chromium, or Edge.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { profileHelper.refreshProfiles() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Refresh Profiles")
                    }
                    .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Divider()
            
            Toggle("Enable Chrome Profile Switcher Hotkeys (Caps Lock + 1..9)", isOn: $configManager.config.autoDiscoverChromeProfiles)
                .onChange(of: configManager.config.autoDiscoverChromeProfiles) { _, _ in
                    configManager.save()
                }
            
            Text("DETECTED PROFILES")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            
            if profileHelper.profiles.isEmpty {
                Text("No browser profiles found on disk.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(profileHelper.profiles) { p in
                        HStack(spacing: 12) {
                            Text("\(p.index)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .frame(width: 24, height: 24)
                                .background(Color.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .clipShape(Circle())
                            
                            if let avatar = p.avatarImage {
                                Image(nsImage: avatar)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name)
                                    .font(.system(size: 13, weight: .semibold))
                                HStack(spacing: 6) {
                                    Text("Dir: \(p.dir)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                    if let email = p.email, !email.isEmpty {
                                        Text("• \(email)")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Button("Test Launch") {
                                profileHelper.focusProfile(index: p.index)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(10)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                    }
                }
            }
        }
    }
}

struct BackupTabContent: View {
    @ObservedObject var configManager: AppConfigManager
    @Binding var showingResetAlert: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Backup & Reset")
                    .font(.title3.bold())
                Text("Export your customized bindings or restore factory settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            HStack(spacing: 16) {
                Button(action: {
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.json]
                    panel.nameFieldStringValue = "mps-config-backup.json"
                    if panel.runModal() == .OK, let url = panel.url {
                        do {
                            try configManager.exportConfig(to: url)
                        } catch {
                            AppLogger.getLogger(category: .config).error("Export failed: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Export Config")
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.json]
                    if panel.runModal() == .OK, let url = panel.url {
                        do {
                            try configManager.importConfig(from: url)
                        } catch {
                            AppLogger.getLogger(category: .config).error("Import failed: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Import Config")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Reset to Defaults") {
                    showingResetAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
            }
        }
    }
}

struct AddKeySheet: View {
    @Binding var isPresented: Bool
    var onAddKey: (String) -> Void
    
    @State private var keyInput: String = ""
    
    let commonKeys = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","1","2","3","4","5","6","7","8","9","0","-","=","[","]","\\",";","'","<",">","/","space","return"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Shortcut Key")
                .font(.headline)
            Text("Select a key to map to an application or browser profile.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField("Type a single character (e.g. 'a', '1', 'space')", text: $keyInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14, design: .monospaced))
                .onChange(of: keyInput) { _, newValue in
                    if newValue.count > 6 {
                        keyInput = String(newValue.prefix(6))
                    }
                }
            
            Text("Common Keys:")
                .font(.system(size: 11, weight: .bold))
                .padding(.top, 4)
            
            ScrollView(.vertical) {
                FlowLayout(spacing: 6) {
                    ForEach(commonKeys, id: \.self) { key in
                        Button(action: { keyInput = key.lowercased() }) {
                            Text(key)
                                .font(.system(size: 11, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }
                }
            }
            .frame(maxHeight: 120)
            
            Spacer()
            
            HStack {
                Button("Cancel") { isPresented = false }
                Spacer()
                Button("Add Key") {
                    let cleaned = keyInput.trimmingCharacters(in: .whitespaces).lowercased()
                    if !cleaned.isEmpty {
                        onAddKey(cleaned)
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360, height: 380)
    }
}

public final class SettingsWindowController {
    public static let shared = SettingsWindowController()
    private var window: NSWindow?
    
    public func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let win = NSWindow(contentViewController: hosting)
            win.title = "Mac Productivity Suite Preferences"
            win.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            win.setContentSize(NSSize(width: 720, height: 540))
            win.center()
            win.isReleasedWhenClosed = false
            self.window = win
        }
        
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    
    public func close() {
        window?.orderOut(nil)
    }
}
