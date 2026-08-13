import Foundation
import Combine
import AppKit

public struct ScheduledRule: Identifiable, Codable, Equatable {
    public var id: String
    public var timeString: String // "08:00", "18:30" format
    public var wallpaperId: String
    public var label: String // "Morning", "Evening", etc.
    public var isEnabled: Bool

    public init(id: String = UUID().uuidString, timeString: String, wallpaperId: String, label: String = "Schedule", isEnabled: Bool = true) {
        self.id = id
        self.timeString = timeString
        self.wallpaperId = wallpaperId
        self.label = label
        self.isEnabled = isEnabled
    }
}

public class SlideshowManager: ObservableObject {
    public static let shared = SlideshowManager()

    // Interval Slideshow Settings
    @Published public var isSlideshowEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSlideshowEnabled, forKey: "isSlideshowEnabled")
            updateSlideshowTimer()
        }
    }

    /// Rotation interval in seconds (e.g., 300 = 5 mins, 3600 = 1 hour)
    @Published public var intervalSeconds: Double {
        didSet {
            UserDefaults.standard.set(intervalSeconds, forKey: "slideshowIntervalSeconds")
            updateSlideshowTimer()
        }
    }

    @Published public var isShuffleEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isShuffleEnabled, forKey: "isShuffleEnabled")
        }
    }

    /// Set of wallpaper IDs explicitly selected for the slideshow playlist.
    /// If empty, all library wallpapers are included by default.
    @Published public var includedWallpaperIds: Set<String> {
        didSet {
            let arr = Array(includedWallpaperIds)
            UserDefaults.standard.set(arr, forKey: "slideshowIncludedIds")
        }
    }

    @Published public var nextRotationDate: Date? = nil

    // Timed Schedule Rules
    @Published public var scheduleRules: [ScheduledRule] {
        didSet {
            saveScheduleRules()
        }
    }

    private var slideshowTimer: Timer?
    private var scheduledTimeTimer: Timer?
    private var lastTriggeredScheduleMinute: String = ""

    private init() {
        let defaults = UserDefaults.standard
        self.isSlideshowEnabled = defaults.bool(forKey: "isSlideshowEnabled")
        self.intervalSeconds = defaults.object(forKey: "slideshowIntervalSeconds") as? Double ?? 900 // default 15 min
        self.isShuffleEnabled = defaults.bool(forKey: "isShuffleEnabled")

        if let savedIds = defaults.array(forKey: "slideshowIncludedIds") as? [String] {
            self.includedWallpaperIds = Set(savedIds)
        } else {
            self.includedWallpaperIds = Set()
        }

        if let data = defaults.data(forKey: "scheduleRules"),
           let rules = try? JSONDecoder().decode([ScheduledRule].self, from: data) {
            self.scheduleRules = rules
        } else {
            // Default sample schedules
            self.scheduleRules = [
                ScheduledRule(timeString: "08:00", wallpaperId: "aurora", label: "Morning Sunrise"),
                ScheduledRule(timeString: "18:00", wallpaperId: "cyberpunk", label: "Evening Sunset"),
                ScheduledRule(timeString: "22:00", wallpaperId: "space", label: "Night Cosmos")
            ]
        }

        setupObservers()
        updateSlideshowTimer()
        startScheduledTimeTimer()
    }

    private func setupObservers() {
        // Stop timer when system sleeps, resume on wake
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                self?.stopSlideshowTimer()
            }
            .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                self?.updateSlideshowTimer()
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Interval Slideshow Engine

    private func updateSlideshowTimer() {
        slideshowTimer?.invalidate()
        slideshowTimer = nil
        nextRotationDate = nil

        guard isSlideshowEnabled else { return }

        nextRotationDate = Date().addingTimeInterval(intervalSeconds)

        slideshowTimer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            self?.rotateWallpaper()
        }
    }

    private func stopSlideshowTimer() {
        slideshowTimer?.invalidate()
        slideshowTimer = nil
        nextRotationDate = nil
    }

    public func rotateWallpaper() {
        let storage = WallpaperStorageManager.shared
        let allWallpapers = storage.wallpapers
        guard !allWallpapers.isEmpty else { return }

        // Filter by user selection if playlist is non-empty
        let wallpapers: [WallpaperItem]
        if includedWallpaperIds.isEmpty {
            wallpapers = allWallpapers
        } else {
            let filtered = allWallpapers.filter { includedWallpaperIds.contains($0.id) }
            wallpapers = filtered.isEmpty ? allWallpapers : filtered
        }

        let activeId = storage.activeWallpaperId
        let nextWallpaper: WallpaperItem?

        if isShuffleEnabled {
            let candidates = wallpapers.filter { $0.id != activeId }
            nextWallpaper = candidates.randomElement() ?? wallpapers.first
        } else {
            if let currentIndex = wallpapers.firstIndex(where: { $0.id == activeId }) {
                let nextIndex = (currentIndex + 1) % wallpapers.count
                nextWallpaper = wallpapers[nextIndex]
            } else {
                nextWallpaper = wallpapers.first
            }
        }

        if let item = nextWallpaper {
            storage.setActiveWallpaper(item)
            nextRotationDate = Date().addingTimeInterval(intervalSeconds)
            print("[SlideshowManager] Switched wallpaper to: \(item.title) (\(item.id))")
        }
    }

    // MARK: - Playlist Selection Helpers

    public func toggleWallpaperInSlideshow(id: String) {
        if includedWallpaperIds.contains(id) {
            includedWallpaperIds.remove(id)
        } else {
            includedWallpaperIds.insert(id)
        }
    }

    public func isWallpaperIncluded(id: String) -> Bool {
        if includedWallpaperIds.isEmpty { return true } // All included by default
        return includedWallpaperIds.contains(id)
    }

    public func selectAllWallpapers() {
        let allIds = WallpaperStorageManager.shared.wallpapers.map { $0.id }
        includedWallpaperIds = Set(allIds)
    }

    public func clearPlaylist() {
        includedWallpaperIds.removeAll()
    }

    // MARK: - Time-of-Day Scheduled Triggers

    private func startScheduledTimeTimer() {
        scheduledTimeTimer?.invalidate()

        // Check every 10 seconds for time rule matches
        scheduledTimeTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkTimeSchedules()
        }
    }

    private func checkTimeSchedules() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentMinute = formatter.string(from: Date())

        // Prevent double trigger in same minute
        guard currentMinute != lastTriggeredScheduleMinute else { return }

        for rule in scheduleRules where rule.isEnabled {
            if rule.timeString == currentMinute {
                lastTriggeredScheduleMinute = currentMinute
                let storage = WallpaperStorageManager.shared
                if let item = storage.wallpapers.first(where: { $0.id == rule.wallpaperId }) {
                    storage.setActiveWallpaper(item)
                    print("[SlideshowManager] Scheduled Rule '\(rule.label)' triggered for time \(currentMinute)")
                }
                break
            }
        }
    }

    // MARK: - Schedule Management

    public func addRule(timeString: String, wallpaperId: String, label: String) {
        let newRule = ScheduledRule(timeString: timeString, wallpaperId: wallpaperId, label: label)
        scheduleRules.append(newRule)
    }

    public func deleteRule(id: String) {
        scheduleRules.removeAll(where: { $0.id == id })
    }

    public func toggleRule(id: String) {
        if let idx = scheduleRules.firstIndex(where: { $0.id == id }) {
            scheduleRules[idx].isEnabled.toggle()
            saveScheduleRules()
        }
    }

    private func saveScheduleRules() {
        if let data = try? JSONEncoder().encode(scheduleRules) {
            UserDefaults.standard.set(data, forKey: "scheduleRules")
        }
    }
}
