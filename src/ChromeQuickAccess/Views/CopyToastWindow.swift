import Cocoa
import AppKit
import SwiftUI

// MARK: - Copy Toast View
public struct CopyToastView: View {
    public let isVisible: Bool
    
    public init(isVisible: Bool) {
        self.isVisible = isVisible
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(Color(red: 0.35, green: 0.88, blue: 0.52))
            
            Text("Copied")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            ZStack {
                Capsule()
                    .fill(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.88))
                Capsule()
                    .fill(.ultraThinMaterial)
            }
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.75
                )
        )
        .shadow(color: Color.black.opacity(0.30), radius: 8, x: 0, y: 4)
        .scaleEffect(isVisible ? 1.0 : 0.80)
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isVisible ? 0 : 6)
        .animation(XomskyMotion.tactileBop, value: isVisible)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Copy Toast State
@MainActor
public final class CopyToastState: ObservableObject {
    public static let shared = CopyToastState()
    @Published public var isVisible: Bool = false
}

// MARK: - Copy Toast Window
@MainActor
public final class CopyToastWindow: NSPanel {
    public static let shared = CopyToastWindow()
    
    private var dismissTask: Task<Void, Never>?
    
    public init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 120, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        
        let hosting = NSHostingView(rootView: CopyToastHostingRoot())
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = .clear
        self.contentView = hosting
    }
    
    /// Positions and presents the ephemeral toast near the cursor point
    public func show(at mouseLocation: CGPoint) {
        dismissTask?.cancel()
        
        // Offset slightly above and to the right of the cursor
        let toastWidth: CGFloat = 110
        let toastHeight: CGFloat = 36
        var originX = mouseLocation.x + 12
        var originY = mouseLocation.y + 12
        
        // Clamp to screen bounds if available
        if let screen = NSScreen.screens.first(where: { NSPointInRect(mouseLocation, $0.frame) }) ?? NSScreen.main {
            let visible = screen.visibleFrame
            if originX + toastWidth > visible.maxX {
                originX = mouseLocation.x - toastWidth - 8
            }
            if originY + toastHeight > visible.maxY {
                originY = mouseLocation.y - toastHeight - 8
            }
            originX = max(visible.minX + 8, originX)
            originY = max(visible.minY + 8, originY)
        }
        
        self.setFrame(NSRect(x: originX, y: originY, width: toastWidth, height: toastHeight), display: true)
        
        withAnimation(XomskyMotion.tactileBop) {
            CopyToastState.shared.isVisible = true
        }
        self.alphaValue = 1.0
        self.orderFrontRegardless()
        
        // Auto-dismiss after 450ms with smooth fade out
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled, let self = self else { return }
            
            withAnimation(.easeOut(duration: 0.15)) {
                CopyToastState.shared.isVisible = false
            }
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            self.orderOut(nil)
        }
    }
    
    public func hideImmediate() {
        dismissTask?.cancel()
        dismissTask = nil
        CopyToastState.shared.isVisible = false
        self.orderOut(nil)
    }
}

// MARK: - Hosting Root View
private struct CopyToastHostingRoot: View {
    @ObservedObject var state = CopyToastState.shared
    
    var body: some View {
        CopyToastView(isVisible: state.isVisible)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
