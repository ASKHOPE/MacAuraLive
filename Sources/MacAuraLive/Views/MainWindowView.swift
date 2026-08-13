import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case liveWallpapers = "Live Wallpapers"
    case staticWallpapers = "Static Wallpapers"
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
                
                // Sidebar Navigation List
                List(NavigationTab.allCases, selection: $selectedTab) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.iconName)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.vertical, 6)
                    }
                }
                .listStyle(.sidebar)
                
                Spacer()
                
                let activeItem = storage.getActiveWallpaper()
                let isStatic = activeItem == nil || activeItem?.type == .image || activeItem?.category == "Static"
                let isVideo = activeItem?.type == .video
                let isVideoWithAudio = isVideo == true && activeItem?.hasAudio == true
                
                // Active Engine & Audio Controls Widget Container (ONLY shown if a Live Wallpaper is active)
                if !isStatic, let item = activeItem {
                    VStack(alignment: .leading, spacing: 12) {
                        // Playback Status Widget
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Circle()
                                    .fill(engine.isPaused ? Color.orange : Color.green)
                                    .frame(width: 10, height: 10)
                                Text(engine.isPaused ? "Engine Paused" : "Engine Playing")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(engine.isPaused ? .orange : .green)
                                Spacer()
                                Button(action: { engine.togglePlayPause() }) {
                                    Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                                        .font(.caption)
                                        .padding(8)
                                        .background(Color.white.opacity(0.12))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text(item.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        
                        // Interactive Video Playback Slider Widget
                        if isVideo, engine.playbackDuration > 0 {
                            Divider()
                                .padding(.vertical, 2)
                            
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

                                // Playback Speed Control Row
                                HStack {
                                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text("Speed:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Picker("", selection: $settings.playbackRate) {
                                        Text("0.25x").tag(Float(0.25))
                                        Text("0.5x").tag(Float(0.5))
                                        Text("0.75x").tag(Float(0.75))
                                        Text("1.0x").tag(Float(1.0))
                                        Text("1.25x").tag(Float(1.25))
                                        Text("1.5x").tag(Float(1.5))
                                        Text("2.0x").tag(Float(2.0))
                                    }
                                    .pickerStyle(.menu)
                                    .controlSize(.mini)
                                    .frame(width: 80)
                                }
                                .padding(.top, 2)
                            }
                        }
                        
                        // Audio Volume & Mute Widget (ONLY visible for Videos with audio)
                        if isVideoWithAudio {
                            Divider()
                                .padding(.vertical, 2)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Button(action: {
                                        settings.isMuted.toggle()
                                        engine.updateAudioSettings(volume: settings.audioVolume, isMuted: settings.isMuted)
                                    }) {
                                        Image(systemName: settings.isMuted ? "speaker.slash.fill" : (settings.audioVolume > 0.5 ? "speaker.wave.3.fill" : "speaker.wave.1.fill"))
                                            .font(.caption)
                                            .foregroundColor(settings.isMuted ? .red : .blue)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text("Volume:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Text(settings.isMuted ? "Muted" : "\(Int(settings.audioVolume * 100))%")
                                        .font(.caption2)
                                        .bold()
                                        .foregroundColor(settings.isMuted ? .red : .white)
                                    
                                    Spacer()
                                }
                                
                                Slider(value: Binding(
                                    get: { settings.audioVolume },
                                    set: { newValue in
                                        settings.audioVolume = newValue
                                        engine.updateAudioSettings(volume: newValue, isMuted: settings.isMuted)
                                    }
                                ), in: 0.0...1.0)
                                .controlSize(.small)
                                .disabled(settings.isMuted)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
            }
            .frame(minWidth: 230)
        } detail: {
            Group {
                switch selectedTab {
                case .liveWallpapers:
                    GalleryView(filterType: .liveOnly)
                case .staticWallpapers:
                    GalleryView(filterType: .staticOnly)
                case .slideshow:
                    SlideshowView()
                case .displays:
                    DisplayManagerView()
                case .lockScreen:
                    LockScreenView()
                case .userGuide:
                    UserGuideView()
                case .aiConfig:
                    AdminGateView(featureTitle: "AI Workshop & Generation Playground") {
                        AIConfigurationView()
                    }
                case .settings:
                    SettingsView()
                }
            }
            .padding(28)
            .frame(minWidth: 700, minHeight: 520)
        }
        .preferredColorScheme(.dark)
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

