import SwiftUI
import Cocoa

@MainActor
public struct HUDOverlayView: View {
    @ObservedObject var engine = AppSwitcherEngine.shared
    
    public var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(engine.currentItems.enumerated()), id: \.element.id) { index, item in
                HUDItemCardView(
                    item: item,
                    index: index,
                    totalCount: engine.currentItems.count,
                    isSelected: index == engine.selectedIndex
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 20, x: 0, y: 10)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: engine.selectedIndex)
    }
}

@MainActor
public struct HUDItemCardView: View {
    let item: AppSwitcherItem
    let index: Int
    let totalCount: Int
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
            
            Text(item.displayName)
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
    }
    
    @ViewBuilder
    private var iconView: some View {
        if item.isChromeProfile {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(isSelected ? Color.cyan.opacity(0.8) : Color.white.opacity(0.25), lineWidth: isSelected ? 2 : 1)
                )
        } else {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 11))
        }
    }
    
    @ViewBuilder
    private var badgeView: some View {
        if item.isChromeProfile {
            Image(nsImage: AppDiscoveryService.shared.iconForApp(nameOrBundle: "Google Chrome"))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .offset(x: 3, y: 3)
        } else if let badge = item.badge {
            Text(badge)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Capsule().fill(Color.blue))
                .offset(x: 4, y: 2)
        }
    }
    
    @ViewBuilder
    private var indexBadgeView: some View {
        if totalCount > 1 {
            let label = "\(index + 1)"
            Text(label)
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
}

@MainActor
public final class HUDOverlayWindow: NSWindow {
    public static let shared = HUDOverlayWindow()
    
    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 110),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.contentView = NSHostingView(rootView: HUDOverlayView())
    }
    
    public func show() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let fittingSize = self.contentView?.fittingSize ?? NSSize(width: 300, height: 110)
        let x = screenFrame.origin.x + (screenFrame.width - fittingSize.width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - fittingSize.height) / 2
        
        self.setFrame(NSRect(x: x, y: y, width: fittingSize.width, height: fittingSize.height), display: true)
        self.orderFrontRegardless()
    }
    
    public func hide() {
        self.orderOut(nil)
    }
}
