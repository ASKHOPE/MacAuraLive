import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case liveWallpapers = "Live Wallpapers"
    case staticWallpapers = "Static Wallpapers"
    case moods = "Moods & Presets"
    case marketplace = "Marketplace"
    case slideshow = "Slideshow & Schedule"
    case displays = "Displays"
    case lockScreen = "Lock Screen"
    case userGuide = "User Guide"
    case aiConfig = "AI Workshop"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .liveWallpapers: return "play.rectangle.fill"
        case .staticWallpapers: return "photo.fill"
        case .moods: return "sparkles.rectangle.stack"
        case .marketplace: return "globe.americas.fill"
        case .slideshow: return "clock.arrow.2.circlepath"
        case .displays: return "desktopcomputer"
        case .lockScreen: return "lock.rectangle.on.rectangle.fill"
        case .userGuide: return "book.closed.fill"
        case .aiConfig: return "sparkles.tv"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct MainWindowView: View {
    @State private var selectedTab: NavigationTab = .liveWallpapers
    @ObservedObject var engine = WallpaperEngine.shared
    @ObservedObject var storage = WallpaperStorageManager.shared
    @ObservedObject var settings = AppSettings.shared

    public init() {}

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0 else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - Persistent Left Sidebar
            VStack(alignment: .leading, spacing: 14) {
                // Header Logo
                HStack(spacing: 12) {
                    if let appIcon = NSImage.appLogo {
                        Image(nsImage: appIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 38, height: 38)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: settings.appTheme == "classic" ? 4 : 10)
                                .fill(settings.appTheme == "classic" ? MacaThemeTokens.classicOlive : Color.blue)
                                .frame(width: 38, height: 38)
                            Image(systemName: "sparkles")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("MacAuraLive")
                            .font(.system(size: settings.appTheme == "classic" ? 17 : 18, weight: .bold, design: settings.appTheme == "classic" ? .monospaced : .default))
                            .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextDark : .primary)
                        Text(settings.appTheme == "classic" ? "v\(AppVersion.current.version) • OS Classic" : "Live Wallpaper Engine")
                            .font(.system(size: 10, weight: .medium, design: settings.appTheme == "classic" ? .monospaced : .default))
                            .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextMuted : .secondary)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 40)
                
                Divider()
                    .padding(.vertical, 4)
                
                // Custom Sidebar Navigation List (Themed & Grouped)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        sidebarSection(
                            title: "LIBRARY & DISCOVER",
                            tabs: [.liveWallpapers, .staticWallpapers, .moods, .marketplace]
                        )
                        
                        sidebarSection(
                            title: "DISPLAYS & SCHEDULING",
                            tabs: [.slideshow, .displays, .lockScreen]
                        )
                        
                        sidebarSection(
                            title: "CREATIVE STUDIO",
                            tabs: [.aiConfig]
                        )
                        
                        sidebarSection(
                            title: "SYSTEM & SUPPORT",
                            tabs: [.userGuide, .settings]
                        )
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: .infinity)
                
                // Active Engine & Playback Controller Card (always visible in sidebar)
                let activeItem = storage.getActiveWallpaper()
                let isStatic = activeItem == nil || activeItem?.type == .image || activeItem?.category == "Static"
                let isVideo = activeItem?.type == .video
                let isClassic = settings.appTheme == "classic"
                
                if let item = activeItem {
                    VStack(alignment: .leading, spacing: 10) {
                        // Header Status
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(isStatic ? "Active Static Backdrop" : (engine.isPaused ? "Playback Paused" : "Engine Playing"))
                                    .font(.system(size: 10, weight: .bold, design: isClassic ? .monospaced : .default))
                                    .foregroundColor(!isStatic && engine.isPaused ? .orange : (isStatic ? .blue : .green))
                                Spacer()
                                 if !isStatic {
                                    Button(action: { engine.togglePlayPause() }) {
                                        Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                                            .font(.caption2)
                                            .padding(6)
                                            .background(Color(NSColor.quaternaryLabelColor).opacity(0.2))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            Text(item.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        
                        // Interactive Video Playback Slider Widget
                        if isVideo, engine.playbackDuration > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "film")
                                        .font(.caption2)
                                        .foregroundColor(.cyan)
                                    Text("Seek:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(formatTime(engine.playbackCurrentTime)) / \(formatTime(engine.playbackDuration))")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.cyan)
                                        .frame(width: 85, alignment: .trailing)
                                }
                                
                                MacaRetroSlider(
                                    value: Binding(
                                        get: { engine.playbackCurrentTime },
                                        set: { newValue in
                                            engine.seekToPosition(seconds: newValue)
                                        }
                                    ),
                                    in: 0...max(0.1, engine.playbackDuration),
                                    accentColor: .cyan
                                )
                                .frame(height: 18)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 2)
                        
                        // Playback Speed & Audio Volume Controls (ALWAYS visible in sidebar bottom)
                        VStack(alignment: .leading, spacing: 8) {
                            // Playback Speed Slider Widget
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text("Speed:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.2fx", settings.playbackRate))
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.orange)
                                        .frame(width: 48, alignment: .trailing)
                                }
                                
                                MacaRetroSlider(
                                    value: Binding(
                                        get: { Double(settings.playbackRate) },
                                        set: { newVal in
                                            let rate = Float(newVal)
                                            settings.playbackRate = rate
                                            engine.updatePlaybackRate(rate)
                                        }
                                    ),
                                    in: 0.25...3.0,
                                    step: 0.25,
                                    accentColor: .orange,
                                    showTicks: true,
                                    tickCount: 8
                                )
                                .frame(height: 24)
                            }
                            
                            HStack {
                                Button(action: {
                                    settings.isMuted.toggle()
                                    engine.updateAudioSettings(volume: settings.audioVolume, isMuted: settings.isMuted)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: settings.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                            .font(.caption)
                                        Text(settings.isMuted ? "Unmute" : "Mute")
                                            .font(.system(size: 11, weight: .bold, design: isClassic ? .monospaced : .default))
                                    }
                                }
                                .macaButtonStyle(settings.isMuted ? .destructive : .secondary, size: .small)
                                
                                Spacer()
                                
                                Text(settings.isMuted ? "MUTED" : "\(Int(settings.audioVolume * 100))%")
                                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(settings.isMuted ? .red : (isClassic ? MacaThemeTokens.classicTextDark : .primary))
                                    .frame(width: 52, alignment: .trailing)
                            }
                            
                            MacaRetroSlider(
                                value: Binding(
                                    get: { settings.audioVolume },
                                    set: { newValue in
                                        settings.audioVolume = newValue
                                        engine.updateAudioSettings(volume: newValue, isMuted: settings.isMuted)
                                    }
                                ),
                                in: 0.0...1.0,
                                accentColor: isClassic ? MacaThemeTokens.classicOlive : Color.blue
                            )
                            .frame(height: 18)
                            .opacity(settings.isMuted ? 0.4 : 1.0)
                            .disabled(settings.isMuted)
                        }
                    }
                    .padding(12)
                    .macaCardStyle(cornerRadius: 14)
                    .padding(.horizontal, 12)
                }
                
                // Retro Import Action Button & Live Engine Status Bar
                VStack(spacing: 8) {
                    Button(action: { openQuickFilePicker() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.doc")
                                .font(.system(size: 12, weight: .bold))
                            Text("Import File")
                                .font(.system(size: 12.5, weight: .semibold, design: settings.appTheme == "classic" ? .monospaced : .default))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(settings.appTheme == "classic" ? Color.white : Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(settings.appTheme == "classic" ? MacaThemeTokens.classicBorder : Color(NSColor.separatorColor), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(!engine.isPaused ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                        Text(engine.isPaused ? "Engine Paused" : "Engine Online")
                            .font(.system(size: 10.5, weight: .medium, design: settings.appTheme == "classic" ? .monospaced : .default))
                            .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextMuted : .secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
            .frame(width: 265)
            .layoutPriority(1)
            .background(
                Group {
                    if settings.appTheme == "classic" {
                        MacaThemeTokens.classicSidebar
                    } else if settings.enableTransparency {
                        VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow)
                    } else {
                        Color(NSColor.controlBackgroundColor)
                    }
                }
            )
            
            Divider()
            
            // MARK: - Right Detail Content Area
            Group {
                switch selectedTab {
                case .liveWallpapers:
                    GalleryView(filterType: .liveOnly)
                case .staticWallpapers:
                    GalleryView(filterType: .staticOnly)
                case .moods:
                    MoodSelectorView()
                case .marketplace:
                    MarketplaceView()
                case .slideshow:
                    SlideshowView()
                case .displays:
                    DisplayManagerView()
                case .lockScreen:
                    LockScreenView()
                case .userGuide:
                    UserGuideView()
                case .aiConfig:
                    AIConfigurationView()
                case .settings:
                    SettingsView()
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 28)
            .padding(.top, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(0)
            .background(
                Group {
                    if settings.appTheme == "classic" {
                        MacaThemeTokens.classicCanvas
                    } else if settings.enableTransparency {
                        VisualEffectBlur(material: .underWindowBackground, blendingMode: .behindWindow)
                    } else {
                        Color(nsColor: .windowBackgroundColor)
                    }
                }
            )
        }
        .frame(width: 1250, height: 950)
        .ignoresSafeArea()
        .id(settings.appTheme)
        .preferredColorScheme(
            settings.appTheme == "dark" ? .dark : (settings.appTheme == "light" || settings.appTheme == "classic" ? .light : nil)
        )
        .onAppear {
            if CommandLine.arguments.contains("--capture-screenshots") {
                exportAllScreenshots()
            }
        }
    }
    
    private func exportAllScreenshots() {
        let baseDir = "/Users/hosanna/Documents/wallpapermacs/Documentation/Screenshots"
        let classicDir = "\(baseDir)/classic"
        let darkDir = "\(baseDir)/dark"
        let lightDir = "\(baseDir)/light"
        let webDir = "/Users/hosanna/Documents/wallpapermacs/docs/assets/screenshots"
        
        try? FileManager.default.createDirectory(atPath: baseDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: classicDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: darkDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: lightDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: webDir, withIntermediateDirectories: true)
        
        let tabMap: [(NavigationTab, String)] = [
            (.liveWallpapers, "01_live_wallpapers.png"),
            (.staticWallpapers, "02_static_wallpapers.png"),
            (.moods, "03_moods_presets.png"),
            (.slideshow, "04_slideshow_schedule.png"),
            (.displays, "05_displays.png"),
            (.lockScreen, "06_lock_screen.png"),
            (.userGuide, "07_user_guide.png"),
            (.aiConfig, "08_ai_workshop.png"),
            (.settings, "09_settings.png"),
            (.marketplace, "10_marketplace.png")
        ]
        
        func captureCurrent(targetDir: String, filename: String, prefixMsg: String) {
            if let window = NSApp.windows.first(where: { $0.isVisible }) {
                window.makeKeyAndOrderFront(nil)
                if let cgImage = CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(window.windowNumber), [.boundsIgnoreFraming, .bestResolution]) {
                    let bitmap = NSBitmapImageRep(cgImage: cgImage)
                    if let pngData = bitmap.representation(using: .png, properties: [:]) {
                        try? pngData.write(to: URL(fileURLWithPath: "\(targetDir)/\(filename)"))
                        try? pngData.write(to: URL(fileURLWithPath: "\(webDir)/\(targetDir.components(separatedBy: "/").last ?? "")_\(filename)"))
                        print("[ScreenshotAutomation] \(prefixMsg) exported to \(targetDir)/\(filename)")
                    }
                }
            }
        }
        
        // Phase 1: Capture Classic OS Theme
        self.settings.appTheme = "classic"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            for (idx, (tab, filename)) in tabMap.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.7) {
                    self.selectedTab = tab
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        captureCurrent(targetDir: classicDir, filename: filename, prefixMsg: "🕹️ Classic '\(tab.rawValue)'")
                        // Also write to baseDir as default showcase
                        if let window = NSApp.windows.first(where: { $0.isVisible }),
                           let cgImage = CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(window.windowNumber), [.boundsIgnoreFraming, .bestResolution]) {
                            let bitmap = NSBitmapImageRep(cgImage: cgImage)
                            if let pngData = bitmap.representation(using: .png, properties: [:]) {
                                try? pngData.write(to: URL(fileURLWithPath: "\(baseDir)/\(filename)"))
                            }
                        }
                    }
                }
            }
            
            // Phase 2: Capture Dark Theme
            let phase2Start = Double(tabMap.count) * 0.7 + 1.2
            DispatchQueue.main.asyncAfter(deadline: .now() + phase2Start) {
                self.settings.appTheme = "dark"
                
                for (idx, (tab, filename)) in tabMap.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.7) {
                        self.selectedTab = tab
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            captureCurrent(targetDir: darkDir, filename: filename, prefixMsg: "🌙 Dark '\(tab.rawValue)'")
                        }
                    }
                }
                
                // Phase 3: Capture Light Theme
                let phase3Start = Double(tabMap.count) * 0.7 + 1.2
                DispatchQueue.main.asyncAfter(deadline: .now() + phase3Start) {
                    self.settings.appTheme = "light"
                    
                    for (idx, (tab, filename)) in tabMap.enumerated() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.7) {
                            self.selectedTab = tab
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                captureCurrent(targetDir: lightDir, filename: filename, prefixMsg: "☀️ Light '\(tab.rawValue)'")
                            }
                        }
                    }
                    
                    // Reset back to classic theme and live wallpapers
                    let finishDelay = Double(tabMap.count) * 0.7 + 0.8
                    DispatchQueue.main.asyncAfter(deadline: .now() + finishDelay) {
                        self.settings.appTheme = "classic"
                        self.selectedTab = .liveWallpapers
                        print("[ScreenshotAutomation] 🎉 All 3-Theme Screenshots Captured & Stored Successfully!")
                    }
                }
            }
        }
    }
    
    private func sidebarSection(title: String, tabs: [NavigationTab]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if settings.appTheme == "classic" {
                Text(title)
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(MacaThemeTokens.classicTextMuted)
                    .tracking(1.0)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
            } else {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
            }
            
            ForEach(tabs) { tab in
                sidebarRow(tab: tab)
            }
        }
    }
    
    private func sidebarRow(tab: NavigationTab) -> some View {
        let isSelected = selectedTab == tab
        let isClassic = settings.appTheme == "classic"
        
        return Button(action: {
            selectedTab = tab
        }) {
            HStack(spacing: 10) {
                Image(systemName: isClassic ? classicIconName(for: tab) : tab.iconName)
                    .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                    .foregroundColor(
                        isClassic ? (isSelected ? .white : MacaThemeTokens.classicTextDark) : (isSelected ? .white : .primary)
                    )
                    .frame(width: 20)
                
                Text(tab.rawValue)
                    .font(
                        isClassic ? .system(size: 12.5, weight: isSelected ? .bold : .medium, design: .monospaced) : .system(size: 13, weight: isSelected ? .semibold : .regular)
                    )
                    .foregroundColor(
                        isClassic ? (isSelected ? .white : MacaThemeTokens.classicTextDark) : (isSelected ? .white : .primary)
                    )
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Group {
                    if isSelected {
                        if isClassic {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(MacaThemeTokens.classicOlive)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor)
                        }
                    } else {
                        Color.clear
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
    }
    
    private func classicIconName(for tab: NavigationTab) -> String {
        switch tab {
        case .liveWallpapers: return "play.rectangle"
        case .staticWallpapers: return "photo.artframe"
        case .moods: return "sparkles.rectangle.stack"
        case .marketplace: return "globe.americas"
        case .slideshow: return "clock.arrow.2.circlepath"
        case .displays: return "desktopcomputer"
        case .lockScreen: return "lock.rectangle.on.rectangle"
        case .aiConfig: return "chevron.left.forwardslash.chevron.right"
        case .userGuide: return "book.closed"
        case .settings: return "gearshape"
        }
    }
    
    private func openQuickFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .video, .quickTimeMovie, .mpeg4Movie, .gif, .image, .png, .jpeg]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            if let item = WallpaperStorageManager.shared.addCustomFileWallpaper(url: url, title: "") {
                WallpaperStorageManager.shared.setActiveWallpaper(item)
                WallpaperEngine.shared.reloadEngine()
            }
        }
    }
}

// MARK: - Native macOS Frosted Glass Visual Effect Component
public struct VisualEffectBlur: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State
    
    public init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}


