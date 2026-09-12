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

// MARK: - Switcher Mode
public enum SwitcherMode: Equatable, Sendable {
    case chrome
    case antigravity
}

// MARK: - Switcher HUD State
@MainActor
public final class ChromeSwitcherState: ObservableObject {
    public static let shared = ChromeSwitcherState()
    
    @Published public var mode: SwitcherMode = .chrome
    @Published public var profiles: [ChromeProfile] = []
    @Published public var antigravityItems: [AntigravityItem] = []
    @Published public var selectedIndex: Int = 0
    @Published public var isVisible: Bool = false
    
    public var selectedProfile: ChromeProfile? {
        guard !profiles.isEmpty, selectedIndex >= 0, selectedIndex < profiles.count else {
            return profiles.first
        }
        return profiles[selectedIndex]
    }
    
    public var selectedAntigravityItem: AntigravityItem? {
        guard !antigravityItems.isEmpty, selectedIndex >= 0, selectedIndex < antigravityItems.count else {
            return antigravityItems.first
        }
        return antigravityItems[selectedIndex]
    }
    
    public func selectNext() {
        let count = mode == .chrome ? profiles.count : antigravityItems.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + 1) % count
    }
    
    public func selectPrevious() {
        let count = mode == .chrome ? profiles.count : antigravityItems.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex - 1 + count) % count
    }
    
    public func selectIndex(_ index: Int) {
        let count = mode == .chrome ? profiles.count : antigravityItems.count
        guard count > 0 else { return }
        let clamped = max(0, min(index, count - 1))
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

// MARK: - Antigravity App Avatar View
public struct AntigravityAvatarView: View {
    public let item: AntigravityItem
    public let isSelected: Bool
    
    public var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .stroke(Color(red: 130/255, green: 200/255, blue: 250/255), lineWidth: 2.2)
                    .frame(width: 27, height: 27)
            }
            
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 21, height: 21)
                .clipShape(Circle())
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
        let count = state.mode == .chrome ? state.profiles.count : state.antigravityItems.count
        return max(148, CGFloat(count) * 32 + 16)
    }
    
    private var topIcon: NSImage {
        if state.mode == .chrome {
            return ChromeAppIconHelper.chromeIcon()
        } else if let selected = state.selectedAntigravityItem {
            return selected.icon
        } else {
            return AntigravityEngine.shared.items.first?.icon ?? NSWorkspace.shared.icon(for: .application)
        }
    }
    
    private var appTitle: String {
        if state.mode == .chrome {
            return "Google Chrome"
        } else if let selected = state.selectedAntigravityItem {
            return selected.name
        } else {
            return "Antigravity"
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Inner Blue Card
            VStack(spacing: 0) {
                Spacer().frame(height: 18)
                
                // 1. App Icon
                Image(nsImage: topIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                
                Spacer().frame(height: 11)
                
                // 2. App Name Label
                Text(appTitle)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer().frame(height: 11)
                
                // 3. Avatar / Icon Row
                HStack(spacing: 4) {
                    if state.mode == .chrome {
                        ForEach(Array(state.profiles.enumerated()), id: \.element.id) { idx, profile in
                            ProfileAvatarView(
                                profile: profile,
                                isSelected: idx == state.selectedIndex
                            )
                        }
                    } else {
                        ForEach(Array(state.antigravityItems.enumerated()), id: \.element.id) { idx, item in
                            AntigravityAvatarView(
                                item: item,
                                isSelected: idx == state.selectedIndex
                            )
                        }
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
        ChromeSwitcherState.shared.mode = .chrome
        ChromeSwitcherState.shared.profiles = profiles
        let validIndex = profiles.isEmpty ? 0 : max(0, min(selectedIndex, profiles.count - 1))
        ChromeSwitcherState.shared.selectedIndex = validIndex
        ChromeSwitcherState.shared.isVisible = true
        
        let hostingView = NSHostingView(rootView: MinimalHUDView())
        self.contentView = hostingView
        reposition(with: hostingView)
        
        self.alphaValue = 1.0
        self.orderFrontRegardless()
    }
    
    public func showAntigravity(items: [AntigravityItem], selectedIndex: Int) {
        ChromeSwitcherState.shared.mode = .antigravity
        ChromeSwitcherState.shared.antigravityItems = items
        let validIndex = items.isEmpty ? 0 : max(0, min(selectedIndex, items.count - 1))
        ChromeSwitcherState.shared.selectedIndex = validIndex
        ChromeSwitcherState.shared.isVisible = true
        
        let hostingView = NSHostingView(rootView: MinimalHUDView())
        self.contentView = hostingView
        reposition(with: hostingView)
        
        self.alphaValue = 1.0
        self.orderFrontRegardless()
    }
    
    private func reposition(with hostingView: NSHostingView<MinimalHUDView>) {
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

