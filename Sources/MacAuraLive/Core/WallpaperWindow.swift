import AppKit

public class WallpaperWindow: NSWindow {
    public var screenDisplayID: CGDirectDisplayID = 0
    
    public override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: backingStoreType,
            defer: flag
        )
        configureDesktopWindow()
    }
    
    public convenience init(screen: NSScreen) {
        let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? 0
        let screenRect = screen.frame
        self.init(
            contentRect: screenRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.screenDisplayID = displayID
        self.setFrame(screenRect, display: true)
    }
    
    private func configureDesktopWindow() {
        // Explicitly disable AppKit window transform animations
        self.animationBehavior = .none
        self.isReleasedWhenClosed = false
        
        // Position window on desktop layer (below icons & app windows)
        let desktopLevel = Int(CGWindowLevelForKey(.desktopWindow))
        self.level = NSWindow.Level(desktopLevel)
        
        self.isOpaque = true
        self.backgroundColor = .black
        self.hasShadow = false
        self.canHide = false
        self.ignoresMouseEvents = true
        
        // Keep window across all Spaces, Lock Screen auxiliary layer, and full-screen apps
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle,
            .fullScreenDisallowsTiling
        ]
    }
    
    public func setLockScreenLevel(isLocked: Bool) {
        if isLocked {
            let lockLevel = Int(CGWindowLevelForKey(.screenSaverWindow))
            self.level = NSWindow.Level(lockLevel)
        } else {
            let desktopLevel = Int(CGWindowLevelForKey(.desktopWindow))
            self.level = NSWindow.Level(desktopLevel)
        }
    }
    
    public func updateContent(view: NSView) {
        // Pause/clean old subviews if any
        if let oldWeb = self.contentView as? WebWallpaperView {
            oldWeb.pause()
        } else if let oldVid = self.contentView as? VideoWallpaperView {
            oldVid.pause()
        }
        
        view.frame = self.contentView?.bounds ?? self.frame
        view.autoresizingMask = [.width, .height]
        self.contentView = view
        self.orderFrontRegardless()
    }
}
