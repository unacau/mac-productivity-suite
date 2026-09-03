import SwiftUI
import Cocoa
import AppKit

public enum SettingsTab: String, CaseIterable, Identifiable {
    case shortcuts = "Shortcuts"
    case chromeProfiles = "Chrome Profiles"
    case advanced = "Advanced"
    
    public var id: String { rawValue }
}

public struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .shortcuts
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 360)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            switch selectedTab {
            case .shortcuts:
                ShortcutsSettingsView()
            case .chromeProfiles:
                ChromeProfilesSettingsTab()
            case .advanced:
                AdvancedSettingsTab()
            }
        }
        .frame(minWidth: 760, minHeight: 560)
    }
}

public struct ShortcutsSettingsView: View {
    @ObservedObject var configManager = AppConfigManager.shared
    @ObservedObject var profileHelper = ChromeProfileHelper.shared
    
    @State private var showingAddKeySheet: Bool = false
    @State private var showingAppPickerForKey: ActiveKeySheetTarget? = nil
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("App Switcher Bindings")
                            .font(.title2.bold())
                        Text("v\(AppConfig.currentAppVersion) (Build \(AppConfig.currentBuildNumber))")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Text("Press Caps Lock (Hyper) + key to switch or cycle between designated apps or Chrome profiles.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                Button(action: {
                    OnboardingWindowController.shared.show()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Setup Wizard...")
                    }
                    .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                
                Button(action: {
                    let smart = AppDiscoveryService.shared.generateSmartBindings()
                    configManager.config.bindings = smart
                    configManager.save()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                        Text("Auto-Detect Apps")
                    }
                    .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                
                Button(action: { showingAddKeySheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Key")
                    }
                    .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(20)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Browser Profiles Toggle
            HStack {
                Toggle(isOn: $configManager.config.autoDiscoverChromeProfiles) {
                    Text("Enable automatic Browser Profile shortcuts (Caps Lock + 1..9)")
                        .font(.system(size: 13, weight: .medium))
                }
                .toggleStyle(.switch)
                .onChange(of: configManager.config.autoDiscoverChromeProfiles) { _, _ in
                    configManager.save()
                }
                Spacer()
                
                if configManager.config.autoDiscoverChromeProfiles {
                    Text("\(profileHelper.profiles.count) profiles found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Bindings List
            ScrollView {
                let sortedKeys = configManager.config.bindings.keys.sorted()
                
                if sortedKeys.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "keyboard.badge.ellipsis")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No shortcuts configured")
                            .font(.headline)
                        Text("Click 'Auto-Detect Apps' or 'Add Key' to set up your workflow.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedKeys, id: \.self) { key in
                            KeyBindingRow(
                                key: key,
                                apps: configManager.config.bindings[key] ?? [],
                                onAddApp: {
                                    showingAppPickerForKey = ActiveKeySheetTarget(id: key)
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
                    .padding(20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Footer
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mac Productivity Suite v\(AppConfig.currentAppVersion) (Build \(AppConfig.currentBuildNumber))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Changes are applied instantly")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if AXIsProcessTrusted() {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                        Text("Accessibility Active")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button(action: {
                        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
                        AXIsProcessTrustedWithOptions(options)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundStyle(.orange)
                            Text("Grant Accessibility")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                Button("Done") {
                    SettingsWindowController.shared.close()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 720, height: 580)
        .sheet(isPresented: $showingAddKeySheet) {
            AddKeySheet(isPresented: $showingAddKeySheet) { newKey in
                configManager.updateBinding(key: newKey, apps: [])
                showingAppPickerForKey = ActiveKeySheetTarget(id: newKey)
            }
        }
        .sheet(item: $showingAppPickerForKey) { target in
            AppPickerSheet(isPresented: Binding(
                get: { showingAppPickerForKey != nil },
                set: { if !$0 { showingAppPickerForKey = nil } }
            )) { selectedAppName in
                let key = target.id
                var current = configManager.config.bindings[key] ?? []
                if !current.contains(selectedAppName) {
                    current.append(selectedAppName)
                    configManager.updateBinding(key: key, apps: current)
                }
            }
        }
    }
}

public struct ActiveKeySheetTarget: Identifiable {
    public let id: String
}

@MainActor
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
        HStack(alignment: .top, spacing: 16) {
            VStack {
                Text(key.uppercased())
                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if apps.isEmpty {
                    Text("No apps assigned yet. Click '+' to add an application.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 12)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(Array(apps.enumerated()), id: \.offset) { index, target in
                            HStack(spacing: 8) {
                                Image(nsImage: icon(for: target))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .clipShape(target.hasPrefix("chrome-profile:") ? AnyShape(Circle()) : AnyShape(Rectangle()))
                                
                                Text(targetName(for: target))
                                    .font(.system(size: 13, weight: .medium))
                                
                                if index > 0 {
                                    Button(action: { onMoveApp(index, index - 1) }) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                if index < apps.count - 1 {
                                    Button(action: { onMoveApp(index, index + 1) }) {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Button(action: { onRemoveApp(index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: onAddApp) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .help("Add application to this key")
                
                Button(action: onDeleteKey) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Delete key shortcut")
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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

// MARK: - Chrome Profiles Tab

public struct ChromeProfilesSettingsTab: View {
    @ObservedObject var configManager = AppConfigManager.shared
    @ObservedObject var profileHelper = ChromeProfileHelper.shared
    
    @State private var testingProfileDir: String? = nil
    @State private var isCapsLockSimulated: Bool = false
    @State private var isCSimulated: Bool = false
    @State private var simulatedNumber: String? = nil
    @State private var localKeyMonitor: Any? = nil
    
    private var orderedProfiles: [DiscoveredChromeProfile] {
        let profiles = profileHelper.profiles
        let order = configManager.config.chromeProfileOrder
        guard !order.isEmpty else { return profiles }
        
        var result: [DiscoveredChromeProfile] = []
        for dir in order {
            if let p = profiles.first(where: { $0.dir == dir }) {
                result.append(p)
            }
        }
        for p in profiles {
            if !result.contains(where: { $0.dir == p.dir }) {
                result.append(p)
            }
        }
        return result
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                // Top: HUD Tiles Row inside floating HUD Container
                VStack(spacing: 12) {
                    if orderedProfiles.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.white.opacity(0.6))
                            Text("No Chrome profiles detected")
                                .font(.headline)
                                .foregroundStyle(Color.white)
                            Text("Ensure Google Chrome or Chromium is installed and has at least one profile.")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
                        .padding(24)
                    } else {
                        HStack(spacing: 12) {
                            ForEach(Array(orderedProfiles.enumerated()), id: \.element.id) { index, profile in
                                ChromeProfileHUDTile(
                                    profile: profile,
                                    index: index + 1,
                                    isSelected: testingProfileDir == profile.dir
                                )
                                .draggable(profile.dir)
                                .dropDestination(for: String.self) { items, _ in
                                    guard let sourceDir = items.first, sourceDir != profile.dir else { return false }
                                    moveProfile(sourceDir: sourceDir, targetDir: profile.dir)
                                    return true
                                }
                                .onTapGesture {
                                    testProfile(profile)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.85))
                        .background(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
                .padding(.top, 24)
                
                // Bottom: MacBook Pro Style Physical Keys Tutorial
                HStack(spacing: 14) {
                    MacBookKeyView(
                        width: 84,
                        hasLed: true,
                        isLedActive: isCapsLockSimulated,
                        label: "caps lock",
                        alignment: .bottomLeading,
                        isPressed: isCapsLockSimulated
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isCapsLockSimulated.toggle()
                        }
                    }
                    
                    Text("+")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    MacBookKeyView(
                        width: 48,
                        label: "C",
                        alignment: .center,
                        isPressed: isCSimulated
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isCSimulated.toggle()
                        }
                    }
                    
                    Text("+")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    MacBookKeyView(
                        width: 48,
                        label: simulatedNumber ?? "1",
                        alignment: .center,
                        isPressed: simulatedNumber != nil
                    )
                    .onTapGesture {
                        if let first = orderedProfiles.first {
                            testProfile(first)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                )
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .onAppear {
            setupLocalKeyMonitor()
        }
        .onDisappear {
            removeLocalKeyMonitor()
        }
    }
    
    private func setupLocalKeyMonitor() {
        guard localKeyMonitor == nil else { return }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if event.modifierFlags.contains(.capsLock) || event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) {
                isCapsLockSimulated = true
            } else {
                isCapsLockSimulated = false
            }
            
            if event.type == .keyDown {
                if event.charactersIgnoringModifiers?.lowercased() == "c" {
                    isCSimulated = true
                } else if let chars = event.charactersIgnoringModifiers,
                          let num = Int(chars), num >= 1 && num <= orderedProfiles.count {
                    let target = orderedProfiles[num - 1]
                    testProfile(target)
                }
            } else if event.type == .keyUp {
                if event.charactersIgnoringModifiers?.lowercased() == "c" {
                    isCSimulated = false
                }
            }
            return event
        }
    }
    
    private func removeLocalKeyMonitor() {
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
    }
    
    private func moveProfile(sourceDir: String, targetDir: String) {
        var currentDirs = orderedProfiles.map(\.dir)
        guard let sourceIndex = currentDirs.firstIndex(of: sourceDir),
              let targetIndex = currentDirs.firstIndex(of: targetDir) else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentDirs.remove(at: sourceIndex)
            currentDirs.insert(sourceDir, at: targetIndex)
            configManager.config.chromeProfileOrder = currentDirs
            configManager.save()
            profileHelper.refreshProfiles()
        }
    }
    
    private func testProfile(_ profile: DiscoveredChromeProfile) {
        testingProfileDir = profile.dir
        simulatedNumber = "\(profile.index)"
        isCapsLockSimulated = true
        isCSimulated = true
        
        profileHelper.focusProfile(dir: profile.dir)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                self.testingProfileDir = nil
                self.isCapsLockSimulated = false
                self.isCSimulated = false
                self.simulatedNumber = nil
            }
        }
    }
}

// MARK: - Chrome Profile HUD Tile

public struct ChromeProfileHUDTile: View {
    let profile: DiscoveredChromeProfile
    let index: Int
    let isSelected: Bool
    
    public var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                iconView
                badgeView
            }
            .frame(width: 52, height: 52)
            .overlay(alignment: .topLeading) {
                indexBadgeView
            }
            
            Text(profile.name)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.75))
                .lineLimit(1)
                .frame(width: 84)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.blue.opacity(0.65) : Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.cyan : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var iconView: some View {
        if let avatar = profile.avatarImage {
            Image(nsImage: avatar)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.cyan.opacity(0.8) : Color.white.opacity(0.25), lineWidth: isSelected ? 2 : 1)
                )
        } else {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(profile.name.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.cyan.opacity(0.8) : Color.white.opacity(0.25), lineWidth: isSelected ? 2 : 1)
                )
        }
    }
    
    @ViewBuilder
    private var badgeView: some View {
        Image(nsImage: AppDiscoveryService.shared.iconForApp(nameOrBundle: "Google Chrome"))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
            .offset(x: 3, y: 3)
    }
    
    @ViewBuilder
    private var indexBadgeView: some View {
        Text("\(index)")
            .font(.system(size: 10, weight: .heavy, design: .monospaced))
            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.9))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(isSelected ? Color.blue : Color.black.opacity(0.6))
            )
            .overlay(
                Capsule().stroke(isSelected ? Color.cyan.opacity(0.8) : Color.white.opacity(0.3), lineWidth: 1)
            )
            .offset(x: -8, y: -6)
    }
}

// MARK: - MacBook Key View

public struct MacBookKeyView: View {
    let width: CGFloat
    var hasLed: Bool = false
    var isLedActive: Bool = false
    let label: String
    var alignment: Alignment = .center
    var isPressed: Bool = false
    
    public var body: some View {
        ZStack(alignment: alignment) {
            if hasLed {
                Circle()
                    .fill(isLedActive ? Color.green : Color(white: 0.25))
                    .frame(width: 4, height: 4)
                    .shadow(color: isLedActive ? Color.green.opacity(0.8) : .clear, radius: 3)
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            
            Text(label)
                .font(.system(size: alignment == .bottomLeading ? 11 : 16, weight: .regular, design: .default))
                .foregroundStyle(Color.white)
                .padding(alignment == .bottomLeading ? 8 : 0)
        }
        .frame(width: width, height: 48)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isPressed ? Color.blue.opacity(0.8) : Color.white.opacity(0.12), lineWidth: isPressed ? 1.5 : 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: isPressed ? 1 : 3, x: 0, y: isPressed ? 0 : 2)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Advanced Settings Tab

public struct AdvancedSettingsTab: View {
    @ObservedObject var configManager = AppConfigManager.shared
    
    public var body: some View {
        Form {
            Section("System Interception & Hyper Key") {
                Toggle("Remap Caps Lock to Hyper Key (Cmd + Ctrl + Opt + Shift)", isOn: $configManager.config.remapCapsLockToHyper)
                    .onChange(of: configManager.config.remapCapsLockToHyper) { _, _ in configManager.save() }
                
                Toggle("Escape on Quick Tap (Vim / Power User Mode)", isOn: $configManager.config.escapeOnTap)
                    .onChange(of: configManager.config.escapeOnTap) { _, _ in configManager.save() }
            }
            
            Section("Clipboard & Productivity") {
                Toggle("Enable Linux/X11-Style Copy on Select", isOn: $configManager.config.copyOnSelectEnabled)
                    .onChange(of: configManager.config.copyOnSelectEnabled) { _, _ in configManager.save() }
            }
            
            Section("Configuration Presets") {
                HStack {
                    Text("Apply Preset:")
                    ForEach(ConfigPreset.allCases) { preset in
                        Button(preset.rawValue) {
                            configManager.config.bindings = preset.bindings
                            configManager.save()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}

@MainActor
public final class SettingsWindowController {
    public static let shared = SettingsWindowController()
    private var window: NSWindow?
    
    public func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let win = NSWindow(contentViewController: hosting)
            win.title = "Mac Productivity Suite Preferences"
            win.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            win.setContentSize(NSSize(width: 780, height: 580))
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
