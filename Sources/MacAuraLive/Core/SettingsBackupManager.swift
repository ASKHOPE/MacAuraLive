import Foundation
import AppKit

public struct AppSettingsSnapshot: Codable {
    public var appVersion: String
    public var exportDate: Date
    
    // Core Preferences
    public var launchAtLogin: Bool
    public var pauseOnBattery: Bool
    public var pauseOnFullScreen: Bool
    public var enableLockScreenWallpaper: Bool
    public var lockScreenWallpaperId: String
    public var lockScreenImagePath: String
    public var spanAcrossDisplays: Bool
    public var playbackRate: Float
    public var audioVolume: Double
    public var isMuted: Bool
    public var defaultAspectFill: Bool
    public var wallpaperPlacement: String
    public var wallpaperZoom: Double
    public var appTheme: String
    public var enableTransparency: Bool
    public var autoDayNightWallpapers: Bool
    
    // Model preferences (API keys omitted for security unless explicitly selected)
    public var claudeModel: String
    public var openAiModel: String
    public var openRouterModel: String
    
    // Custom Wallpaper Metadata Snapshot
    public var customWallpapers: [WallpaperItem]?
}

public class SettingsBackupManager: ObservableObject {
    public static let shared = SettingsBackupManager()
    
    @Published public var lastExportURL: URL? = nil
    @Published public var statusMessage: String? = nil
    @Published public var isSuccess: Bool = false
    
    public init() {}
    
    public func createSnapshot() -> AppSettingsSnapshot {
        let settings = AppSettings.shared
        let storage = WallpaperStorageManager.shared
        
        let customOnly = storage.wallpapers.filter { item in
            !storage.getBuiltInWallpapers().contains(where: { $0.id == item.id })
        }
        
        return AppSettingsSnapshot(
            appVersion: UpdateManager.shared.currentVersion,
            exportDate: Date(),
            launchAtLogin: settings.launchAtLogin,
            pauseOnBattery: settings.pauseOnBattery,
            pauseOnFullScreen: settings.pauseOnFullScreen,
            enableLockScreenWallpaper: settings.enableLockScreenWallpaper,
            lockScreenWallpaperId: settings.lockScreenWallpaperId,
            lockScreenImagePath: settings.lockScreenImagePath,
            spanAcrossDisplays: settings.spanAcrossDisplays,
            playbackRate: settings.playbackRate,
            audioVolume: settings.audioVolume,
            isMuted: settings.isMuted,
            defaultAspectFill: settings.defaultAspectFill,
            wallpaperPlacement: settings.wallpaperPlacement,
            wallpaperZoom: settings.wallpaperZoom,
            appTheme: settings.appTheme,
            enableTransparency: settings.enableTransparency,
            autoDayNightWallpapers: settings.autoDayNightWallpapers,
            claudeModel: settings.claudeModel,
            openAiModel: settings.openAiModel,
            openRouterModel: settings.openRouterModel,
            customWallpapers: customOnly
        )
    }
    
    public func exportSettings() {
        let snapshot = createSnapshot()
        guard let data = try? JSONEncoder().encode(snapshot) else {
            self.statusMessage = "Failed to encode settings to JSON."
            self.isSuccess = false
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateStr = formatter.string(from: Date())
        let defaultFilename = "MacAuraLive_Settings_Backup_\(dateStr).json"
        
        let savePanel = NSSavePanel()
        savePanel.title = "Export MacAuraLive Settings"
        savePanel.nameFieldStringValue = defaultFilename
        savePanel.allowedContentTypes = [.json]
        
        savePanel.begin { [weak self] response in
            guard let self = self else { return }
            if response == .OK, let targetURL = savePanel.url {
                do {
                    try data.write(to: targetURL)
                    DispatchQueue.main.async {
                        self.lastExportURL = targetURL
                        self.statusMessage = "Settings exported successfully to \(targetURL.lastPathComponent)."
                        self.isSuccess = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.statusMessage = "Export failed: \(error.localizedDescription)"
                        self.isSuccess = false
                    }
                }
            }
        }
    }
    
    public func importSettings() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Import MacAuraLive Settings"
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { [weak self] response in
            guard let self = self else { return }
            if response == .OK, let fileURL = openPanel.url {
                self.restoreFromURL(fileURL)
            }
        }
    }
    
    public func restoreFromURL(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let snapshot = try JSONDecoder().decode(AppSettingsSnapshot.self, from: data)
            
            let settings = AppSettings.shared
            
            // Restore preferences
            settings.pauseOnBattery = snapshot.pauseOnBattery
            settings.pauseOnFullScreen = snapshot.pauseOnFullScreen
            settings.enableLockScreenWallpaper = snapshot.enableLockScreenWallpaper
            settings.lockScreenWallpaperId = snapshot.lockScreenWallpaperId
            settings.lockScreenImagePath = snapshot.lockScreenImagePath
            settings.spanAcrossDisplays = snapshot.spanAcrossDisplays
            settings.playbackRate = snapshot.playbackRate
            settings.audioVolume = snapshot.audioVolume
            settings.isMuted = snapshot.isMuted
            settings.defaultAspectFill = snapshot.defaultAspectFill
            settings.wallpaperPlacement = snapshot.wallpaperPlacement
            settings.wallpaperZoom = snapshot.wallpaperZoom
            settings.appTheme = snapshot.appTheme
            settings.enableTransparency = snapshot.enableTransparency
            settings.autoDayNightWallpapers = snapshot.autoDayNightWallpapers
            settings.claudeModel = snapshot.claudeModel
            settings.openAiModel = snapshot.openAiModel
            settings.openRouterModel = snapshot.openRouterModel
            settings.launchAtLogin = snapshot.launchAtLogin
            
            settings.applyAppearanceTheme()
            
            // Restore custom wallpaper items if present
            if let customItems = snapshot.customWallpapers, !customItems.isEmpty {
                let storage = WallpaperStorageManager.shared
                let existingIds = Set(storage.wallpapers.map { $0.id })
                for item in customItems where !existingIds.contains(item.id) {
                    storage.wallpapers.append(item)
                }
                storage.saveCustomWallpapers()
            }
            
            WallpaperEngine.shared.reloadEngine()
            
            DispatchQueue.main.async {
                self.statusMessage = "Settings restored successfully from backup (\(snapshot.appVersion))."
                self.isSuccess = true
            }
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "Import failed: Invalid or corrupted JSON backup file."
                self.isSuccess = false
            }
        }
    }
}
