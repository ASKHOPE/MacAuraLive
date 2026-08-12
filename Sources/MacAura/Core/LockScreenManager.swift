import AppKit
import Combine

public class LockScreenManager: ObservableObject {
    public static let shared = LockScreenManager()
    
    @Published public var isScreenLocked: Bool = false
    
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
                self?.isScreenLocked = true
            }
            .store(in: &cancellables)
            
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.sessionDidBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.isScreenLocked = false
            }
            .store(in: &cancellables)
    }
    
    @objc private func screenDidLock() {
        DispatchQueue.main.async {
            self.isScreenLocked = true
            print("[LockScreenManager] Screen Locked")
        }
    }
    
    @objc private func screenDidUnlock() {
        DispatchQueue.main.async {
            self.isScreenLocked = false
            print("[LockScreenManager] Screen Unlocked")
        }
    }
}
