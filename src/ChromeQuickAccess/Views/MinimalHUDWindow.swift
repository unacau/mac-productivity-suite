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
    @Published public var isMascotPeeking: Bool = false
    
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
        withAnimation(XomskyMotion.magneticGlide) {
            selectedIndex = (selectedIndex + 1) % count
        }
    }
    
    public func selectPrevious() {
        let count = mode == .chrome ? profiles.count : antigravityItems.count
        guard count > 0 else { return }
        withAnimation(XomskyMotion.magneticGlide) {
            selectedIndex = (selectedIndex - 1 + count) % count
        }
    }
    
    public func selectIndex(_ index: Int) {
        let count = mode == .chrome ? profiles.count : antigravityItems.count
        guard count > 0 else { return }
        let clamped = max(0, min(index, count - 1))
        withAnimation(XomskyMotion.magneticGlide) {
            selectedIndex = clamped
        }
    }
}

// MARK: - Profile Avatar View
public struct ProfileAvatarView: View {
    public let profile: ChromeProfile
    public let isSelected: Bool
    public let slotIndex: Int
    public var namespace: Namespace.ID?
    
    public init(profile: ChromeProfile, isSelected: Bool, slotIndex: Int = 0, namespace: Namespace.ID? = nil) {
        self.profile = profile
        self.isSelected = isSelected
        self.slotIndex = slotIndex > 0 ? slotIndex : profile.index
        self.namespace = namespace
    }
    
    public var body: some View {
        VStack(spacing: 5) {
            ZStack {
                // Frosted light circular plate so transparent/dark icons (e.g. sunglasses) pop with clarity
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.38),
                                Color.white.opacity(0.24)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 32, height: 32)
                
                if let avatar = profile.avatarImage {
                    Image(nsImage: avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.35, green: 0.55, blue: 0.95), Color(red: 0.55, green: 0.35, blue: 0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(profile.effectiveName.prefix(1)).uppercased())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                // Refined circular hairline: subtle framing without clashing with the outer selection tile
                Circle()
                    .stroke(
                        Color.white.opacity(isSelected ? 0.35 : 0.12),
                        lineWidth: 1
                    )
                    .frame(width: 34, height: 34)
            }
            .frame(width: 36, height: 36)
            
            Text("\(slotIndex)")
                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.60))
        }
        .frame(width: 44)
        .padding(.vertical, 4)
        .background {
            if isSelected {
                if let ns = namespace {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.24), lineWidth: 0.75)
                        )
                        .matchedGeometryEffect(id: "activeSlotCapsule", in: ns)
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.24), lineWidth: 0.75)
                        )
                }
            }
        }
        .scaleEffect(isSelected ? 1.05 : 0.96)
        .animation(XomskyMotion.magneticGlide, value: isSelected)
    }
}

// MARK: - Antigravity App Avatar View
public struct AntigravityAvatarView: View {
    public let item: AntigravityItem
    public let isSelected: Bool
    public let slotIndex: Int
    public var namespace: Namespace.ID?
    
    public init(item: AntigravityItem, isSelected: Bool, slotIndex: Int = 0, namespace: Namespace.ID? = nil) {
        self.item = item
        self.isSelected = isSelected
        self.slotIndex = slotIndex > 0 ? slotIndex : item.index
        self.namespace = namespace
    }
    
    public var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.white.opacity(0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                
                Circle()
                    .stroke(
                        Color.white.opacity(isSelected ? 0.35 : 0.12),
                        lineWidth: 1
                    )
                    .frame(width: 34, height: 34)
            }
            .frame(width: 36, height: 36)
            
            Text("\(slotIndex)")
                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.60))
        }
        .frame(width: 44)
        .padding(.vertical, 4)
        .background {
            if isSelected {
                if let ns = namespace {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.24), lineWidth: 0.75)
                        )
                        .matchedGeometryEffect(id: "activeSlotCapsule", in: ns)
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.24), lineWidth: 0.75)
                        )
                }
            }
        }
        .scaleEffect(isSelected ? 1.05 : 0.96)
        .animation(XomskyMotion.magneticGlide, value: isSelected)
    }
}

// MARK: - Modern Switcher HUD View
public struct MinimalHUDView: View {
    @ObservedObject var state = ChromeSwitcherState.shared
    @Namespace private var selectionNamespace
    
    public init() {}
    
    private var cardWidth: CGFloat {
        if !state.hasBrothers {
            return 155
        }
        let count = state.mode == .chrome ? state.profiles.count : state.antigravityItems.count
        let itemsWidth = CGFloat(count) * 44 + CGFloat(max(0, count - 1)) * 8
        return max(180, itemsWidth + 32)
    }
    
    private var topIcon: NSImage {
        if state.mode == .chrome {
            return ChromeProfileEngine.shared.activeBrowserIcon
        } else if let selected = state.selectedAppItem {
            return selected.icon
        } else {
            return AntigravityEngine.shared.items.first?.icon ?? NSWorkspace.shared.icon(for: .application)
        }
    }
    
    private var appTitle: String {
        if state.mode == .chrome {
            return ChromeProfileEngine.shared.activeBrowserName
        }
        return state.selectedAppItem?.name ?? "Application"
    }
    
    private var activeSubtitle: String? {
        if state.mode == .chrome {
            let activeName = ChromeProfileEngine.shared.activeBrowserName
            if let prof = state.selectedProfile?.effectiveName, prof != "Google Chrome", prof != "Chrome", prof != activeName {
                return prof.capitalized
            }
        }
        return nil
    }
    
    public var body: some View {
        VStack(spacing: 7) {
            // 1. App Icon with continuous rounded rect and subtle shadow
            Image(nsImage: topIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 2)
                .padding(.top, 2)
                .id(topIcon)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            
            // 2. Primary Title Label & Contextual Subtitle (Understated & Non-Intrusive)
            VStack(spacing: 3) {
                Text(appTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.82))
                    .lineLimit(1)
                
                if let sub = activeSubtitle {
                    Text(sub)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.72))
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                        )
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            
            // 3. Avatar / Icon Carousel (Only shown when there are sibling profiles or apps)
            if state.hasBrothers {
                HStack(spacing: 8) {
                    if state.mode == .chrome {
                        ForEach(Array(state.profiles.enumerated()), id: \.element.id) { idx, profile in
                            ProfileAvatarView(
                                profile: profile,
                                isSelected: idx == state.selectedIndex,
                                slotIndex: idx + 1,
                                namespace: selectionNamespace
                            )
                        }
                    } else {
                        ForEach(Array(state.antigravityItems.enumerated()), id: \.element.id) { idx, item in
                            AntigravityAvatarView(
                                item: item,
                                isSelected: idx == state.selectedIndex,
                                slotIndex: idx + 1,
                                namespace: selectionNamespace
                            )
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .frame(width: cardWidth)
        .animation(XomskyMotion.cardMorph, value: cardWidth)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.85))
                
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.75
                )
        )
        .overlay(alignment: .top) {
            if state.isMascotPeeking {
                Image(nsImage: AppDelegate.makeKhomyakStatusIcon())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .offset(y: -13)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Two-stage organic Apple drop shadow (ambient + directional)
        .shadow(color: Color.black.opacity(0.28), radius: 16, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.16), radius: 4, x: 0, y: 2)
        .scaleEffect(state.isVisible ? 1.0 : 0.93)
        .opacity(state.isVisible ? 1.0 : 0.0)
        .animation(XomskyMotion.interactiveSnap, value: state.isVisible)
        .padding(48)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Minimal HUD Window
@MainActor
public final class MinimalHUDWindow: NSPanel {
    public static let shared = MinimalHUDWindow()
    
    private let hostingView: NSHostingView<MinimalHUDView>
    private var peekTask: Task<Void, Never>?
    
    public init() {
        let hosting = NSHostingView(rootView: MinimalHUDView())
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = .clear
        self.hostingView = hosting
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 260),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.contentView = hosting
    }
    
    private func resetAndSchedulePeek() {
        peekTask?.cancel()
        ChromeSwitcherState.shared.isMascotPeeking = false
        peekTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled, let _ = self, ChromeSwitcherState.shared.isVisible else { return }
            withAnimation(XomskyMotion.tactileBop) {
                ChromeSwitcherState.shared.isMascotPeeking = true
            }
        }
    }
    
    public func show(profiles: [ChromeProfile], selectedIndex: Int) {
        withAnimation(XomskyMotion.interactiveSnap) {
            ChromeSwitcherState.shared.mode = .chrome
            ChromeSwitcherState.shared.profiles = profiles
            let validIndex = profiles.isEmpty ? 0 : max(0, min(selectedIndex, profiles.count - 1))
            ChromeSwitcherState.shared.selectedIndex = validIndex
            ChromeSwitcherState.shared.isVisible = true
        }
        
        reposition()
        resetAndSchedulePeek()
        self.alphaValue = 1.0
        self.orderFrontRegardless()
        triggerSensoryFeedback()
    }
    
    public func showAntigravity(items: [AntigravityItem], selectedIndex: Int) {
        showAppGroup(mode: .antigravity, items: items, selectedIndex: selectedIndex)
    }
    
    public func showAppGroup(mode: SwitcherMode, items: [AntigravityItem], selectedIndex: Int) {
        withAnimation(XomskyMotion.interactiveSnap) {
            ChromeSwitcherState.shared.mode = mode
            ChromeSwitcherState.shared.antigravityItems = items
            let validIndex = items.isEmpty ? 0 : max(0, min(selectedIndex, items.count - 1))
            ChromeSwitcherState.shared.selectedIndex = validIndex
            ChromeSwitcherState.shared.isVisible = true
        }
        
        reposition()
        resetAndSchedulePeek()
        self.alphaValue = 1.0
        self.orderFrontRegardless()
        triggerSensoryFeedback()
    }
    
    private func reposition() {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let width: CGFloat = 440
            let height: CGFloat = 260
            let x = screenRect.midX - (width / 2)
            let y = screenRect.midY - (height / 2)
            self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        }
    }
    
    private func triggerSensoryFeedback() {
        // 1. Tactile haptic feedback on Force Touch trackpads
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .default
        )
        
        // 2. VoiceOver announcement
        let announcementText: String
        if ChromeSwitcherState.shared.mode == .chrome {
            let prof = ChromeSwitcherState.shared.selectedProfile?.effectiveName ?? "Profile"
            announcementText = "\(ChromeProfileEngine.shared.activeBrowserName), \(prof)"
        } else if let app = ChromeSwitcherState.shared.selectedAppItem {
            announcementText = app.name
        } else {
            announcementText = "Quick Switcher"
        }
        
        NSAccessibility.post(
            element: NSApp as Any,
            notification: .announcementRequested,
            userInfo: [.announcement: announcementText]
        )
    }
    
    public func updateSelection(to index: Int) {
        peekTask?.cancel()
        if ChromeSwitcherState.shared.isMascotPeeking {
            withAnimation(XomskyMotion.interactiveSnap) {
                ChromeSwitcherState.shared.isMascotPeeking = false
            }
        }
        ChromeSwitcherState.shared.selectIndex(index)
        triggerSensoryFeedback()
    }
    
    public func selectNext() {
        peekTask?.cancel()
        if ChromeSwitcherState.shared.isMascotPeeking {
            withAnimation(XomskyMotion.interactiveSnap) {
                ChromeSwitcherState.shared.isMascotPeeking = false
            }
        }
        ChromeSwitcherState.shared.selectNext()
        triggerSensoryFeedback()
    }
    
    public func selectPrevious() {
        peekTask?.cancel()
        if ChromeSwitcherState.shared.isMascotPeeking {
            withAnimation(XomskyMotion.interactiveSnap) {
                ChromeSwitcherState.shared.isMascotPeeking = false
            }
        }
        ChromeSwitcherState.shared.selectPrevious()
        triggerSensoryFeedback()
    }
    
    public func hideImmediate() {
        peekTask?.cancel()
        peekTask = nil
        ChromeSwitcherState.shared.isMascotPeeking = false
        ChromeSwitcherState.shared.isVisible = false
        self.orderOut(nil)
        self.alphaValue = 1.0
    }
}

