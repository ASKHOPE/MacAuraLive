import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case liveWallpapers = "Live Wallpapers"
    case staticWallpapers = "Static Wallpapers"
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
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 14) {
                // Header Logo
                HStack(spacing: 14) {
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
                .padding(.horizontal, 18)
                .padding(.top, 18)
                
                Divider()
                    .padding(.vertical, 4)
                
                // Sidebar Navigation List (Grouped by Nature)
                List(selection: $selectedTab) {
                    Section("Library & Discover") {
                        NavigationLink(value: NavigationTab.liveWallpapers) {
                            Label(NavigationTab.liveWallpapers.rawValue, systemImage: NavigationTab.liveWallpapers.iconName)
                        }
                        NavigationLink(value: NavigationTab.staticWallpapers) {
                            Label(NavigationTab.staticWallpapers.rawValue, systemImage: NavigationTab.staticWallpapers.iconName)
                        }
                        NavigationLink(value: NavigationTab.marketplace) {
                            Label(NavigationTab.marketplace.rawValue, systemImage: NavigationTab.marketplace.iconName)
                        }
                    }
                    
                    Section("Displays & Scheduling") {
                        NavigationLink(value: NavigationTab.slideshow) {
                            Label(NavigationTab.slideshow.rawValue, systemImage: NavigationTab.slideshow.iconName)
                        }
                        NavigationLink(value: NavigationTab.displays) {
                            Label(NavigationTab.displays.rawValue, systemImage: NavigationTab.displays.iconName)
                        }
                        NavigationLink(value: NavigationTab.lockScreen) {
                            Label(NavigationTab.lockScreen.rawValue, systemImage: NavigationTab.lockScreen.iconName)
                        }
                    }
                    
                    Section("Creative Studio") {
                        NavigationLink(value: NavigationTab.aiConfig) {
                            Label(NavigationTab.aiConfig.rawValue, systemImage: NavigationTab.aiConfig.iconName)
                        }
                    }
                    
                    Section("System & Support") {
                        NavigationLink(value: NavigationTab.userGuide) {
                            Label(NavigationTab.userGuide.rawValue, systemImage: NavigationTab.userGuide.iconName)
                        }
                        NavigationLink(value: NavigationTab.settings) {
                            Label(NavigationTab.settings.rawValue, systemImage: NavigationTab.settings.iconName)
                        }
                    }
                }
                .listStyle(.sidebar)
                
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
                                            .background(Color.white.opacity(0.12))
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
                                .background(settings.isMuted ? Color.red.opacity(0.25) : Color.blue.opacity(0.25))
                                .foregroundColor(settings.isMuted ? .red : .cyan)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            Text(settings.isMuted ? "MUTED" : "\(Int(settings.audioVolume * 100))%")
                                .font(.caption2)
                                .bold()
                                .foregroundColor(settings.isMuted ? .red : .white)
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
                .background(Color.black.opacity(0.4))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .frame(minWidth: 230)
        } detail: {
            Group {
                switch selectedTab {
                case .liveWallpapers:
                    GalleryView(filterType: .liveOnly)
                case .staticWallpapers:
                    GalleryView(filterType: .staticOnly)
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
            settings.appTheme == "dark" ? .dark : (settings.appTheme == "light" ? .light : nil)
        )
        .background(
            Group {
                if settings.enableTransparency {
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
        let outDir = "/Users/hosanna/Documents/wallpapermacs/Documentation/Screenshots"
        try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
        
        let tabMap: [(NavigationTab, String)] = [
            (.liveWallpapers, "01_live_wallpapers.png"),
            (.staticWallpapers, "02_static_wallpapers.png"),
            (.slideshow, "03_slideshow_schedule.png"),
            (.displays, "04_displays.png"),
            (.lockScreen, "05_lock_screen.png"),
            (.userGuide, "06_user_guide.png"),
            (.aiConfig, "07_ai_workshop.png"),
            (.settings, "08_settings.png")
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            for (idx, (tab, filename)) in tabMap.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.8) {
                    self.selectedTab = tab
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        if let window = NSApp.windows.first(where: { $0.isVisible }),
                           let view = window.contentView {
                            let rect = view.bounds
                            if let bitmap = view.bitmapImageRepForCachingDisplay(in: rect) {
                                view.cacheDisplay(in: rect, to: bitmap)
                                if let pngData = bitmap.representation(using: .png, properties: [:]) {
                                    let savePath = "\(outDir)/\(filename)"
                                    try? pngData.write(to: URL(fileURLWithPath: savePath))
                                    print("[ScreenshotAutomation] ✅ Exported tab '\(tab.rawValue)' to \(savePath)")
                                }
                            }
                        }
                        
                        if idx == tabMap.count - 1 {
                            print("[ScreenshotAutomation] 🎉 All 8 UI tab screenshots exported successfully!")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                NSApp.terminate(nil)
                            }
                        }
                    }
                }
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


