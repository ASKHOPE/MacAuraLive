import Foundation
import AppKit
import Combine
import SwiftUI

public class MoodProfileManager: ObservableObject {
    public static let shared = MoodProfileManager()
    
    @Published public var moods: [MoodProfile] = []
    @Published public var activeMoodId: String? = nil
    @Published public var isSyncEnabled: Bool = true
    @Published public var lastTriggeredReason: String? = nil
    
    private var cycleTimer: Timer?
    private var currentCycleIndex: Int = 0
    private let storageKey = "MacAuraLive_SavedMoods"
    private let activeMoodKey = "MacAuraLive_ActiveMoodId"
    private let syncEnabledKey = "MacAuraLive_MoodSyncEnabled"
    
    private init() {
        self.isSyncEnabled = UserDefaults.standard.object(forKey: syncEnabledKey) as? Bool ?? true
        self.activeMoodId = UserDefaults.standard.string(forKey: activeMoodKey)
        loadMoods()
        setupSystemObservers()
    }
    
    // MARK: - Persistence & Defaults
    
    public func loadMoods() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([MoodProfile].self, from: data),
           !decoded.isEmpty {
            self.moods = decoded
        } else {
            self.moods = createDefaultMoods()
            saveMoods()
        }
    }
    
    public func saveMoods() {
        if let data = try? JSONEncoder().encode(moods) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func createDefaultMoods() -> [MoodProfile] {
        let allItems = WallpaperStorageManager.shared.wallpapers
        
        let darkWallpapers = allItems.filter {
            $0.title.lowercased().contains("night") ||
            $0.title.lowercased().contains("dark") ||
            $0.title.lowercased().contains("cyber") ||
            $0.title.lowercased().contains("aurora")
        }.map { $0.id }
        
        let chillWallpapers = allItems.filter {
            $0.title.lowercased().contains("zen") ||
            $0.title.lowercased().contains("nature") ||
            $0.title.lowercased().contains("water") ||
            $0.title.lowercased().contains("rain") ||
            $0.title.lowercased().contains("forest")
        }.map { $0.id }
        
        let vibrantWallpapers = allItems.filter {
            $0.type == .builtInWeb || $0.type == .video
        }.map { $0.id }
        
        return [
            MoodProfile(
                name: "Deep Focus",
                description: "Calm, minimal dark themes designed to prevent distraction during coding and writing.",
                icon: "brain.head.profile",
                accentColorHex: "#3B82F6",
                wallpaperIDs: darkWallpapers.isEmpty ? allItems.prefix(2).map { $0.id } : Array(darkWallpapers.prefix(3)),
                playbackMode: .single,
                cycleIntervalMinutes: 30,
                isMuted: true,
                linkedMode: .doNotDisturb,
                isBuiltIn: true
            ),
            MoodProfile(
                name: "Night Sanctuary",
                description: "Deep starry nights and cozy dark visuals matching macOS Sleep and evening hours.",
                icon: "moon.stars.fill",
                accentColorHex: "#8B5CF6",
                wallpaperIDs: darkWallpapers.isEmpty ? allItems.prefix(2).map { $0.id } : Array(darkWallpapers.prefix(3)),
                playbackMode: .sequenceCycle,
                cycleIntervalMinutes: 20,
                isMuted: true,
                linkedMode: .appearanceDark,
                isBuiltIn: true
            ),
            MoodProfile(
                name: "Day Flow & Energy",
                description: "Bright, energetic landscape views for peak daytime productivity.",
                icon: "sun.max.fill",
                accentColorHex: "#F59E0B",
                wallpaperIDs: chillWallpapers.isEmpty ? allItems.prefix(2).map { $0.id } : Array(chillWallpapers.prefix(3)),
                playbackMode: .randomCycle,
                cycleIntervalMinutes: 15,
                isMuted: false,
                linkedMode: .appearanceLight,
                isBuiltIn: true
            ),
            MoodProfile(
                name: "Cyber Lounge",
                description: "Neon futuristic loops and interactive dynamic visuals for music and gaming.",
                icon: "sparkles.tv",
                accentColorHex: "#EC4899",
                wallpaperIDs: vibrantWallpapers.isEmpty ? allItems.prefix(2).map { $0.id } : Array(vibrantWallpapers.prefix(4)),
                playbackMode: .randomCycle,
                cycleIntervalMinutes: 10,
                isMuted: false,
                linkedMode: .none,
                isBuiltIn: true
            )
        ]
    }
    
    // MARK: - Mood Management
    
    public func addMood(_ mood: MoodProfile) {
        moods.append(mood)
        saveMoods()
    }
    
    public func updateMood(_ mood: MoodProfile) {
        if let idx = moods.firstIndex(where: { $0.id == mood.id }) {
            moods[idx] = mood
            saveMoods()
            if activeMoodId == mood.id {
                activateMood(mood)
            }
        }
    }
    
    public func deleteMood(id: String) {
        moods.removeAll { $0.id == id }
        saveMoods()
        if activeMoodId == id {
            activeMoodId = nil
            UserDefaults.standard.removeObject(forKey: activeMoodKey)
            stopCycleTimer()
        }
    }
    
    public func duplicateMood(_ mood: MoodProfile) {
        var copy = mood
        let newId = UUID().uuidString
        copy = MoodProfile(
            id: newId,
            name: "\(mood.name) (Copy)",
            description: mood.description,
            icon: mood.icon,
            accentColorHex: mood.accentColorHex,
            wallpaperIDs: mood.wallpaperIDs,
            playbackMode: mood.playbackMode,
            cycleIntervalMinutes: mood.cycleIntervalMinutes,
            isMuted: mood.isMuted,
            linkedMode: .none,
            isBuiltIn: false
        )
        moods.append(copy)
        saveMoods()
    }
    
    public func activateMood(id: String) {
        guard let mood = moods.first(where: { $0.id == id }) else { return }
        activateMood(mood)
    }
    
    public func activateMood(_ mood: MoodProfile) {
        activeMoodId = mood.id
        UserDefaults.standard.set(mood.id, forKey: activeMoodKey)
        
        // Apply Audio mute preference if defined
        if let shouldMute = mood.isMuted {
            AppSettings.shared.isMuted = shouldMute
            WallpaperEngine.shared.updateAudioSettings(
                volume: AppSettings.shared.audioVolume,
                isMuted: shouldMute
            )
        }
        
        // Start wallpaper cycle or apply first wallpaper
        currentCycleIndex = 0
        applyCurrentMoodWallpaper(mood: mood)
        setupCycleTimer(for: mood)
    }
    
    private func applyCurrentMoodWallpaper(mood: MoodProfile) {
        guard !mood.wallpaperIDs.isEmpty else { return }
        let allWallpapers = WallpaperStorageManager.shared.wallpapers
        
        let targetWallpaper: WallpaperItem?
        switch mood.playbackMode {
        case .single:
            let firstId = mood.wallpaperIDs[0]
            targetWallpaper = allWallpapers.first(where: { $0.id == firstId })
        case .sequenceCycle:
            let safeIdx = currentCycleIndex % mood.wallpaperIDs.count
            let targetId = mood.wallpaperIDs[safeIdx]
            targetWallpaper = allWallpapers.first(where: { $0.id == targetId })
        case .randomCycle:
            let randomId = mood.wallpaperIDs.randomElement() ?? mood.wallpaperIDs[0]
            targetWallpaper = allWallpapers.first(where: { $0.id == randomId })
        }
        
        if let target = targetWallpaper {
            WallpaperStorageManager.shared.setActiveWallpaper(target)
        }
    }
    
    private func setupCycleTimer(for mood: MoodProfile) {
        stopCycleTimer()
        guard mood.playbackMode != .single && mood.wallpaperIDs.count > 1 else { return }
        
        let interval = max(30.0, mood.cycleIntervalMinutes * 60.0)
        cycleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self,
                  let currentMood = self.moods.first(where: { $0.id == self.activeMoodId }) else { return }
            self.currentCycleIndex += 1
            self.applyCurrentMoodWallpaper(mood: currentMood)
        }
    }
    
    private func stopCycleTimer() {
        cycleTimer?.invalidate()
        cycleTimer = nil
    }
    
    // MARK: - macOS System Observers & Auto-Sync
    
    private func setupSystemObservers() {
        let ws = NSWorkspace.shared.notificationCenter
        
        // 1. macOS Sleep / Wake
        ws.addObserver(self, selector: #selector(handleSystemSleep), name: NSWorkspace.willSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(handleScreensSleep), name: NSWorkspace.screensDidSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(handleSystemWake), name: NSWorkspace.didWakeNotification, object: nil)
        
        // 2. macOS Focus / Do Not Disturb Mode changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleFocusModeChange),
            name: NSNotification.Name("com.apple.focus.mode"),
            object: nil
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleFocusModeChange),
            name: NSNotification.Name("com.apple.notificationcenter.dndstatus"),
            object: nil
        )
        
        // 3. Dark / Light Mode switches
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleAppearanceChange),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }
    
    @objc private func handleSystemSleep() {
        guard isSyncEnabled else { return }
        triggerMatchingMood(for: .sleep, reason: "macOS entered Sleep mode")
    }
    
    @objc private func handleScreensSleep() {
        guard isSyncEnabled else { return }
        triggerMatchingMood(for: .sleep, reason: "macOS display sleep")
    }
    
    @objc private func handleSystemWake() {
        guard isSyncEnabled else { return }
        checkCurrentSystemState()
    }
    
    @objc private func handleFocusModeChange() {
        guard isSyncEnabled else { return }
        triggerMatchingMood(for: .doNotDisturb, reason: "Focus / DND mode activated")
    }
    
    @objc private func handleAppearanceChange() {
        guard isSyncEnabled else { return }
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let targetMode: LinkedMacOSMode = isDark ? .appearanceDark : .appearanceLight
        triggerMatchingMood(for: targetMode, reason: "System switched to \(isDark ? "Dark" : "Light") Mode")
    }
    
    public func checkCurrentSystemState() {
        guard isSyncEnabled else { return }
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        triggerMatchingMood(for: isDark ? .appearanceDark : .appearanceLight, reason: "Current system appearance")
    }
    
    private func triggerMatchingMood(for mode: LinkedMacOSMode, reason: String) {
        guard let matchingMood = moods.first(where: { $0.linkedMode == mode }) else { return }
        DispatchQueue.main.async {
            self.lastTriggeredReason = reason
            self.activateMood(matchingMood)
        }
    }
}
