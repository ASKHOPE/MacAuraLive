import Foundation
import Combine
import ServiceManagement
import AppKit

public class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    @Published public var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin(enabled: launchAtLogin)
        }
    }
    
    /// Human-readable registration status for the Settings UI
    @Published public var launchAtLoginStatus: String = "Checking..."
    @Published public var launchAtLoginError: String? = nil
    
    @Published public var pauseOnBattery: Bool {
        didSet { UserDefaults.standard.set(pauseOnBattery, forKey: "pauseOnBattery") }
    }
    
    @Published public var pauseOnFullScreen: Bool {
        didSet { UserDefaults.standard.set(pauseOnFullScreen, forKey: "pauseOnFullScreen") }
    }
    
    @Published public var enableLockScreenWallpaper: Bool {
        didSet { UserDefaults.standard.set(enableLockScreenWallpaper, forKey: "enableLockScreenWallpaper") }
    }
    
    @Published public var lockScreenWallpaperId: String {
        didSet { UserDefaults.standard.set(lockScreenWallpaperId, forKey: "lockScreenWallpaperId") }
    }
    
    /// Persisted absolute file path of the last successfully applied lock screen image
    @Published public var lockScreenImagePath: String {
        didSet { UserDefaults.standard.set(lockScreenImagePath, forKey: "lockScreenImagePath") }
    }
    
    @Published public var spanAcrossDisplays: Bool {
        didSet { UserDefaults.standard.set(spanAcrossDisplays, forKey: "spanAcrossDisplays") }
    }
    
    @Published public var playbackRate: Float {
        didSet { UserDefaults.standard.set(playbackRate, forKey: "playbackRate") }
    }
    
    @Published public var audioVolume: Double {
        didSet { UserDefaults.standard.set(audioVolume, forKey: "audioVolume") }
    }
    
    @Published public var isMuted: Bool {
        didSet { UserDefaults.standard.set(isMuted, forKey: "isMuted") }
    }
    
    @Published public var defaultAspectFill: Bool {
        didSet { UserDefaults.standard.set(defaultAspectFill, forKey: "defaultAspectFill") }
    }
    
    @Published public var wallpaperPlacement: String { // "fill", "fit", "stretch", "center", "zoom"
        didSet { UserDefaults.standard.set(wallpaperPlacement, forKey: "wallpaperPlacement") }
    }
    
    @Published public var wallpaperZoom: Double { // 0.5 to 2.5
        didSet { UserDefaults.standard.set(wallpaperZoom, forKey: "wallpaperZoom") }
    }
    
    @Published public var isAdminUnlocked: Bool {
        didSet { UserDefaults.standard.set(isAdminUnlocked, forKey: "isAdminUnlocked") }
    }
    
    // Theme & Appearance Settings (macOS Native Following, Transparency & Day/Night Theming)
    @Published public var appTheme: String { // "system", "dark", "light"
        didSet {
            UserDefaults.standard.set(appTheme, forKey: "appTheme")
            applyAppearanceTheme()
        }
    }
    
    @Published public var enableTransparency: Bool {
        didSet { UserDefaults.standard.set(enableTransparency, forKey: "enableTransparency") }
    }
    
    @Published public var autoDayNightWallpapers: Bool {
        didSet { UserDefaults.standard.set(autoDayNightWallpapers, forKey: "autoDayNightWallpapers") }
    }
    
    // AI API Keys & Configurations (Secured via macOS Keychain)
    @Published public var claudeApiKey: String {
        didSet { KeychainManager.shared.saveKey(claudeApiKey, forAccount: "claudeApiKey") }
    }
    
    @Published public var claudeModel: String {
        didSet { UserDefaults.standard.set(claudeModel, forKey: "claudeModel") }
    }
    
    @Published public var openAiApiKey: String {
        didSet { KeychainManager.shared.saveKey(openAiApiKey, forAccount: "openAiApiKey") }
    }
    
    @Published public var openAiModel: String {
        didSet { UserDefaults.standard.set(openAiModel, forKey: "openAiModel") }
    }
    
    @Published public var geminiApiKey: String {
        didSet { KeychainManager.shared.saveKey(geminiApiKey, forAccount: "geminiApiKey") }
    }
    
    @Published public var openRouterApiKey: String {
        didSet { KeychainManager.shared.saveKey(openRouterApiKey, forAccount: "openRouterApiKey") }
    }
    
    @Published public var openRouterModel: String {
        didSet { UserDefaults.standard.set(openRouterModel, forKey: "openRouterModel") }
    }
    
    @Published public var localApiEndpoint: String {
        didSet { UserDefaults.standard.set(localApiEndpoint, forKey: "localApiEndpoint") }
    }
    
    @Published public var selectedAIProvider: String {
        didSet { UserDefaults.standard.set(selectedAIProvider, forKey: "selectedAIProvider") }
    }
    
    // Marketplace & Content Provider API Keys (Secured via macOS Keychain)
    @Published public var unsplashApiKey: String {
        didSet { KeychainManager.shared.saveKey(unsplashApiKey, forAccount: "unsplashApiKey") }
    }
    
    @Published public var pixabayApiKey: String {
        didSet { KeychainManager.shared.saveKey(pixabayApiKey, forAccount: "pixabayApiKey") }
    }
    
    @Published public var pexelsApiKey: String {
        didSet { KeychainManager.shared.saveKey(pexelsApiKey, forAccount: "pexelsApiKey") }
    }
    
    @Published public var enableMarketplacePlugins: Bool {
        didSet { UserDefaults.standard.set(enableMarketplacePlugins, forKey: "enableMarketplacePlugins") }
    }
    
    private init() {
        let defaults = UserDefaults.standard
        if #available(macOS 13.0, *) {
            self.launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        }
        self.pauseOnBattery = defaults.object(forKey: "pauseOnBattery") as? Bool ?? true
        self.pauseOnFullScreen = defaults.object(forKey: "pauseOnFullScreen") as? Bool ?? true
        self.enableLockScreenWallpaper = defaults.object(forKey: "enableLockScreenWallpaper") as? Bool ?? true
        self.lockScreenWallpaperId = defaults.string(forKey: "lockScreenWallpaperId") ?? "aurora"
        self.lockScreenImagePath = defaults.string(forKey: "lockScreenImagePath") ?? ""
        self.spanAcrossDisplays = defaults.object(forKey: "spanAcrossDisplays") as? Bool ?? false
        self.playbackRate = defaults.object(forKey: "playbackRate") as? Float ?? 1.0
        self.audioVolume = defaults.object(forKey: "audioVolume") as? Double ?? 0.8
        self.isMuted = defaults.object(forKey: "isMuted") as? Bool ?? true
        self.defaultAspectFill = defaults.object(forKey: "defaultAspectFill") as? Bool ?? true
        self.wallpaperPlacement = defaults.string(forKey: "wallpaperPlacement") ?? "stretch"
        self.wallpaperZoom = defaults.object(forKey: "wallpaperZoom") as? Double ?? 1.0
        self.isAdminUnlocked = defaults.bool(forKey: "isAdminUnlocked")
        
        // Theme & Appearance
        self.appTheme = defaults.string(forKey: "appTheme") ?? "system"
        self.enableTransparency = defaults.object(forKey: "enableTransparency") as? Bool ?? true
        self.autoDayNightWallpapers = defaults.object(forKey: "autoDayNightWallpapers") as? Bool ?? true
        
        // Retrieve credentials securely from macOS Keychain
        self.claudeApiKey = KeychainManager.shared.getKey(forAccount: "claudeApiKey")
        self.claudeModel = defaults.string(forKey: "claudeModel") ?? "claude-3-5-sonnet-20241022"
        self.openAiApiKey = KeychainManager.shared.getKey(forAccount: "openAiApiKey")
        self.openAiModel = defaults.string(forKey: "openAiModel") ?? "gpt-4o-mini"
        self.geminiApiKey = KeychainManager.shared.getKey(forAccount: "geminiApiKey")
        self.openRouterApiKey = KeychainManager.shared.getKey(forAccount: "openRouterApiKey")
        self.openRouterModel = defaults.string(forKey: "openRouterModel") ?? "google/gemma-2-9b-it:free"
        self.localApiEndpoint = defaults.string(forKey: "localApiEndpoint") ?? "http://localhost:11434/v1"
        self.selectedAIProvider = defaults.string(forKey: "selectedAIProvider") ?? "OpenRouter"
        
        // Marketplace Credentials from Keychain
        self.unsplashApiKey = KeychainManager.shared.getKey(forAccount: "unsplashApiKey")
        self.pixabayApiKey = KeychainManager.shared.getKey(forAccount: "pixabayApiKey")
        self.pexelsApiKey = KeychainManager.shared.getKey(forAccount: "pexelsApiKey")
        self.enableMarketplacePlugins = defaults.object(forKey: "enableMarketplacePlugins") as? Bool ?? true
        
        // Populate status and apply theme immediately
        DispatchQueue.main.async {
            self.refreshLaunchAtLoginStatus()
            self.applyAppearanceTheme()
            self.setupSystemAppearanceListener()
        }
    }
    
    public func applyAppearanceTheme() {
        DispatchQueue.main.async {
            switch self.appTheme {
            case "dark":
                NSApp.appearance = NSAppearance(named: .darkAqua)
            case "light":
                NSApp.appearance = NSAppearance(named: .aqua)
            default:
                NSApp.appearance = nil // Follow macOS native
            }
        }
    }
    
    private func setupSystemAppearanceListener() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemAppearanceChange()
        }
    }
    
    private func handleSystemAppearanceChange() {
        guard autoDayNightWallpapers else { return }
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        print("[AppSettings] macOS Appearance changed. Dark mode active: \(isDarkMode)")
        WallpaperStorageManager.shared.adaptWallpaperForDayNight(isDarkMode: isDarkMode)
    }
    
    private func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                DispatchQueue.main.async { self.refreshLaunchAtLoginStatus() }
                launchAtLoginError = nil
            } catch {
                print("[AppSettings] Launch at login error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.launchAtLoginError = error.localizedDescription
                    self.refreshLaunchAtLoginStatus()
                }
            }
        }
    }
    
    public func refreshLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            switch SMAppService.mainApp.status {
            case .enabled:
                launchAtLoginStatus = "Active"
            case .requiresApproval:
                launchAtLoginStatus = "Requires Approval"
            case .notRegistered:
                launchAtLoginStatus = "Not Registered"
            case .notFound:
                launchAtLoginStatus = "Not Found — Move app to /Applications"
            @unknown default:
                launchAtLoginStatus = "Unknown"
            }
        } else {
            launchAtLoginStatus = launchAtLogin ? "Active (Legacy)" : "Off"
        }
    }
}
