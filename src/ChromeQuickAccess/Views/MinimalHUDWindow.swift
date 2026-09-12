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
                    .stroke(Color(red: 130/255, green: 200/255, blue: 250/255), lineWidth: 2.2)
                    .frame(width: 27, height: 27)
            }
            
            if let avatar = profile.avatarImage {
                Image(nsImage: avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 21, height: 21)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(red: 175/255, green: 110/255, blue: 230/255))
                    .frame(width: 21, height: 21)
                    .overlay(
                        Text(String(profile.effectiveName.prefix(1)).uppercased())
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: 28, height: 28)
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
    
    private var cardWidth: CGFloat {
        max(148, CGFloat(state.profiles.count) * 32 + 16)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Inner Blue Card
            VStack(spacing: 0) {
                Spacer().frame(height: 18)
                
                // 1. Chrome App Icon
                Image(nsImage: ChromeAppIconHelper.chromeIcon())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                
                Spacer().frame(height: 11)
                
                // 2. App Name Label
                Text("Google Chrome")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer().frame(height: 11)
                
                // 3. Profiles Avatar Row
                HStack(spacing: 4) {
                    ForEach(Array(state.profiles.enumerated()), id: \.element.id) { idx, profile in
                        ProfileAvatarView(
                            profile: profile,
                            isSelected: idx == state.selectedIndex
                        )
                    }
                }
                
                Spacer().frame(height: 18)
            }
            .frame(width: cardWidth)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 64/255, green: 108/255, blue: 171/255))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(red: 130/255, green: 189/255, blue: 248/255), lineWidth: 1.8)
            )
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 12)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                Color(red: 45/255, green: 44/255, blue: 49/255)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
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
            contentRect: NSRect(x: 0, y: 0, width: 170, height: 196),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.hasShadow = true
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
            let width = max(160, fittingSize.width)
            let height = max(185, fittingSize.height)
            let x = screenRect.midX - (width / 2)
            let y = screenRect.midY - (height / 2)
            self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
            self.invalidateShadow()
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

