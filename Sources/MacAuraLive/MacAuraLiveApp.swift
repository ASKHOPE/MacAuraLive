import SwiftUI
import AppKit

@main
struct MacAuraLiveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboardingSheet: Bool = false
    
    var body: some Scene {
        WindowGroup("MacAuraLive Live Wallpaper Dashboard") {
            MainWindowView()
                .frame(width: 1250, height: 950)
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
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About MacAuraLive") {
                    appDelegate.showAboutPanel()
                }
            }
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
        // No-op to prevent recursive layout update loops
    }
}

public class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    private(set) var mainWindow: NSWindow?
    
    public func registerMainWindow(_ window: NSWindow) {
        self.mainWindow = window
        window.delegate = self
        window.isOpaque = true
        window.backgroundColor = NSColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1.0)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.styleMask.remove(.resizable)
        window.showsResizeIndicator = false
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.minSize = NSSize(width: 1250, height: 950)
        window.maxSize = NSSize(width: 1250, height: 950)
        window.setContentSize(NSSize(width: 1250, height: 950))
        window.center()
    }

    /// Intercept red close button click on the main window: hide window instead of destroying it
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        // Drop back to accessory (no Dock icon) once the dashboard is hidden
        NSApp.setActivationPolicy(.accessory)
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
            (app.bundleIdentifier == bundleID || app.localizedName == "MacAuraLive")
        }
        
        if let existingApp = otherInstances.first {
            print("[MacAuraLive] Existing instance detected (PID \(existingApp.processIdentifier)). Activating existing app and exiting.")
            existingApp.activate(options: [.activateIgnoringOtherApps])
            exit(0)
        }
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as a menu-bar app — hide from Dock while running.
        // The dashboard window will temporarily promote to .regular so it
        // appears in Cmd+Tab, then we drop back to .accessory on close.
        NSApp.setActivationPolicy(.accessory)
        
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
                button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "MacAuraLive Live Wallpaper")
            }
            button.toolTip = "MacAuraLive Live Wallpaper"
        }
        
        let menu = NSMenu()
        menu.delegate = self
        
        let titleItem = NSMenuItem(title: "MacAuraLive Live Wallpaper", action: nil, keyEquivalent: "")
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
        
        let aboutItem = NSMenuItem(title: "About MacAuraLive...", action: #selector(showAboutPanel), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
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
        
        let quitItem = NSMenuItem(title: "Quit MacAuraLive", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        self.statusItem = statusItem
    }
    
    @objc public func showAboutPanel() {
        let credits = NSMutableAttributedString()
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: NSColor.labelColor
        ]
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        credits.append(NSAttributedString(string: "MacAuraLive — Native Live Wallpaper Engine\n\n", attributes: boldAttributes))
        credits.append(NSAttributedString(string: "Architecture: Universal 2 (Apple Silicon M1/M2/M3/M4 & Intel x86_64)\nGraphics Engine: Apple Metal 3 & WebKit WebGL (60 FPS VSync)\nMedia Pipeline: AVFoundation Hardware 4K Video Decoder\nStorage: Local Archive (~/Library/Application Support/MacAuraLive/Media)\nSecurity: Hardware Keychain Secure Enclave • Zero Telemetry\n\nCreated by ASKHOPE • Distributed under the MIT License.\nhttps://askhope.github.io/MacAuraLive/\n", attributes: regularAttributes))
        
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: "MacAuraLive",
            .applicationVersion: "v\(AppVersion.current.version)",
            .version: "Universal 2 (Apple Silicon M1-M4 & Intel)",
            .credits: credits
        ]
        
        NSApp.orderFrontStandardAboutPanel(options: options)
        NSApp.activate(ignoringOtherApps: true)
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
        // Promote to regular app so the window appears in Cmd+Tab switcher
        NSApp.setActivationPolicy(.regular)
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
