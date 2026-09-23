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
    @Published public var selectedIndex: Int = 0 {
        didSet {
            if mode == .chrome {
                selectedProfileIndex = selectedIndex
            }
        }
    }
    @Published public var selectedProfileIndex: Int = 0
    @Published public var isVisible: Bool = false
    @Published public var isMascotPeeking: Bool = false
    
    public var selectedProfile: ChromeProfile? {
        guard !profiles.isEmpty else { return nil }
        if mode == .chrome {
            let idx = max(0, min(selectedIndex, profiles.count - 1))
            return profiles[idx]
        }
        let idx = max(0, min(selectedProfileIndex, profiles.count - 1))
        return profiles[idx]
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
        if mode == .chrome {
            guard !profiles.isEmpty else { return }
            withAnimation(XomskyMotion.magneticGlide) {
                selectedIndex = (selectedIndex + 1) % profiles.count
                selectedProfileIndex = selectedIndex
            }
            return
        }
        
        guard !antigravityItems.isEmpty else { return }
        withAnimation(XomskyMotion.magneticGlide) {
            selectedIndex = (selectedIndex + 1) % antigravityItems.count
        }
    }
    
    public func selectPrevious() {
        if mode == .chrome {
            guard !profiles.isEmpty else { return }
            withAnimation(XomskyMotion.magneticGlide) {
                selectedIndex = (selectedIndex - 1 + profiles.count) % profiles.count
                selectedProfileIndex = selectedIndex
            }
            return
        }
        
        guard !antigravityItems.isEmpty else { return }
        withAnimation(XomskyMotion.magneticGlide) {
            selectedIndex = (selectedIndex - 1 + antigravityItems.count) % antigravityItems.count
        }
    }
    
    public func selectNextCard() {
        selectNext()
    }
    
    public func selectPreviousCard() {
        selectPrevious()
    }
    
    public func selectIndex(_ index: Int) {
        if mode == .chrome {
            guard !profiles.isEmpty else { return }
            let clamped = max(0, min(index, profiles.count - 1))
            withAnimation(XomskyMotion.magneticGlide) {
                selectedIndex = clamped
                selectedProfileIndex = clamped
            }
        } else {
            guard !antigravityItems.isEmpty else { return }
            let clamped = max(0, min(index, antigravityItems.count - 1))
            withAnimation(XomskyMotion.magneticGlide) {
                selectedIndex = clamped
            }
        }
    }
    
    public func selectChromeProfile(index: Int) {
        guard !profiles.isEmpty else { return }
        let clamped = max(0, min(index, profiles.count - 1))
        if let browserIdx = antigravityItems.firstIndex(where: { item in
            item.bundleID == ChromeProfileEngine.shared.browserBundleID ||
            ChromeProfileEngine.supportedBrowsers.contains(where: { b in b.bundleID == item.bundleID })
        }) {
            withAnimation(XomskyMotion.magneticGlide) {
                selectedIndex = browserIdx
                selectedProfileIndex = clamped
            }
        } else {
            withAnimation(XomskyMotion.magneticGlide) {
                mode = .chrome
                selectedIndex = clamped
                selectedProfileIndex = clamped
            }
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
        VStack(spacing: 3) {
            ZStack {
                // Frosted light circular plate
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
                    .frame(width: 20, height: 20)
                
                if let avatar = profile.avatarImage {
                    Image(nsImage: avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.35, green: 0.55, blue: 0.95), Color(red: 0.55, green: 0.35, blue: 0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text(String(profile.effectiveName.prefix(1)).uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                // Active cyan/white selection ring (exact match to reference frame)
                if isSelected {
                    Circle()
                        .stroke(Color(red: 130/255, green: 200/255, blue: 250/255), lineWidth: 1.75)
                        .frame(width: 24, height: 24)
                        .shadow(color: Color(red: 130/255, green: 200/255, blue: 250/255).opacity(0.45), radius: 2)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.75)
                        .frame(width: 22, height: 22)
                }
            }
            .frame(width: 24, height: 24)
            
            Text("\(slotIndex)")
                .font(.system(size: 9, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.60))
        }
        .frame(width: 24)
        .padding(.vertical, 1)
        .background {
            if isSelected {
                if let ns = namespace {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.white.opacity(0.20), lineWidth: 0.75)
                        )
                        .matchedGeometryEffect(id: "activeSlotCapsule", in: ns)
                } else {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.white.opacity(0.20), lineWidth: 0.75)
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

// MARK: - Native macOS HUD Card View
public struct HUDCardView: View {
    /// Deterministic standard width matching native macOS application switcher cards.
    public static let standardCardWidth: CGFloat = 132
    
    public let name: String
    public let icon: NSImage
    public let isSelected: Bool
    public let isBrowser: Bool
    public let profiles: [ChromeProfile]
    public let selectedProfileIndex: Int
    public let hasRowProfiles: Bool
    public var namespace: Namespace.ID?
    
    public init(
        name: String,
        icon: NSImage,
        isSelected: Bool,
        isBrowser: Bool,
        profiles: [ChromeProfile],
        selectedProfileIndex: Int,
        hasRowProfiles: Bool = true,
        namespace: Namespace.ID? = nil
    ) {
        self.name = name
        self.icon = icon
        self.isSelected = isSelected
        self.isBrowser = isBrowser
        self.profiles = profiles
        self.selectedProfileIndex = selectedProfileIndex
        self.hasRowProfiles = hasRowProfiles
        self.namespace = namespace
    }
    
    public var cardWidth: CGFloat {
        Self.standardCardWidth
    }
    
    private var cardHeight: CGFloat {
        hasRowProfiles ? 142 : 116
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            // 1. App Icon with continuous rounded rect and subtle shadow
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .shadow(color: Color.black.opacity(0.24), radius: 4, x: 0, y: 2)
                .padding(.top, 2)
            
            // 2. Primary Title Label
            Text(name)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.78))
                .lineLimit(1)
            
            // 3. Profiles Avatar Row or Balanced Spacer (when row has profiles)
            if isBrowser && !profiles.isEmpty {
                HStack(spacing: 4) {
                    ForEach(Array(profiles.enumerated()), id: \.element.id) { idx, profile in
                        ProfileAvatarView(
                            profile: profile,
                            isSelected: isSelected && (idx == selectedProfileIndex),
                            slotIndex: idx + 1,
                            namespace: namespace
                        )
                    }
                }
                .padding(.top, 2)
            } else if hasRowProfiles {
                Spacer().frame(height: 38)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .frame(width: cardWidth, height: cardHeight)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
            }
        }
        .scaleEffect(isSelected ? 1.02 : 0.98)
        .animation(XomskyMotion.magneticGlide, value: isSelected)
    }
}

// MARK: - Modern Switcher HUD View
public struct MinimalHUDView: View {
    @ObservedObject var state = ChromeSwitcherState.shared
    @Namespace private var selectionNamespace
    
    public init() {}
    
    private func isBrowser(_ item: AntigravityItem) -> Bool {
        let browserBundleID = ChromeProfileEngine.shared.browserBundleID
        if item.bundleID == browserBundleID { return true }
        return ChromeProfileEngine.supportedBrowsers.contains(where: { b in b.bundleID == item.bundleID })
    }
    
    private var hasRowProfiles: Bool {
        if state.mode == .chrome {
            return !state.profiles.isEmpty
        }
        return state.antigravityItems.contains(where: { isBrowser($0) }) && !state.profiles.isEmpty
    }
    
    @ViewBuilder
    private var cardsContent: some View {
        let rowHasProfiles = hasRowProfiles
        if state.mode == .chrome {
            HUDCardView(
                name: ChromeProfileEngine.shared.activeBrowserName,
                icon: ChromeProfileEngine.shared.activeBrowserIcon,
                isSelected: true,
                isBrowser: true,
                profiles: state.profiles,
                selectedProfileIndex: state.selectedProfileIndex,
                hasRowProfiles: rowHasProfiles,
                namespace: selectionNamespace
            )
        } else if !state.antigravityItems.isEmpty {
            ForEach(Array(state.antigravityItems.enumerated()), id: \.element.id) { cardIdx, item in
                let browser = isBrowser(item)
                HUDCardView(
                    name: item.name,
                    icon: item.icon,
                    isSelected: cardIdx == state.selectedIndex,
                    isBrowser: browser,
                    profiles: browser ? state.profiles : [],
                    selectedProfileIndex: state.selectedProfileIndex,
                    hasRowProfiles: rowHasProfiles,
                    namespace: selectionNamespace
                )
            }
        } else {
            HUDCardView(
                name: "Application",
                icon: NSWorkspace.shared.icon(for: .application),
                isSelected: true,
                isBrowser: false,
                profiles: [],
                selectedProfileIndex: 0,
                hasRowProfiles: false,
                namespace: selectionNamespace
            )
        }
    }
    
    public var body: some View {
        ZStack {
            HStack(spacing: 12) {
                cardsContent
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.85))
                    
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.24),
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
            .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
            .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 2)
            .scaleEffect(state.isVisible ? 1.0 : 0.93)
            .opacity(state.isVisible ? 1.0 : 0.0)
            .animation(XomskyMotion.interactiveSnap, value: state.isVisible)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 320),
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
            ChromeSwitcherState.shared.antigravityItems = []
            let validIndex = profiles.isEmpty ? 0 : max(0, min(selectedIndex, profiles.count - 1))
            ChromeSwitcherState.shared.selectedIndex = validIndex
            ChromeSwitcherState.shared.selectedProfileIndex = validIndex
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
    
    public func showAppGroup(mode: SwitcherMode, items: [AntigravityItem], selectedIndex: Int, profileIndex: Int = 0) {
        withAnimation(XomskyMotion.interactiveSnap) {
            ChromeSwitcherState.shared.mode = mode
            ChromeSwitcherState.shared.antigravityItems = items
            
            let profileEngine = ChromeProfileEngine.shared
            let containsBrowser = items.contains(where: { item in
                item.bundleID == profileEngine.browserBundleID ||
                ChromeProfileEngine.supportedBrowsers.contains(where: { b in b.bundleID == item.bundleID })
            })
            if containsBrowser {
                ChromeSwitcherState.shared.profiles = profileEngine.selectedProfiles
            } else {
                ChromeSwitcherState.shared.profiles = []
            }
            
            let validIndex = items.isEmpty ? 0 : max(0, min(selectedIndex, items.count - 1))
            let profCount = ChromeSwitcherState.shared.profiles.count
            let validProfIndex = profCount > 0 ? max(0, min(profileIndex, profCount - 1)) : 0
            
            ChromeSwitcherState.shared.selectedIndex = validIndex
            ChromeSwitcherState.shared.selectedProfileIndex = validProfIndex
            ChromeSwitcherState.shared.isVisible = true
        }
        
        reposition()
        resetAndSchedulePeek()
        self.alphaValue = 1.0
        self.orderFrontRegardless()
        triggerSensoryFeedback()
    }
    
    private func currentScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
            ?? NSScreen()
    }
    
    private func reposition() {
        let screen = currentScreen()
        let screenRect = screen.visibleFrame
        // Deterministic window sizing: 880pt width x 320pt height accommodates up to 5 cards (740pt max)
        // plus margins to cleanly contain the Apple drop shadow (24pt blur + 12pt offset) without clipping.
        let windowWidth: CGFloat = 880
        let windowHeight: CGFloat = 320
        let x = screenRect.midX - (windowWidth / 2)
        let y = screenRect.midY - (windowHeight / 2)
        let targetFrame = NSRect(x: x, y: y, width: windowWidth, height: windowHeight)
        if self.frame != targetFrame {
            self.setFrame(targetFrame, display: true)
            self.invalidateShadow()
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
            let profileEngine = ChromeProfileEngine.shared
            let isBrowser = app.bundleID == profileEngine.browserBundleID ||
                            ChromeProfileEngine.supportedBrowsers.contains(where: { $0.bundleID == app.bundleID })
            if isBrowser, let prof = ChromeSwitcherState.shared.selectedProfile {
                announcementText = "\(app.name), \(prof.effectiveName)"
            } else {
                announcementText = app.name
            }
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
    
    public func selectChromeProfile(index: Int) {
        peekTask?.cancel()
        if ChromeSwitcherState.shared.isMascotPeeking {
            withAnimation(XomskyMotion.interactiveSnap) {
                ChromeSwitcherState.shared.isMascotPeeking = false
            }
        }
        ChromeSwitcherState.shared.selectChromeProfile(index: index)
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
    
    public func selectNextCard() {
        peekTask?.cancel()
        if ChromeSwitcherState.shared.isMascotPeeking {
            withAnimation(XomskyMotion.interactiveSnap) {
                ChromeSwitcherState.shared.isMascotPeeking = false
            }
        }
        ChromeSwitcherState.shared.selectNextCard()
        triggerSensoryFeedback()
    }
    
    public func selectPreviousCard() {
        peekTask?.cancel()
        if ChromeSwitcherState.shared.isMascotPeeking {
            withAnimation(XomskyMotion.interactiveSnap) {
                ChromeSwitcherState.shared.isMascotPeeking = false
            }
        }
        ChromeSwitcherState.shared.selectPreviousCard()
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

