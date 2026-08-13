import SwiftUI
import AppKit

@main
struct MacAuraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboardingSheet: Bool = false
    
    var body: some Scene {
        WindowGroup("MacAura Live Wallpaper Dashboard") {
            MainWindowView()
                .background(WindowAccessor { window in
                    appDelegate.registerMainWindow(window)
                })
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                    if !hasCompletedOnboarding {
                        showOnboardingSheet = true
                    }
                }
                .sheet(isPresented: $showOnboardingSheet) {
                    OnboardingView(isPresented: $showOnboardingSheet)
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

/// Helper to get a direct reference to the parent NSWindow
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                callback(window)
            }
        }
    }
}

public class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    private(set) var mainWindow: NSWindow?
    
    public func registerMainWindow(_ window: NSWindow) {
        self.mainWindow = window
        window.delegate = self
    }

    /// Intercept red close button click on the main window: hide window instead of destroying it
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false // Intercept destruction
    }

    public func applicationWillFinishLaunching(_ notification: Notification) {
        enforceSingleInstance()
    }
    
    private func enforceSingleInstance() {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let bundleID = Bundle.main.bundleIdentifier ?? "com.macaura.app"
        
        // Find other running instances by bundle ID or process name
        let runningApps = NSWorkspace.shared.runningApplications
        let otherInstances = runningApps.filter { app in
            app.processIdentifier != currentPID &&
            (app.bundleIdentifier == bundleID || app.localizedName == "MacAura")
        }
        
        if let existingApp = otherInstances.first {
            print("[MacAura] Existing instance detected (PID \(existingApp.processIdentifier)). Activating existing app and exiting.")
            existingApp.activate(options: [.activateIgnoringOtherApps])
            exit(0)
        }
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Wallpaper Engine
        WallpaperEngine.shared.startEngine()
        
        // Refresh SMAppService status badge immediately
        AppSettings.shared.refreshLaunchAtLoginStatus()
        
        // Setup Status Bar Menu
        setupStatusBar()
        
        // Set app icon
        applyAppIcon()
    }
    
    private func applyAppIcon() {
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let icon = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = icon
        }
    }
    
    private func setupStatusBar() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            // Load StatusBarIcon.png from bundle Resources root
            if let customIconPath = Bundle.main.path(forResource: "StatusBarIcon", ofType: "png"),
               let image = NSImage(contentsOfFile: customIconPath) {
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = false
                button.image = image
            } else {
                button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "MacAura Live Wallpaper")
            }
        }
        
        let menu = NSMenu()
        menu.delegate = self
        
        let titleItem = NSMenuItem(title: "MacAura Live Wallpaper", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let playPauseItem = NSMenuItem(title: "Pause Wallpaper", action: #selector(togglePlayPause), keyEquivalent: "")
        playPauseItem.target = self
        menu.addItem(playPauseItem)
        
        let muteItem = NSMenuItem(title: "Mute Audio", action: #selector(toggleMute), keyEquivalent: "")
        muteItem.target = self
        menu.addItem(muteItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let openDashboardItem = NSMenuItem(title: "Open Dashboard...", action: #selector(openDashboard), keyEquivalent: "d")
        openDashboardItem.target = self
        menu.addItem(openDashboardItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Launch at Login quick toggle
        let loginTitle = AppSettings.shared.launchAtLogin ? "✓ Launch at Login" : "Launch at Login"
        let launchAtLoginItem = NSMenuItem(
            title: loginTitle,
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit MacAura", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        self.statusItem = statusItem
    }
    
    public func menuWillOpen(_ menu: NSMenu) {
        let activeItem = WallpaperStorageManager.shared.getActiveWallpaper()
        let isStatic = activeItem?.type == .image || (activeItem?.category == "Static" && activeItem?.type != .builtInWeb && activeItem?.type != .video)
        let wallpaperHasAudio = activeItem?.hasAudio == true || activeItem?.type == .video
        
        let isPaused = WallpaperEngine.shared.isPaused
        let isMuted = AppSettings.shared.isMuted
        let isLaunchAtLogin = AppSettings.shared.launchAtLogin
        
        if menu.items.count > 3 {
            // Playback item (index 2)
            if isStatic {
                menu.items[2].title = "Static Wallpaper Active"
                menu.items[2].isEnabled = false
            } else {
                menu.items[2].title = isPaused ? "Resume Wallpaper" : "Pause Wallpaper"
                menu.items[2].isEnabled = true
            }
            
            // Mute item (index 3)
            menu.items[3].title = isMuted ? "Unmute Audio" : "Mute Audio"
            menu.items[3].isHidden = !wallpaperHasAudio
            
            // Launch at Login item — find by action
            if let loginItem = menu.items.first(where: { $0.action == #selector(toggleLaunchAtLogin) }) {
                loginItem.title = isLaunchAtLogin ? "✓ Launch at Login" : "Launch at Login"
                loginItem.image = NSImage(systemSymbolName: isLaunchAtLogin ? "checkmark.circle.fill" : "circle", accessibilityDescription: nil)
            }
        }
    }
    
    @objc private func togglePlayPause() {
        WallpaperEngine.shared.togglePlayPause()
    }
    
    @objc private func toggleMute() {
        AppSettings.shared.isMuted.toggle()
        WallpaperEngine.shared.updateAudioSettings(volume: AppSettings.shared.audioVolume, isMuted: AppSettings.shared.isMuted)
    }
    
    @objc private func toggleLaunchAtLogin() {
        AppSettings.shared.launchAtLogin.toggle()
    }
    
    @objc public func openDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        
        let targetWindow = mainWindow ?? NSApp.windows.first(where: { !($0 is NSPanel) && $0.canBecomeMain })
        
        if let window = targetWindow {
            if window.delegate == nil {
                window.delegate = self
            }
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.setIsVisible(true)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running in background when main window is closed
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openDashboard()
        return true
    }
    
    /// Native macOS Dock right-click context menu items
    public func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let dockMenu = NSMenu()
        
        let openItem = NSMenuItem(
            title: "Open Dashboard...",
            action: #selector(openDashboard),
            keyEquivalent: ""
        )
        openItem.target = self
        dockMenu.addItem(openItem)
        
        dockMenu.addItem(NSMenuItem.separator())
        
        let playPauseItem = NSMenuItem(
            title: WallpaperEngine.shared.isPaused ? "Resume Wallpaper" : "Pause Wallpaper",
            action: #selector(togglePlayPause),
            keyEquivalent: ""
        )
        playPauseItem.target = self
        dockMenu.addItem(playPauseItem)
        
        return dockMenu
    }
}
