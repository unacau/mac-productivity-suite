import Cocoa
import AppKit
import SwiftUI

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
                    .stroke(Color(red: 130/255, green: 200/255, blue: 250/255), lineWidth: 2.0)
                    .frame(width: 24, height: 24)
            }
            
            if let avatar = profile.avatarImage {
                Image(nsImage: avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 18, height: 18)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(red: 175/255, green: 110/255, blue: 230/255))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Text(String(profile.effectiveName.prefix(1)).uppercased())
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: 25, height: 25)
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
                    .stroke(Color(red: 130/255, green: 200/255, blue: 250/255), lineWidth: 2.0)
                    .frame(width: 24, height: 24)
            }
            
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .clipShape(Circle())
        }
        .frame(width: 25, height: 25)
    }
}

// MARK: - Redesigned Switcher HUD View
public struct MinimalHUDView: View {
    @ObservedObject var state = ChromeSwitcherState.shared
    
    public init() {}
    
    private var cardWidth: CGFloat {
        let count = state.mode == .chrome ? state.profiles.count : state.antigravityItems.count
        return max(130, CGFloat(count) * 28 + 14)
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
                Spacer().frame(height: 14)
                
                // 1. App Icon
                Image(nsImage: topIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                
                Spacer().frame(height: 9)
                
                // 2. App Name Label
                Text(appTitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer().frame(height: 9)
                
                // 3. Avatar / Icon Row
                HStack(spacing: 3.5) {
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
                
                Spacer().frame(height: 14)
            }
            .frame(width: cardWidth)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color(red: 64/255, green: 108/255, blue: 171/255))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Color(red: 130/255, green: 189/255, blue: 248/255), lineWidth: 1.5)
            )
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 10)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                Color(red: 45/255, green: 44/255, blue: 49/255).opacity(0.82)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
public final class MinimalHUDWindow: NSPanel {
    public static let shared = MinimalHUDWindow()
    
    public init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 148, height: 168),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = true
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
            let width = max(140, fittingSize.width)
            let height = max(160, fittingSize.height)
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
    
    public func hideImmediate() {
        ChromeSwitcherState.shared.isVisible = false
        self.orderOut(nil)
        self.alphaValue = 1.0
    }
}

