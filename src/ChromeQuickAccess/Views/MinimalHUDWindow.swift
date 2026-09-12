import Cocoa
import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Chrome App Icon Helper
public enum ChromeAppIconHelper {
    public static func chromeIcon() -> NSImage {
        let chromeAppPath = "/Applications/Google Chrome.app"
        if FileManager.default.fileExists(atPath: chromeAppPath) {
            return NSWorkspace.shared.icon(forFile: chromeAppPath)
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        if let icon = NSImage(named: NSImage.applicationIconName) {
            return icon
        }
        return NSWorkspace.shared.icon(for: .application)
    }
}

// MARK: - Switcher HUD State
@MainActor
public final class ChromeSwitcherState: ObservableObject {
    public static let shared = ChromeSwitcherState()
    
    @Published public var profiles: [ChromeProfile] = []
    @Published public var selectedIndex: Int = 0
    @Published public var isVisible: Bool = false
    
    public var selectedProfile: ChromeProfile? {
        guard !profiles.isEmpty, selectedIndex >= 0, selectedIndex < profiles.count else {
            return profiles.first
        }
        return profiles[selectedIndex]
    }
    
    public func selectNext() {
        guard !profiles.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % profiles.count
    }
    
    public func selectPrevious() {
        guard !profiles.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + profiles.count) % profiles.count
    }
    
    public func selectIndex(_ index: Int) {
        guard !profiles.isEmpty else { return }
        let clamped = max(0, min(index, profiles.count - 1))
        selectedIndex = clamped
    }
}

// MARK: - Profile Avatar View
public struct ProfileAvatarView: View {
    public let profile: ChromeProfile
    public let isSelected: Bool
    
    public var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .stroke(Color(red: 0.49, green: 0.82, blue: 0.96), lineWidth: 2.2)
                    .frame(width: 32, height: 32)
            }
            
            if let avatar = profile.avatarImage {
                Image(nsImage: avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(red: 0.58, green: 0.30, blue: 0.88))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Text(String(profile.effectiveName.prefix(1)).uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: 34, height: 34)
    }
}

// MARK: - Redesigned Switcher HUD View
public struct MinimalHUDView: View {
    @ObservedObject var state = ChromeSwitcherState.shared
    
    public init(profile: ChromeProfile? = nil) {
        if let profile = profile, state.profiles.isEmpty {
            state.profiles = [profile]
            state.selectedIndex = 0
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Inner Blue Card
            VStack(spacing: 8) {
                // 1. Chrome App Icon
                Image(nsImage: ChromeAppIconHelper.chromeIcon())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // 2. App Name Label
                Text("Google Chrome")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // 3. Profiles Avatar Row
                HStack(spacing: 6) {
                    ForEach(Array(state.profiles.enumerated()), id: \.element.id) { idx, profile in
                        ProfileAvatarView(
                            profile: profile,
                            isSelected: idx == state.selectedIndex
                        )
                    }
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.23, green: 0.42, blue: 0.67))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(red: 0.48, green: 0.73, blue: 0.95), lineWidth: 1.5)
            )
        }
        .padding(10)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}

// Visual Effect View helper
struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Minimal HUD Window
@MainActor
public final class MinimalHUDWindow: NSWindow {
    public static let shared = MinimalHUDWindow()
    
    public init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 180),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.contentView = NSHostingView(rootView: MinimalHUDView())
    }
    
    public func show(profiles: [ChromeProfile], selectedIndex: Int) {
        ChromeSwitcherState.shared.profiles = profiles
        let validIndex = profiles.isEmpty ? 0 : max(0, min(selectedIndex, profiles.count - 1))
        ChromeSwitcherState.shared.selectedIndex = validIndex
        ChromeSwitcherState.shared.isVisible = true
        
        let hostingView = NSHostingView(rootView: MinimalHUDView())
        self.contentView = hostingView
        
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let fittingSize = hostingView.fittingSize
            let width = max(180, fittingSize.width)
            let height = max(160, fittingSize.height)
            let x = screenRect.midX - (width / 2)
            let y = screenRect.midY - (height / 2)
            self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        }
        
        self.alphaValue = 1.0
        self.orderFrontRegardless()
    }
    
    public func updateSelection(to index: Int) {
        ChromeSwitcherState.shared.selectIndex(index)
    }
    
    public func selectNext() {
        ChromeSwitcherState.shared.selectNext()
    }
    
    public func selectPrevious() {
        ChromeSwitcherState.shared.selectPrevious()
    }
    
    /// Backward-compatibility helper
    public func show(for profile: ChromeProfile) {
        show(profiles: [profile], selectedIndex: 0)
    }
    
    public func hideImmediate() {
        ChromeSwitcherState.shared.isVisible = false
        self.orderOut(nil)
        self.alphaValue = 1.0
    }
}

