import AppKit
import Combine

public class WallpaperEngine: ObservableObject {
    public static let shared = WallpaperEngine()
    
    @Published public var displays: [DisplayInfo] = []
    @Published public var isPaused: Bool = false
    @Published public var perDisplayWallpaperMap: [CGDirectDisplayID: String] = [:] // displayID -> wallpaperID
    
    // Playback Timeline Slider Tracking
    @Published public var playbackCurrentTime: Double = 0.0
    @Published public var playbackDuration: Double = 0.0
    
    private var windowMap: [CGDirectDisplayID: WallpaperWindow] = [:] // displayID -> WallpaperWindow
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        updateDisplays()
        setupObservers()
    }
    
    public func updateDisplays() {
        let screens = NSScreen.screens
        var updatedList: [DisplayInfo] = []
        
        for screen in screens {
            let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? 0
            let isMain = screen == NSScreen.main
            let info = DisplayInfo(
                id: displayID,
                name: screen.localizedName,
                bounds: screen.frame,
                scaleFactor: screen.backingScaleFactor,
                isMain: isMain
            )
            updatedList.append(info)
        }
        
        self.displays = updatedList
    }
    
    private func setupObservers() {
        // Monitor connect / disconnect listener
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.updateDisplays()
                self?.reloadEngine()
            }
            .store(in: &cancellables)
            
        // Observe Span Across Displays toggle
        AppSettings.shared.$spanAcrossDisplays
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.reloadEngine()
                }
            }
            .store(in: &cancellables)
            
        // Observe Audio Volume & Mute Settings
        Publishers.CombineLatest(AppSettings.shared.$audioVolume, AppSettings.shared.$isMuted)
            .sink { [weak self] (vol, muted) in
                DispatchQueue.main.async {
                    self?.updateAudioSettings(volume: vol, isMuted: muted)
                }
            }
            .store(in: &cancellables)

        // Observe Playback Speed Rate
        AppSettings.shared.$playbackRate
            .sink { [weak self] rate in
                DispatchQueue.main.async {
                    self?.updatePlaybackRate(rate)
                }
            }
            .store(in: &cancellables)
            
        // Observe Lock Screen settings
        Publishers.CombineLatest(AppSettings.shared.$enableLockScreenWallpaper, AppSettings.shared.$lockScreenWallpaperId)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.reloadEngine()
                }
            }
            .store(in: &cancellables)
            
        // Observe Wallpaper Placement & Zoom Settings
        Publishers.CombineLatest(AppSettings.shared.$wallpaperPlacement, AppSettings.shared.$wallpaperZoom)
            .sink { [weak self] (placement, zoom) in
                DispatchQueue.main.async {
                    self?.updatePlacementSettings(placement: placement, zoom: zoom)
                }
            }
            .store(in: &cancellables)
            
        // Observe PerformanceManager notifications
        NotificationCenter.default.publisher(for: Notification.Name("PerformanceTierChanged"))
            .sink { [weak self] notification in
                if let tier = notification.object as? PerformanceTier {
                    self?.applyPerformanceTier(tier)
                }
            }
            .store(in: &cancellables)
    }
    
    private func applyPerformanceTier(_ tier: PerformanceTier) {
        DispatchQueue.main.async {
            if tier == .paused {
                self.pauseAll()
            } else {
                if self.isPaused {
                    // Stay paused
                } else {
                    self.resumeAll()
                }
            }
        }
    }
    
    
    public func startEngine() {
        reloadEngine()
    }
    
    public func reloadEngine() {
        let storage = WallpaperStorageManager.shared
        let settings = AppSettings.shared
        guard let defaultWallpaper = storage.getActiveWallpaper() else { return }
        let screens = NSScreen.screens
        
        var currentScreenIDs = Set<CGDirectDisplayID>()
        let isLockedSession = LockScreenManager.shared.isScreenLocked && settings.enableLockScreenWallpaper
        
        for screen in screens {
            let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? 0
            currentScreenIDs.insert(displayID)
            
            let targetWallpaperId: String
            if isLockedSession {
                targetWallpaperId = settings.lockScreenWallpaperId
            } else if settings.spanAcrossDisplays {
                targetWallpaperId = defaultWallpaper.id
            } else {
                targetWallpaperId = perDisplayWallpaperMap[displayID] ?? defaultWallpaper.id
            }
            
            let wallpaper = storage.wallpapers.first(where: { $0.id == targetWallpaperId }) ?? defaultWallpaper
            
            let win: WallpaperWindow
            if let existingWin = windowMap[displayID] {
                win = existingWin
                win.setFrame(screen.frame, display: true)
            } else {
                win = WallpaperWindow(screen: screen)
                windowMap[displayID] = win
            }
            
            win.setLockScreenLevel(isLocked: isLockedSession)
            
            if let renderView = createView(for: wallpaper, screenFrame: screen.frame) {
                win.updateContent(view: renderView)
            }
        }
        
        // Remove stale display windows
        for (id, win) in windowMap {
            if !currentScreenIDs.contains(id) {
                win.orderOut(nil)
                windowMap.removeValue(forKey: id)
            }
        }
        
        if self.isPaused {
            self.pauseAll()
        } else {
            self.resumeAll()
        }
    }
    
    public func getActiveWallpaperTitle() -> String {
        let storage = WallpaperStorageManager.shared
        if let mainScreen = NSScreen.main {
            let mainID = (mainScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? 0
            let targetID = perDisplayWallpaperMap[mainID] ?? storage.activeWallpaperId
            if let item = storage.wallpapers.first(where: { $0.id == targetID }) {
                return item.title
            }
        }
        return storage.getActiveWallpaper()?.title ?? "Aurora Borealis"
    }
    
    public func getWallpaperIdForDisplay(displayID: CGDirectDisplayID) -> String {
        return perDisplayWallpaperMap[displayID] ?? WallpaperStorageManager.shared.activeWallpaperId
    }
    
    public func setWallpaperForDisplay(displayID: CGDirectDisplayID, wallpaperID: String) {
        perDisplayWallpaperMap[displayID] = wallpaperID
        reloadEngine()
    }
    
    public func updatePlaybackPosition(current: Double, duration: Double) {
        self.playbackCurrentTime = current
        self.playbackDuration = duration
    }
    
    public func seekToPosition(seconds: Double) {
        self.playbackCurrentTime = seconds
        for win in windowMap.values {
            if let vidView = win.contentView as? VideoWallpaperView {
                vidView.seek(to: seconds)
            }
        }
    }
    
    public func updatePlaybackRate(_ rate: Float) {
        for win in windowMap.values {
            if let vidView = win.contentView as? VideoWallpaperView {
                vidView.setPlaybackRate(rate)
            }
        }
    }
    
    public func updateAudioSettings(volume: Double, isMuted: Bool) {
        for win in windowMap.values {
            if let webView = win.contentView as? WebWallpaperView {
                webView.setVolume(volume, isMuted: isMuted)
            } else if let vidView = win.contentView as? VideoWallpaperView {
                vidView.setVolume(volume, isMuted: isMuted)
            }
        }
    }
    
    public func updatePlacementSettings(placement: String, zoom: Double) {
        for win in windowMap.values {
            if let webView = win.contentView as? WebWallpaperView {
                webView.setPlacement(placement, zoom: zoom)
            } else if let vidView = win.contentView as? VideoWallpaperView {
                vidView.setPlacement(placement: placement, zoom: zoom)
            }
        }
    }
    
    public func updateActiveWallpaperSettings(_ jsonString: String) {
        for win in windowMap.values {
            if let webView = win.contentView as? WebWallpaperView {
                webView.setCustomSettings(jsonString)
            }
        }
    }
    
    private func createView(for wallpaper: WallpaperItem, screenFrame: CGRect) -> NSView? {
        let settings = AppSettings.shared
        let view: NSView?
        
        switch wallpaper.type {
        case .builtInWeb:
            guard let resourcePath = Bundle.module.path(forResource: wallpaper.pathOrUrl, ofType: nil, inDirectory: "Resources/Wallpapers") ?? getLocalResourcePath(relative: wallpaper.pathOrUrl) else {
                return nil
            }
            let url = URL(fileURLWithPath: resourcePath)
            let webView = WebWallpaperView(url: url)
            webView.setVolume(settings.audioVolume, isMuted: settings.isMuted)
            view = webView
            
        case .webUrl:
            guard let url = URL(string: wallpaper.pathOrUrl) else { return nil }
            let webView = WebWallpaperView(url: url)
            webView.setVolume(settings.audioVolume, isMuted: settings.isMuted)
            view = webView
            
        case .video:
            let url = URL(fileURLWithPath: wallpaper.pathOrUrl)
            return VideoWallpaperView(videoURL: url, volume: settings.audioVolume, isMuted: settings.isMuted)
            
        case .gif, .image:
            let url = URL(fileURLWithPath: wallpaper.pathOrUrl)
            let webView = WebWallpaperView(url: url)
            webView.setVolume(settings.audioVolume, isMuted: settings.isMuted)
            view = webView
        }
        
        if let webView = view as? WebWallpaperView,
           let customSettings = wallpaper.customSettings,
           let data = try? JSONSerialization.data(withJSONObject: customSettings),
           let jsonString = String(data: data, encoding: .utf8) {
            webView.setCustomSettings(jsonString)
        }
        
        return view
    }
    
    private func getLocalResourcePath(relative: String) -> String? {
        let bundleURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Wallpapers/" + relative)
        if FileManager.default.fileExists(atPath: bundleURL.path) {
            return bundleURL.path
        }
        return nil
    }
    
    public func pauseAll() {
        for win in windowMap.values {
            if let webView = win.contentView as? WebWallpaperView {
                webView.pause()
            } else if let vidView = win.contentView as? VideoWallpaperView {
                vidView.pause()
            }
        }
        objectWillChange.send()
    }
    
    public func resumeAll() {
        for win in windowMap.values {
            if let webView = win.contentView as? WebWallpaperView {
                webView.resume()
            } else if let vidView = win.contentView as? VideoWallpaperView {
                vidView.play()
            }
        }
        objectWillChange.send()
    }
    
    public func togglePlayPause() {
        objectWillChange.send()
        isPaused.toggle()
        if isPaused {
            pauseAll()
        } else {
            resumeAll()
        }
    }
}
