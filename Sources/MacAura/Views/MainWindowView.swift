import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case liveWallpapers = "Live Wallpapers"
    case staticWallpapers = "Static Wallpapers"
    case displays = "Displays"
    case lockScreen = "Lock Screen"
    case aiConfig = "AI Configuration"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .liveWallpapers: return "play.rectangle.fill"
        case .staticWallpapers: return "photo.fill"
        case .displays: return "desktopcomputer"
        case .lockScreen: return "lock.rectangle.on.rectangle.fill"
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
                        Text("MacAura")
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
                let isVideoWithAudio = activeItem?.type == .video && activeItem?.hasAudio == true
                
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
                case .displays:
                    DisplayManagerView()
                case .lockScreen:
                    AdminGateView(featureTitle: "macOS Lock Screen Wallpaper") {
                        LockScreenView()
                    }
                case .aiConfig:
                    AdminGateView(featureTitle: "AI Planner & LLM Configuration") {
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
    }
}

