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
    case terminal
    case notes
    case ide
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
    
    public var selectedAppItem: AntigravityItem? {
        guard !antigravityItems.isEmpty, selectedIndex >= 0, selectedIndex < antigravityItems.count else {
            return antigravityItems.first
        }
        return antigravityItems[selectedIndex]
    }
    
    public var selectedAntigravityItem: AntigravityItem? {
        selectedAppItem
    }
    
    public var hasBrothers: Bool {
        if mode == .chrome {
            return profiles.count > 1
        } else {
            return antigravityItems.count > 1
        }
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
                    .frame(width: 38, height: 38)
            }
            
            if let avatar = profile.avatarImage {
                Image(nsImage: avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(red: 175/255, green: 110/255, blue: 230/255))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Text(String(profile.effectiveName.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: 40, height: 40)
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
                    .frame(width: 38, height: 38)
            }
            
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .clipShape(Circle())
        }
        .frame(width: 40, height: 40)
    }
}

// MARK: - Redesigned Switcher HUD View
public struct MinimalHUDView: View {
    @ObservedObject var state = ChromeSwitcherState.shared
    
    public init() {}
    
    private var cardWidth: CGFloat {
        if !state.hasBrothers {
            return 150
        }
        let count = state.mode == .chrome ? state.profiles.count : state.antigravityItems.count
        return max(150, CGFloat(count) * 46 + 20)
    }
    
    private var topIcon: NSImage {
        if state.mode == .chrome {
            return ChromeAppIconHelper.chromeIcon()
        } else if let selected = state.selectedAppItem {
            return selected.icon
        } else {
            return AntigravityEngine.shared.items.first?.icon ?? NSWorkspace.shared.icon(for: .application)
        }
    }
    
    private var appTitle: String {
        if state.mode == .chrome {
            return "Google Chrome"
        } else if let selected = state.selectedAppItem {
            return selected.name
        } else {
            switch state.mode {
            case .terminal: return "Terminal"
            case .notes: return "Notes"
            case .ide: return "IDE"
            case .antigravity: return "Antigravity"
            case .chrome: return "Google Chrome"
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Inner Blue Card
            VStack(spacing: 0) {
                Spacer().frame(height: 16)
                
                // 1. App Icon
                Image(nsImage: topIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Spacer().frame(height: 10)
                
                // 2. App Name Label
                Text(appTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // 3. Avatar / Icon Row (only displayed when there are sibling "brothers" to cycle between)
                if state.hasBrothers {
                    Spacer().frame(height: 10)
                    
                    HStack(spacing: 6) {
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
                } else {
                    Spacer().frame(height: 16)
                }
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
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 225),
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
        showAppGroup(mode: .antigravity, items: items, selectedIndex: selectedIndex)
    }
    
    public func showAppGroup(mode: SwitcherMode, items: [AntigravityItem], selectedIndex: Int) {
        ChromeSwitcherState.shared.mode = mode
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
            let width = max(150, fittingSize.width)
            let minHeight: CGFloat = ChromeSwitcherState.shared.hasBrothers ? 215 : 140
            let height = max(minHeight, fittingSize.height)
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

