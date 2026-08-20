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
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
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
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(alignment: .leading, spacing: 14) {
                // Header Logo
                HStack(spacing: 14) {
                    if settings.appTheme == "classic" {
                        // Retro System 7 / Classic Box Badge
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0.90, green: 0.88, blue: 0.84))
                                .frame(width: 38, height: 38)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(MacaThemeTokens.classicBorder, lineWidth: 1.5))
                            Text("MA")
                                .font(.system(size: 16, weight: .black, design: .monospaced))
                                .foregroundColor(MacaThemeTokens.classicOlive)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("MacAura")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(MacaThemeTokens.classicTextDark)
                            Text("V \(AppVersion.current.version) - OS Classic")
                                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                .foregroundColor(MacaThemeTokens.classicTextMuted)
                        }
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.clear)
                                .frame(width: 42, height: 42)
                            if let appIcon = NSImage(named: "AppIcon") {
                                Image(nsImage: appIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 42, height: 42)
                                    .cornerRadius(10)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 42, height: 42)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MacAuraLive")
                                .font(.system(size: 20, weight: .bold))
                            Text("Live Wallpaper Engine")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                
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
                
                Spacer()
                
                let activeItem = storage.getActiveWallpaper()
                let isStatic = activeItem == nil || activeItem?.type == .image || activeItem?.category == "Static"
                let isVideo = activeItem?.type == .video
                
                // Sidebar Footer: Active Status + Always Visible Mute / Unmute Controls
                VStack(alignment: .leading, spacing: 10) {
                    if let item = activeItem {
                        // Active Wallpaper Header
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Circle()
                                    .fill(!isStatic && engine.isPaused ? Color.orange : (isStatic ? Color.blue : Color.green))
                                    .frame(width: 8, height: 8)
                                Text(isStatic ? "Active (Static)" : (engine.isPaused ? "Engine Paused" : "Engine Playing"))
                                    .font(.caption2)
                                    .bold()
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
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { engine.playbackCurrentTime },
                                        set: { newValue in
                                            engine.seekToPosition(seconds: newValue)
                                        }
                                    ),
                                    in: 0...max(0.1, engine.playbackDuration)
                                )
                                .controlSize(.small)
                                .tint(.cyan)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 2)
                    }
                    
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
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(settings.playbackRate) },
                                    set: { newVal in
                                        let rate = Float(newVal)
                                        settings.playbackRate = rate
                                        engine.updatePlaybackRate(rate)
                                    }
                                ),
                                in: 0.25...3.0,
                                step: 0.25
                            )
                            .controlSize(.mini)
                            .tint(.orange)
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
                                        .font(.caption2)
                                        .bold()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(settings.isMuted ? Color.red.opacity(0.18) : Color.blue.opacity(0.18))
                                .foregroundColor(settings.isMuted ? .red : .blue)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            Text(settings.isMuted ? "MUTED" : "\(Int(settings.audioVolume * 100))%")
                                .font(.caption2)
                                .bold()
                                .foregroundColor(settings.isMuted ? .red : .primary)
                        }
                        
                        Slider(value: Binding(
                            get: { settings.audioVolume },
                            set: { newValue in
                                settings.audioVolume = newValue
                                engine.updateAudioSettings(volume: newValue, isMuted: settings.isMuted)
                            }
                        ), in: 0.0...1.0)
                        .controlSize(.small)
                        .tint(.blue)
                        .disabled(settings.isMuted)
                    }
                }
                .padding(12)
                .macaCardStyle(cornerRadius: 14)
                .padding(.horizontal, 14)
                
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
                            .fill(!isStatic && engine.isPaused ? Color.orange : Color.green)
                            .frame(width: 7, height: 7)
                        Text(isStatic ? "Static Engine Active" : (engine.isPaused ? "Engine Paused" : "Engine Online"))
                            .font(.system(size: 10.5, weight: .medium, design: settings.appTheme == "classic" ? .monospaced : .default))
                            .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextMuted : .secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 270, max: 320)
        } detail: {
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
            .padding(28)
            .frame(minWidth: 700, minHeight: 520)
        }
        .preferredColorScheme(
            settings.appTheme == "dark" ? .dark : (settings.appTheme == "light" || settings.appTheme == "classic" ? .light : nil)
        )
        .background(
            Group {
                if settings.appTheme == "classic" {
                    MacaThemeTokens.classicCanvas
                        .ignoresSafeArea()
                } else if settings.enableTransparency {
                    VisualEffectBlur(material: .underWindowBackground, blendingMode: .behindWindow)
                        .ignoresSafeArea()
                } else {
                    Color(nsColor: .windowBackgroundColor)
                        .ignoresSafeArea()
                }
            }
        )
        .onAppear {
            if CommandLine.arguments.contains("--capture-screenshots") {
                exportAllScreenshots()
            }
        }
    }
    
    private func exportAllScreenshots() {
        let baseDir = "/Users/hosanna/Documents/wallpapermacs/Documentation/Screenshots"
        let darkDir = "\(baseDir)/dark"
        let lightDir = "\(baseDir)/light"
        try? FileManager.default.createDirectory(atPath: baseDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: darkDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: lightDir, withIntermediateDirectories: true)
        
        let tabMap: [(NavigationTab, String)] = [
            (.liveWallpapers, "01_live_wallpapers.png"),
            (.staticWallpapers, "02_static_wallpapers.png"),
            (.slideshow, "03_slideshow_schedule.png"),
            (.displays, "04_displays.png"),
            (.lockScreen, "05_lock_screen.png"),
            (.userGuide, "06_user_guide.png"),
            (.aiConfig, "07_ai_workshop.png"),
            (.settings, "08_settings.png"),
            (.marketplace, "09_marketplace.png")
        ]
        
        // Phase 1: Capture Dark Theme
        self.settings.appTheme = "dark"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            for (idx, (tab, filename)) in tabMap.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.85) {
                    self.selectedTab = tab
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        if let window = NSApp.windows.first(where: { $0.isVisible }) {
                            window.makeKeyAndOrderFront(nil)
                            if let cgImage = CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(window.windowNumber), [.boundsIgnoreFraming, .bestResolution]) {
                                let bitmap = NSBitmapImageRep(cgImage: cgImage)
                                if let pngData = bitmap.representation(using: .png, properties: [:]) {
                                    try? pngData.write(to: URL(fileURLWithPath: "\(darkDir)/\(filename)"))
                                    try? pngData.write(to: URL(fileURLWithPath: "\(baseDir)/\(filename)"))
                                    print("[ScreenshotAutomation] 🌙 Exported Dark tab '\(tab.rawValue)' to \(darkDir)/\(filename)")
                                }
                            }
                        }
                    }
                }
            }
            
            // Phase 2: Capture Light Theme
            let phase2Start = Double(tabMap.count) * 0.85 + 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + phase2Start) {
                self.settings.appTheme = "light"
                
                for (idx, (tab, filename)) in tabMap.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.85) {
                        self.selectedTab = tab
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            if let window = NSApp.windows.first(where: { $0.isVisible }) {
                                window.makeKeyAndOrderFront(nil)
                                if let cgImage = CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(window.windowNumber), [.boundsIgnoreFraming, .bestResolution]) {
                                    let bitmap = NSBitmapImageRep(cgImage: cgImage)
                                    if let pngData = bitmap.representation(using: .png, properties: [:]) {
                                        try? pngData.write(to: URL(fileURLWithPath: "\(lightDir)/\(filename)"))
                                        print("[ScreenshotAutomation] ☀️ Exported Light tab '\(tab.rawValue)' to \(lightDir)/\(filename)")
                                    }
                                }
                            }
                        }
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
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
            } else {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 14)
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
        .padding(.horizontal, 8)
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


