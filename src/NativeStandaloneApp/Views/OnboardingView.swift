import SwiftUI
import Cocoa

public struct OnboardingView: View {
    @ObservedObject var configManager = AppConfigManager.shared
    @ObservedObject var profileHelper = ChromeProfileHelper.shared
    
    @State private var currentStep: Int = 0
    @State private var selectedProfileDirs: Set<String> = []
    @State private var isAccessibilityTrusted: Bool = AXIsProcessTrusted()
    
    public init() {
        // Pre-select all discovered profiles or existing favorites
        let existingFavs = AppConfigManager.shared.config.favoriteChromeProfiles
        if !existingFavs.isEmpty {
            _selectedProfileDirs = State(initialValue: Set(existingFavs.map { $0.replacingOccurrences(of: "chrome-profile:", with: "") }))
        } else {
            let allDirs = ChromeProfileHelper.shared.profiles.map { $0.dir }
            _selectedProfileDirs = State(initialValue: Set(allDirs))
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header / Progress Bar
            HStack(spacing: 8) {
                ForEach(0..<4) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Content Area
            Group {
                switch currentStep {
                case 0:
                    welcomeStepView
                case 1:
                    chromeProfilesStepView
                case 2:
                    standardPresetStepView
                default:
                    completionStepView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Footer Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
                
                Spacer()
                
                if currentStep < 3 {
                    Button(action: {
                        if currentStep == 0 {
                            profileHelper.refreshProfiles()
                        }
                        withAnimation { currentStep += 1 }
                    }) {
                        HStack(spacing: 4) {
                            Text(currentStep == 0 ? "Get Started" : "Continue")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                } else {
                    Button(action: finishOnboarding) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Setup")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 640, height: 500)
        .background(Color(nsColor: .controlBackgroundColor))
        .onAppear {
            isAccessibilityTrusted = AXIsProcessTrusted()
            profileHelper.refreshProfiles()
        }
    }
    
    // MARK: - Step 1: Welcome & Permissions
    private var welcomeStepView: some View {
        VStack(spacing: 16) {
            Image(systemName: "command.square.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .foregroundStyle(Color.accentColor)
                .padding(.top, 10)
            
            VStack(spacing: 6) {
                Text("Welcome to Mac Productivity Suite")
                    .font(.title2.bold())
                
                Text("Supercharge your macOS navigation with Hyper-key app switching, instant HUD overlays, and direct Chrome profile routing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "capslock.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Caps Lock as Hyper Key")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Press Caps Lock + Letter to switch or cycle between designated apps with zero friction.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    Image(systemName: isAccessibilityTrusted ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.title3)
                        .foregroundStyle(isAccessibilityTrusted ? Color.green : Color.orange)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility Permissions")
                            .font(.system(size: 13, weight: .semibold))
                        Text(isAccessibilityTrusted ? "Granted! Global keyboard shortcuts and HUD will work smoothly." : "Accessibility permission is required for global shortcuts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !isAccessibilityTrusted {
                        Spacer()
                        Button("Grant Access") {
                            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                            AXIsProcessTrustedWithOptions(options)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isAccessibilityTrusted = AXIsProcessTrusted()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.top, 10)
    }
    
    // MARK: - Step 2: Chrome Profile Selection
    private var chromeProfilesStepView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Favorite Browser Profiles")
                    .font(.title3.bold())
                Text("Select your primary Chrome profiles to include under the **C** shortcut and numeric hotkeys (1..9).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            
            HStack {
                Text("\(profileHelper.profiles.count) profiles discovered")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("Select All") {
                    selectedProfileDirs = Set(profileHelper.profiles.map { $0.dir })
                }
                .buttonStyle(.link)
                .font(.caption)
                
                Button("Clear") {
                    selectedProfileDirs.removeAll()
                }
                .buttonStyle(.link)
                .font(.caption)
            }
            .padding(.horizontal, 24)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    if profileHelper.profiles.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "globe")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No Chromium profiles detected.")
                                .font(.headline)
                            Text("Standard Google Chrome app will be used for 'C'.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 30)
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(profileHelper.profiles) { profile in
                            let isSelected = selectedProfileDirs.contains(profile.dir)
                            
                            HStack(spacing: 12) {
                                if let img = profile.avatarImage {
                                    Image(nsImage: img)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 36, height: 36)
                                        .foregroundStyle(Color.accentColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(profile.name)
                                            .font(.system(size: 13, weight: .semibold))
                                        
                                        Text("Profile \(profile.index)")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color.blue.opacity(0.15)))
                                            .foregroundStyle(Color.blue)
                                    }
                                    
                                    if let email = profile.email {
                                        Text(email)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.4))
                            }
                            .padding(10)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.15), lineWidth: isSelected ? 1.5 : 1))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelected {
                                    selectedProfileDirs.remove(profile.dir)
                                } else {
                                    selectedProfileDirs.insert(profile.dir)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 250)
        }
        .padding(.top, 12)
    }
    
    // MARK: - Step 3: Standard Preset Setup
    private var standardPresetStepView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Standard Productivity Preset")
                    .font(.title3.bold())
                Text("We've configured an intuitive, single-letter preset for your most essential apps:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            
            let presetItems = [
                ("F", "Finder & Freeform", "folder.fill", Color.blue),
                ("T", "Telegram & Terminal (iTerm2 / Terminal)", "terminal.fill", Color.green),
                ("P", "Photos, Passwords, Preview", "photo.fill", Color.purple),
                ("N", "Notes", "note.text", Color.yellow),
                ("C", "Google Chrome & Favorite Profiles", "globe", Color.orange),
                ("S", "System Settings", "gearshape.fill", Color.gray)
            ]
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(presetItems, id: \.0) { key, label, icon, color in
                        HStack(spacing: 12) {
                            Text(key)
                                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                .frame(width: 32, height: 32)
                                .background(color.opacity(0.15))
                                .foregroundStyle(color)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(label)
                                    .font(.system(size: 11, weight: .semibold))
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                        }
                        .padding(10)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 250)
        }
        .padding(.top, 12)
    }
    
    // MARK: - Step 4: Completion
    private var completionStepView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 52, height: 52)
                .foregroundStyle(Color.accentColor)
                .padding(.top, 20)
            
            VStack(spacing: 6) {
                Text("Setup Complete!")
                    .font(.title2.bold())
                Text("Your productivity suite is configured and ready to go.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                    Text("Standard Preset (F, T, P, N, C, S) Activated")
                        .font(.system(size: 12, weight: .medium))
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                    Text("\(selectedProfileDirs.count) Chrome profiles linked to 'C' and number keys (1..9)")
                        .font(.system(size: 12, weight: .medium))
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                    Text("Instant visual HUD overlay feedback enabled")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.top, 10)
    }
    
    private func finishOnboarding() {
        // 1. Build profile target IDs in canonical profile order (Default, Profile 1, Profile 2, etc.)
        let sortedProfiles = profileHelper.profiles.filter { selectedProfileDirs.contains($0.dir) }
        let favoriteList: [String]
        if !sortedProfiles.isEmpty {
            favoriteList = sortedProfiles.map { "chrome-profile:\($0.dir)" }
        } else {
            favoriteList = selectedProfileDirs.sorted().map { "chrome-profile:\($0)" }
        }
        configManager.config.favoriteChromeProfiles = favoriteList
        
        // 2. Configure Standard preset
        var standard = ConfigPreset.standard.bindings
        
        // Smart terminal resolution: if iTerm2 or iTerm is installed, prioritize it
        let service = AppDiscoveryService.shared
        var tList = ["Telegram"]
        let termCandidates = ["iTerm2", "iTerm", "Terminal"]
        for term in termCandidates {
            if service.findApp(nameOrBundle: term) != nil {
                tList.append(term)
                break
            }
        }
        if tList.count == 1 { tList.append("Terminal") }
        standard["t"] = tList
        
        // Configure Chrome shortcut
        if !favoriteList.isEmpty {
            standard["c"] = favoriteList
        } else {
            standard["c"] = ["Google Chrome"]
        }
        
        configManager.config.bindings = standard
        configManager.config.hasCompletedOnboarding = true
        configManager.save()
        
        OnboardingWindowController.shared.close()
    }
}

public final class OnboardingWindowController {
    public static let shared = OnboardingWindowController()
    private var window: NSWindow?
    
    public func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: OnboardingView())
            let win = NSWindow(contentViewController: hosting)
            win.title = "Mac Productivity Suite Setup"
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.setContentSize(NSSize(width: 640, height: 500))
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
