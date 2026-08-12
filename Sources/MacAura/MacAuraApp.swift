import SwiftUI
import AppKit

@main
struct MacAuraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup("MacAura Live Wallpaper Dashboard") {
            MainWindowView()
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

public class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    
    /// true = visible in Dock (default), false = menu bar only
    private var isDockVisible: Bool {
        get { UserDefaults.standard.object(forKey: "isDockVisible") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isDockVisible") }
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Wallpaper Engine
        WallpaperEngine.shared.startEngine()
        
        // Restore dock visibility preference FIRST (before icon, since policy change can clear it)
        applyDockVisibility(isDockVisible)
        
        // Setup Status Bar Menu
        setupStatusBar()
        
        // Set app icon — do it after a short delay so it sticks after activation policy is applied
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.applyAppIcon()
        }
    }
    
    private func applyAppIcon() {
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let icon = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = icon
        }
    }
    
    private func applyDockVisibility(_ visible: Bool) {
        if visible {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
        // Re-apply icon after policy change since macOS may reset it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.applyAppIcon()
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
        
        // Dock visibility toggle
        let dockTitle = isDockVisible ? "Remove from Dock" : "Keep in Dock"
        let dockItem = NSMenuItem(title: dockTitle, action: #selector(toggleDockVisibility), keyEquivalent: "")
        dockItem.target = self
        menu.addItem(dockItem)
        
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
            
            // Dock visibility item — find it by action
            if let dockItem = menu.items.first(where: { $0.action == #selector(toggleDockVisibility) }) {
                dockItem.title = isDockVisible ? "Remove from Dock" : "Keep in Dock"
                dockItem.image = NSImage(systemSymbolName: isDockVisible ? "dock.rectangle.badge.minus" : "dock.rectangle", accessibilityDescription: nil)
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
    
    @objc private func openDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title.contains("MacAura") }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func toggleDockVisibility() {
        isDockVisible.toggle()
        applyDockVisibility(isDockVisible)
        // Refresh menu label immediately
        if let dockItem = statusItem?.menu?.items.first(where: { $0.action == #selector(toggleDockVisibility) }) {
            dockItem.title = isDockVisible ? "Remove from Dock" : "Keep in Dock"
            dockItem.image = NSImage(systemSymbolName: isDockVisible ? "dock.rectangle.badge.minus" : "dock.rectangle", accessibilityDescription: nil)
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
    
    // Adds custom items to the Dock right-click context menu
    public func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let dockMenu = NSMenu()
        
        let dockToggleItem = NSMenuItem(
            title: isDockVisible ? "Remove from Dock" : "Keep in Dock",
            action: #selector(toggleDockVisibility),
            keyEquivalent: ""
        )
        dockToggleItem.target = self
        dockToggleItem.image = NSImage(
            systemSymbolName: isDockVisible ? "dock.rectangle.badge.minus" : "dock.rectangle",
            accessibilityDescription: nil
        )
        dockMenu.addItem(dockToggleItem)
        
        dockMenu.addItem(NSMenuItem.separator())
        
        let playPauseDockItem = NSMenuItem(
            title: WallpaperEngine.shared.isPaused ? "Resume Wallpaper" : "Pause Wallpaper",
            action: #selector(togglePlayPause),
            keyEquivalent: ""
        )
        playPauseDockItem.target = self
        dockMenu.addItem(playPauseDockItem)
        
        return dockMenu
    }
}
