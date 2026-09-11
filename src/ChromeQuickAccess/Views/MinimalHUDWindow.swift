import Cocoa
import AppKit
import SwiftUI

public struct MinimalHUDView: View {
    public let profile: ChromeProfile
    
    public var body: some View {
        HStack(spacing: 16) {
            if let avatar = profile.avatarImage {
                Image(nsImage: avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(profile.effectiveName.prefix(1)).uppercased())
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.effectiveName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let email = profile.email, !email.isEmpty {
                    Text(email)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 8)
            
            Text("⌥\(profile.index)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.2))
                .cornerRadius(6)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(minWidth: 260, maxWidth: 360)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
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

@MainActor
public final class MinimalHUDWindow: NSWindow {
    public static let shared = MinimalHUDWindow()
    
    private var hideWorkItem: DispatchWorkItem?
    
    public init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    }
    
    public func show(for profile: ChromeProfile) {
        hideWorkItem?.cancel()
        
        let hostingView = NSHostingView(rootView: MinimalHUDView(profile: profile))
        self.contentView = hostingView
        
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - 160
            let y = screenRect.minY + 90 // Float near center-bottom
            self.setFrame(NSRect(x: x, y: y, width: 320, height: 80), display: true)
        }
        
        self.alphaValue = 1.0
        self.orderFrontRegardless()
        
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                self.animator().alphaValue = 0.0
            }, completionHandler: {
                self.orderOut(nil)
                self.alphaValue = 1.0
            })
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }
    
    public func hideImmediate() {
        hideWorkItem?.cancel()
        self.orderOut(nil)
        self.alphaValue = 1.0
    }
}
