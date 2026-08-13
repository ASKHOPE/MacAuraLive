import AppKit
import Combine

public class LockScreenManager: ObservableObject {
    public static let shared = LockScreenManager()
    
    @Published public var isScreenLocked: Bool = false
    @Published public var snapshotStatus: String = ""
    
    /// URL of the last snapshot written to disk (for restoration)
    private var snapshotURL: URL?
    /// Previous desktop wallpaper URLs so we can restore them on unlock
    private var previousWallpaperURLs: [NSScreen: URL] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        let distCenter = DistributedNotificationCenter.default()
        
        // Listen to macOS screen lock
        distCenter.addObserver(
            self,
            selector: #selector(screenDidLock),
            name: Notification.Name("com.apple.screenIsLocked"),
            object: nil
        )
        
        // Listen to macOS screen unlock
        distCenter.addObserver(
            self,
            selector: #selector(screenDidUnlock),
            name: Notification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
        
        // Workspace session active state
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.sessionDidResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleLock()
            }
            .store(in: &cancellables)
            
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.sessionDidBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleUnlock()
            }
            .store(in: &cancellables)
    }
    
    @objc private func screenDidLock() {
        DispatchQueue.main.async {
            self.handleLock()
        }
    }
    
    @objc private func screenDidUnlock() {
        DispatchQueue.main.async {
            self.handleUnlock()
        }
    }
    
    private func handleLock() {
        guard !isScreenLocked else { return }
        isScreenLocked = true
        print("[LockScreenManager] Screen Locked")
        
        // Elevate wallpaper window level so it renders at lock screen layer
        WallpaperEngine.shared.reloadEngine()
        
        // If lock screen wallpaper is enabled, snapshot the live wallpaper and set as system wallpaper
        if AppSettings.shared.enableLockScreenWallpaper {
            captureAndSetDesktopSnapshot()
        }
    }
    
    private func handleUnlock() {
        guard isScreenLocked else { return }
        isScreenLocked = false
        print("[LockScreenManager] Screen Unlocked")
        
        // Restore wallpaper window to desktop level
        WallpaperEngine.shared.reloadEngine()
    }
    
    // MARK: - Snapshot & Desktop Wallpaper
    
    /// Captures the current live wallpaper window as a PNG image, saves it to a temp
    /// file, and sets it as the system desktop wallpaper for all screens.
    /// Since macOS lock screen mirrors the desktop wallpaper, the lock screen will
    /// display this snapshot automatically.
    public func captureAndSetDesktopSnapshot() {
        guard let windowID = findWallpaperWindowID() else {
            snapshotStatus = "No wallpaper window found to snapshot."
            print("[LockScreenManager] captureAndSetDesktopSnapshot: no window found")
            return
        }
        
        // Capture the window image using CoreGraphics
        guard let cgImage = CGWindowListCreateImage(
            .infinite,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .nominalResolution]
        ) else {
            snapshotStatus = "Failed to capture wallpaper snapshot."
            print("[LockScreenManager] captureAndSetDesktopSnapshot: CGWindowListCreateImage failed")
            return
        }
        
        // Save snapshot to temp directory
        let tempDir = FileManager.default.temporaryDirectory
        let snapURL = tempDir.appendingPathComponent("macaura_lockscreen_snapshot.png")
        
        guard let dest = CGImageDestinationCreateWithURL(snapURL as CFURL, "public.png" as CFString, 1, nil) else {
            snapshotStatus = "Failed to create image destination."
            return
        }
        CGImageDestinationAddImage(dest, cgImage, nil)
        guard CGImageDestinationFinalize(dest) else {
            snapshotStatus = "Failed to write snapshot PNG."
            return
        }
        
        self.snapshotURL = snapURL
        
        // Save previous wallpapers so we could restore (optional)
        var previous: [NSScreen: URL] = [:]
        for screen in NSScreen.screens {
            if let existing = NSWorkspace.shared.desktopImageURL(for: screen) {
                previous[screen] = existing
            }
        }
        self.previousWallpaperURLs = previous
        
        // Set the snapshot as desktop wallpaper on all screens
        var successCount = 0
        for screen in NSScreen.screens {
            do {
                let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
                    .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
                    .allowClipping: true
                ]
                try NSWorkspace.shared.setDesktopImageURL(snapURL, for: screen, options: options)
                successCount += 1
            } catch {
                print("[LockScreenManager] setDesktopImageURL failed for screen: \(error.localizedDescription)")
            }
        }
        
        if successCount > 0 {
            snapshotStatus = "Lock screen snapshot applied to \(successCount) display(s)."
        } else {
            snapshotStatus = "Snapshot captured but could not set desktop wallpaper."
        }
        
        print("[LockScreenManager] \(snapshotStatus)")
    }
    
    /// Finds the CGWindowID of the first MacAura wallpaper window (level = screenSaverWindow or desktopWindow)
    private func findWallpaperWindowID() -> CGWindowID? {
        let options = CGWindowListOption([.excludeDesktopElements, .optionOnScreenOnly])
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            // Fallback: try including desktop elements
            let allWindows = CGWindowListOption([.optionAll])
            guard let list = CGWindowListCopyWindowInfo(allWindows, kCGNullWindowID) as? [[String: Any]] else {
                return nil
            }
            return findMacAuraWindow(in: list)
        }
        return findMacAuraWindow(in: windowList)
    }
    
    private func findMacAuraWindow(in list: [[String: Any]]) -> CGWindowID? {
        let ourPID = ProcessInfo.processInfo.processIdentifier
        for info in list {
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t,
                  pid == ourPID,
                  let windowID = info[kCGWindowNumber as String] as? CGWindowID,
                  let layer = info[kCGWindowLayer as String] as? Int else { continue }
            // Desktop window layer is typically -2147483623 range; screenSaver is higher
            // Our wallpaper windows are borderless at desktop or screenSaver level
            let desktopLayer = Int(CGWindowLevelForKey(.desktopWindow))
            let saverLayer = Int(CGWindowLevelForKey(.screenSaverWindow))
            if layer == desktopLayer || layer == saverLayer {
                return windowID
            }
        }
        // Fallback: return first window owned by this process
        for info in list {
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t,
                  pid == ourPID,
                  let windowID = info[kCGWindowNumber as String] as? CGWindowID else { continue }
            return windowID
        }
        return nil
    }
}
