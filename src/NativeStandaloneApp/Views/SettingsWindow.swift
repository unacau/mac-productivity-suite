import SwiftUI
import Cocoa

public struct SettingsView: View {
    @ObservedObject var configManager = AppConfigManager.shared
    @ObservedObject var profileHelper = ChromeProfileHelper.shared
    @ObservedObject var discovery = AppDiscoveryService.shared
    
    @State private var selectedTab: SettingsTab = .shortcuts
    @State private var showingAddKeySheet: Bool = false
    @State private var showingAppPickerForKey: String? = nil
    @State private var showingAddExclusionSheet: Bool = false
    @State private var showingResetAlert: Bool = false
    @State private var statusNotification: String? = nil
    
    public enum SettingsTab: String, CaseIterable, Identifiable {
        case shortcuts = "Shortcuts & Apps"
        case profiles = "Browser Profiles"
        case copyOnSelect = "Copy on Select"
        case mode = "Activation Mode"
        case actions = "Actions & Notes"
        case backup = "Backup & Reset"
        
        public var id: String { rawValue }
        
        public var iconName: String {
            switch self {
            case .shortcuts: return "keyboard"
            case .profiles: return "person.crop.circle"
            case .copyOnSelect: return "doc.on.doc"
            case .mode: return "slider.horizontal.3"
            case .actions: return "sparkles"
            case .backup: return "arrow.triangle.2.circlepath"
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Sidebar Navigation / Tab Bar
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
            
            // Tab Content
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
                    case .copyOnSelect:
                        CopyOnSelectTabContent(
                            configManager: configManager,
                            showingAddExclusionSheet: $showingAddExclusionSheet
                        )
                    case .mode:
                        ModeTabContent(configManager: configManager)
                    case .actions:
                        ActionsTabContent(configManager: configManager)
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
            
            // Status Bar Footer
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
        .sheet(isPresented: $showingAddExclusionSheet) {
            AppPickerSheet(isPresented: $showingAddExclusionSheet) { selectedAppName in
                if let app = discovery.findApp(nameOrBundle: selectedAppName), !app.bundleID.isEmpty {
                    if !configManager.config.copyOnSelect.excludedBundleIDs.contains(app.bundleID) {
                        configManager.config.copyOnSelect.excludedBundleIDs.append(app.bundleID)
                        configManager.save()
                    }
                } else if !configManager.config.copyOnSelect.excludedBundleIDs.contains(selectedAppName) {
                    configManager.config.copyOnSelect.excludedBundleIDs.append(selectedAppName)
                    configManager.save()
                }
            }
        }
        .alert("Reset to Defaults?", isPresented: $showingResetAlert) {
            Button("Reset Everything", role: .destructive) {
                configManager.resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore default shortcuts, settings, and exclusions. Your customized bindings will be overwritten.")
        }
    }
}

// Extension to allow String to conform to Identifiable for sheet(item:)
extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Shortcuts Tab
struct ShortcutsTabContent: View {
    @ObservedObject var configManager: AppConfigManager
    @Binding var showingAddKeySheet: Bool
    @Binding var showingAppPickerForKey: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Bar with Quick Presets and Auto-Detect
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("App Switcher Bindings")
                        .font(.title3.bold())
                    Text("Press modifier + key to switch or cycle between designated apps.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                // Auto-detect button
                Button(action: {
                    let smart = AppDiscoveryService.shared.generateSmartBindings()
                    configManager.config.bindings = smart
                    configManager.save()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                        Text("Auto-Detect My Apps")
                    }
                    .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                // Preset Menu
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
                
                // Add Key Button
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
            
            // Key Bindings Table / Cards
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
                    Button("Auto-Detect Installed Apps") {
                        let smart = AppDiscoveryService.shared.generateSmartBindings()
                        configManager.config.bindings = smart
                        configManager.save()
                    }
                    .buttonStyle(.borderedProminent)
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
    }
}

struct KeyBindingRow: View {
    let key: String
    let apps: [String]
    let onAddApp: () -> Void
    let onRemoveApp: (Int) -> Void
    let onMoveApp: (Int, Int) -> Void
    let onDeleteKey: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Key Badge
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
            
            // App Badges & Cycling Order
            VStack(alignment: .leading, spacing: 6) {
                if apps.isEmpty {
                    Text("No apps assigned yet. Click '+' to add an application.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(Array(apps.enumerated()), id: \.offset) { index, appName in
                            HStack(spacing: 6) {
                                Image(nsImage: AppDiscoveryService.shared.iconForApp(nameOrBundle: appName))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                                
                                Text(appName)
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
            
            // Actions
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

// FlowLayout helper for SwiftUI tag chips
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

// MARK: - Profiles Tab
struct ProfilesTabContent: View {
    @ObservedObject var configManager: AppConfigManager
    @ObservedObject var profileHelper: ChromeProfileHelper
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Browser Profiles (Keys 1..4)")
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
            
            Toggle("Enable Chrome Profile Switcher Hotkeys (⌥⌘ + 1..4)", isOn: $configManager.config.autoDiscoverChromeProfiles)
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

// MARK: - Copy on Select Tab
struct CopyOnSelectTabContent: View {
    @ObservedObject var configManager: AppConfigManager
    @Binding var showingAddExclusionSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Copy on Select")
                    .font(.title3.bold())
                Text("Automatically copies highlighted or double-clicked text to your clipboard.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            Toggle("Enable Copy-on-Select Globally", isOn: $configManager.config.copyOnSelect.enabled)
                .font(.system(size: 13, weight: .medium))
                .onChange(of: configManager.config.copyOnSelect.enabled) { _, _ in
                    configManager.save()
                }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Drag Sensitivity:")
                        .font(.system(size: 12))
                    Spacer()
                    Text("\(Int(configManager.config.copyOnSelect.dragThreshold)) px")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                Slider(value: $configManager.config.copyOnSelect.dragThreshold, in: 5...40, step: 1)
                    .onChange(of: configManager.config.copyOnSelect.dragThreshold) { _, _ in
                        configManager.save()
                    }
            }
            .padding(.top, 4)
            
            Divider()
            
            // Excluded Applications
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Excluded Applications")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Copy-on-select will be disabled inside these applications (e.g. Terminals).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { showingAddExclusionSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add App")
                    }
                    .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            LazyVStack(spacing: 6) {
                ForEach(configManager.config.copyOnSelect.excludedBundleIDs, id: \.self) { bundleID in
                    HStack {
                        Image(nsImage: AppDiscoveryService.shared.iconForApp(nameOrBundle: bundleID))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                        
                        Text(bundleID)
                            .font(.system(size: 12, design: .monospaced))
                        
                        Spacer()
                        
                        Button(action: {
                            configManager.config.copyOnSelect.excludedBundleIDs.removeAll(where: { $0 == bundleID })
                            configManager.save()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                }
            }
        }
    }
}

// MARK: - Activation Mode Tab
struct ModeTabContent: View {
    @ObservedObject var configManager: AppConfigManager
    @State private var hasAccessibility: Bool = AXIsProcessTrusted()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Activation Mode & Modifiers")
                    .font(.title3.bold())
                Text("Select the keyboard modifier combination for your app switcher shortcuts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 10) {
                ForEach(ProductivityMode.allCases, id: \.self) { mode in
                    Button(action: { configManager.setMode(mode) }) {
                        HStack {
                            Image(systemName: configManager.config.mode == mode ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(configManager.config.mode == mode ? Color.accentColor : Color.secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                Text(mode == .hyper ? "Caps Lock mapped via Karabiner-Elements or event tap" : "Uses standard macOS modifier keys")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(mode.shortBadge)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.12))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(configManager.config.mode == mode ? Color.accentColor.opacity(0.08) : Color(nsColor: .windowBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(configManager.config.mode == mode ? Color.accentColor.opacity(0.4) : Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
            
            // Accessibility Status
            HStack {
                Image(systemName: hasAccessibility ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(hasAccessibility ? Color.green : Color.orange)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(hasAccessibility ? "Accessibility Permissions Active" : "Accessibility Permission Required")
                        .font(.system(size: 12, weight: .semibold))
                    Text(hasAccessibility ? "Global hotkeys and mouse tracking are enabled." : "Required for global application switching and text copying.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if !hasAccessibility {
                    Button("Grant Access...") {
                        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                        AXIsProcessTrustedWithOptions(options)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(12)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onAppear {
                hasAccessibility = AXIsProcessTrusted()
            }
        }
    }
}

// MARK: - Actions & Notes Tab
struct ActionsTabContent: View {
    @ObservedObject var configManager: AppConfigManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Productivity Actions & Quick Notes")
                    .font(.title3.bold())
                Text("Additional native workflow tools built into macOS.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Finder Split
            Toggle(isOn: $configManager.config.productivityShortcuts.finderSplitEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Finder Dual-Column Split (⌥⌘⌃ + F)")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Automatically splits Finder into two side-by-side column view windows.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: configManager.config.productivityShortcuts.finderSplitEnabled) { _, _ in
                configManager.save()
            }
            
            Divider()
            
            // Quick Notes
            Toggle(isOn: $configManager.config.productivityShortcuts.quickNotesEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Highlight & Save to Quick Notes (⌘⇧ + H)")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Instantly saves highlighted text with timestamps to a local Markdown note.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: configManager.config.productivityShortcuts.quickNotesEnabled) { _, _ in
                configManager.save()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes Storage Directory:")
                    .font(.system(size: 12, weight: .medium))
                
                HStack {
                    TextField("Storage Path", text: $configManager.config.productivityShortcuts.quickNotesDirectory)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            configManager.config.productivityShortcuts.quickNotesDirectory = url.path
                            configManager.save()
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Backup & Reset Tab
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
            
            HStack(spacing: 12) {
                Button(action: exportConfig) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Config to JSON...")
                    }
                }
                .buttonStyle(.bordered)
                
                Button(action: importConfig) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import Config from JSON...")
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(role: .destructive, action: { showingResetAlert = true }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Defaults")
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            Text("CONFIG FILE LOCATION")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            
            Text(configManager.configURL.path)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
    
    private func exportConfig() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "mac-productivity-suite-config.json"
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            try? configManager.exportConfig(to: url)
        }
    }
    
    private func importConfig() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            try? configManager.importConfig(from: url)
        }
    }
}

// MARK: - Add Key Sheet
struct AddKeySheet: View {
    @Binding var isPresented: Bool
    var onAddKey: (String) -> Void
    
    @State private var keyInput: String = ""
    let suggestedKeys = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add Shortcut Key")
                .font(.headline)
            
            Text("Type a letter, number, or select a suggested key below:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField("Key (e.g. 'c' or 'space')", text: $keyInput)
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(suggestedKeys, id: \.self) { k in
                    Button(action: { keyInput = k }) {
                        Text(k.uppercased())
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .frame(maxWidth: .infinity, minHeight: 28)
                            .background(keyInput == k ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                            .foregroundStyle(keyInput == k ? Color.white : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            
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
            .padding(.top, 10)
        }
        .padding(20)
        .frame(width: 360, height: 320)
    }
}

// MARK: - Settings Window Controller
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
