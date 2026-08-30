import SwiftUI
import Cocoa

struct HUDOverlayView: View {
    @ObservedObject var engine = AppSwitcherEngine.shared
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(engine.currentItems.enumerated()), id: \.element.id) { index, item in
                let isSelected = (index == engine.selectedIndex)
                
                VStack(spacing: 8) {
                    Image(nsImage: item.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                    
                    Text(item.displayName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.75))
                        .lineLimit(1)
                        .frame(width: 80)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue.opacity(0.65) : Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.cyan : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
    }
}

final class HUDOverlayWindow: NSWindow {
    static let shared = HUDOverlayWindow()
    
    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 120),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.contentView = NSHostingView(rootView: HUDOverlayView())
    }
    
    func show() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let fittingSize = self.contentView?.fittingSize ?? NSSize(width: 300, height: 120)
        let x = screenFrame.origin.x + (screenFrame.width - fittingSize.width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - fittingSize.height) / 2
        
        self.setFrame(NSRect(x: x, y: y, width: fittingSize.width, height: fittingSize.height), display: true)
        self.orderFrontRegardless()
    }
    
    func hide() {
        self.orderOut(nil)
    }
}
