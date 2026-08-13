import AppKit
import Combine

public class LockScreenManager: ObservableObject {
    public static let shared = LockScreenManager()

    @Published public var isScreenLocked: Bool = false
    @Published public var applyStatus: String = ""

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        let distCenter = DistributedNotificationCenter.default()

        distCenter.addObserver(
            self,
            selector: #selector(screenDidLock),
            name: Notification.Name("com.apple.screenIsLocked"),
            object: nil
        )
        distCenter.addObserver(
            self,
            selector: #selector(screenDidUnlock),
            name: Notification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )

        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.sessionDidResignActiveNotification)
            .sink { [weak self] _ in self?.isScreenLocked = true }
            .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.sessionDidBecomeActiveNotification)
            .sink { [weak self] _ in self?.isScreenLocked = false }
            .store(in: &cancellables)
    }

    @objc private func screenDidLock() {
        DispatchQueue.main.async { self.isScreenLocked = true }
    }

    @objc private func screenDidUnlock() {
        DispatchQueue.main.async { self.isScreenLocked = false }
    }

    // MARK: - Set Static Lock Screen Wallpaper

    /// Sets a static image file as the system desktop wallpaper on all screens.
    /// macOS lock screen always mirrors the desktop wallpaper, so this image
    /// will appear on the lock screen automatically.
    public func setStaticLockScreenWallpaper(url: URL) {
        var successCount = 0
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true
        ]
        for screen in NSScreen.screens {
            do {
                try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: options)
                successCount += 1
            } catch {
                print("[LockScreenManager] setDesktopImageURL error: \(error.localizedDescription)")
            }
        }
        DispatchQueue.main.async {
            self.applyStatus = successCount > 0
                ? "Wallpaper applied to \(successCount) display(s). Lock your screen to see it."
                : "Failed to set wallpaper. Make sure the file exists and is a supported image."
        }
    }
}
