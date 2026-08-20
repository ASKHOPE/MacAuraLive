import SwiftUI

public struct UserGuideView: View {
    @State private var searchQuery: String = ""
    @State private var selectedCategory: GuideCategory = .all
    @State private var expandedTopicId: String? = "quickstart"
    
    public init() {}
    
    enum GuideCategory: String, CaseIterable, Identifiable {
        case all = "All Topics"
        case quickStart = "Quick Start"
        case moods = "Moods & macOS Sync"
        case updater = "In-App Updates"
        case marketplace = "Marketplace & APIs"
        case lockScreen = "Lock Screen"
        case slideshow = "Slideshow & Schedules"
        case displays = "Multi-Monitor"
        case aiWorkshop = "AI Workshop & WebGL"
        case performance = "Performance & Battery"
        case audio = "Sound & Audio"
        case troubleshoot = "Troubleshooting & FAQ"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .all: return "sparkles"
            case .quickStart: return "play.circle.fill"
            case .moods: return "sparkles.rectangle.stack"
            case .updater: return "arrow.triangle.2.circlepath.circle.fill"
            case .marketplace: return "globe.americas.fill"
            case .lockScreen: return "lock.rectangle.on.rectangle.fill"
            case .slideshow: return "clock.arrow.2.circlepath"
            case .displays: return "desktopcomputer"
            case .aiWorkshop: return "sparkles.tv"
            case .performance: return "bolt.fill"
            case .audio: return "speaker.wave.2.fill"
            case .troubleshoot: return "questionmark.circle.fill"
            }
        }
    }
    
    struct GuideTopic: Identifiable {
        let id: String
        let category: GuideCategory
        let title: String
        let summary: String
        let badge: String
        let badgeColor: Color
        let steps: [String]
        let tips: [String]
        let shortcutsOrPaths: [(label: String, value: String)]
    }
    
    private var allTopics: [GuideTopic] {
        [
            // Mood Profiles & macOS Sync
            GuideTopic(
                id: "moods",
                category: .moods,
                title: "Mood Profiles: Custom Wallpaper Templates & macOS Mode Sync",
                summary: "Group wallpapers under customizable mood profiles and automatically trigger them on Focus Mode, Sleep, or Appearance changes.",
                badge: "NEW in v1.9.3.1",
                badgeColor: .indigo,
                steps: [
                    "1. Open 'Moods & Presets' from the sidebar.",
                    "2. Browse built-in mood profiles: Deep Focus, Night Sanctuary, Day Flow & Energy, and Cyber Lounge.",
                    "3. Click 'Create New Mood Profile' to make a custom playlist with tailored rotation intervals.",
                    "4. Link an automatic macOS trigger: 'Focus Mode / DND', 'macOS Sleep', or 'Dark / Light Theme'.",
                    "5. Whenever your Mac enters that state, MacAuraLive activates the linked mood and updates your desktop seamlessly."
                ],
                tips: [
                    "You can manually switch active moods anytime by clicking the 'Activate Mood' button on any profile card.",
                    "Mood playlists support mixing 4K videos, live WebGL shaders, and high-res static photos."
                ],
                shortcutsOrPaths: [
                    (label: "System Focus Trigger", value: "Auto-activates on Focus Mode / Do Not Disturb"),
                    (label: "System Sleep Trigger", value: "Auto-activates when Mac or screen sleeps")
                ]
            ),
            
            // In-App Updater
            GuideTopic(
                id: "updater",
                category: .updater,
                title: "In-App Background Updater & 1-Click Relaunch",
                summary: "Download and apply GitHub releases directly in Settings without visiting a browser.",
                badge: "NEW in v1.9.3.1",
                badgeColor: .green,
                steps: [
                    "1. Open Settings (Command + ,) and scroll down to the 'Software Update' section.",
                    "2. Click 'Check for Updates' to query the latest MacAuraLive release on GitHub.",
                    "3. If a new version is available, review the release notes and click 'Download & Install Update'.",
                    "4. Watch the live background download progress bar.",
                    "5. Once downloaded, click 'Restart & Update' to relaunch immediately with the new release."
                ],
                tips: [
                    "The updater automatically verifies SHA-256 cryptographic checksums before replacing the application bundle in /Applications.",
                    "Rollback safety manifests are preserved in build_history.json for complete peace of mind."
                ],
                shortcutsOrPaths: [
                    (label: "Update Check", value: "Settings > Software Update"),
                    (label: "Release Source", value: "github.com/ASKHOPE/MacAuraLive/releases")
                ]
            ),
            
            // 1. Quick Start
            GuideTopic(
                id: "quickstart",
                category: .quickStart,
                title: "Quick Start: Applying Wallpapers & Scale Modes",
                summary: "Learn how to preview, activate, scale, and adjust live and static wallpapers.",
                badge: "ESSENTIAL",
                badgeColor: .blue,
                steps: [
                    "1. Open the left sidebar and select either 'Live Wallpapers' (video loops & WebGL shaders) or 'Static Wallpapers' (4K/8K images).",
                    "2. Hover over any wallpaper card to see its live dynamic preview or click the eye icon (Quick Look) for full resolution inspection.",
                    "3. Click anywhere on the card or click 'Apply Wallpaper' to set it on your desktop immediately.",
                    "4. Choose your preferred Scaling Placement in Settings > Live Wallpaper Placement (Default is 'Stretch to Fill Screen', or select 'Fill Aspect Ratio', 'Fit (Contain)', 'Center', or 'Custom Zoom 0.5x - 2.5x').",
                    "5. Control playback speed (0.25x to 2.0x) or pause/resume rendering using the sidebar footer status widget."
                ],
                tips: [
                    "MacAuraLive renders underneath your Finder desktop icons, so all your desktop files, folders, and widgets remain fully interactive.",
                    "The Dynamic Desktop Icon Contrast engine computes wallpaper luminance in real-time and adjusts Finder icon text shadows for maximum legibility."
                ],
                shortcutsOrPaths: [
                    (label: "Quick Mute/Unmute", value: "Click the Mute button in the sidebar footer or menu bar"),
                    (label: "Default Placement", value: "Stretch to Fill Screen (Active on App Launch)")
                ]
            ),
            
            // 2. Marketplace & Content Plugins
            GuideTopic(
                id: "marketplace",
                category: .marketplace,
                title: "Online Marketplace: Connecting Unsplash, Pixabay & Pexels",
                summary: "Discover millions of 4K wallpapers and video loops with secure API plugins.",
                badge: "MARKETPLACE",
                badgeColor: .cyan,
                steps: [
                    "1. Open the 'Marketplace' tab from the sidebar to browse curated online wallpaper feeds.",
                    "2. Filter by provider (Unsplash, Pixabay, Pexels), media type (Videos, Photos), or discovery tags (Nature, Ocean, Cyberpunk, Space, Dark).",
                    "3. Click 'Configure API Keys' or visit Settings > Marketplace & Content Plugins to add your free developer keys for high-rate quota access.",
                    "4. Enter your API key in the dedicated card row, click 'Save Key' (stored securely in macOS Keychain), or click 'Clear' to remove it anytime.",
                    "5. Click 'Download & Set' on any wallpaper to download the full 4K asset directly to your Mac and apply it instantly."
                ],
                tips: [
                    "All downloads are saved locally to your Mac at ~/Library/Application Support/MacAuraLive/Media/ so you can enjoy them forever offline without repeated downloads.",
                    "Obtaining API keys is 100% free: click 'Get Free Key ↗' next to each provider to generate your personal key in 30 seconds."
                ],
                shortcutsOrPaths: [
                    (label: "Videos Storage Path", value: "~/Library/Application Support/MacAuraLive/Media/livewallpaper/"),
                    (label: "Photos Storage Path", value: "~/Library/Application Support/MacAuraLive/Media/staticwallpaper/"),
                    (label: "Key Security", value: "macOS Keychain Hardware Enclave (AES-256 GCM)")
                ]
            ),
            
            // 3. Lock Screen Wallpaper
            GuideTopic(
                id: "lockscreen",
                category: .lockScreen,
                title: "Lock Screen Wallpaper: Independent macOS Lock Screen Setup",
                summary: "Configure an independent static photo on your lock screen while keeping live wallpapers on desktop.",
                badge: "CUSTOMIZATION",
                badgeColor: .purple,
                steps: [
                    "1. Open the 'Lock Screen' tab from the sidebar.",
                    "2. Select a high-resolution photo from your MacAuraLive library, or click 'Browse Image…' to choose any photo (JPEG, PNG, HEIC, TIFF, WebP) from your Mac.",
                    "3. Click 'Set as Lock Screen Wallpaper'.",
                    "4. MacAuraLive will configure macOS lock screen image cache with zero delay.",
                    "5. Press Control + Command + Q or close your MacBook lid to test your new lock screen!"
                ],
                tips: [
                    "macOS lock screen displays static images natively, while MacAuraLive keeps high-performance live motion loops playing seamlessly on your unlocked desktop."
                ],
                shortcutsOrPaths: [
                    (label: "Test Lock Screen", value: "Press ^ + ⌘ + Q (Control + Command + Q)"),
                    (label: "Supported Formats", value: "JPEG, PNG, HEIC, TIFF, WebP, GIF")
                ]
            ),
            
            // 4. Slideshow & Scheduled Rotation
            GuideTopic(
                id: "slideshow",
                category: .slideshow,
                title: "Slideshow & Timed Scheduling: Automated Wallpaper Rotation",
                summary: "Automatically rotate wallpapers on interval timers or scheduled times of day.",
                badge: "AUTOMATION",
                badgeColor: .green,
                steps: [
                    "1. Open 'Slideshow & Schedule' from the sidebar.",
                    "2. Toggle 'Interval Slideshow Engine' ON to rotate wallpapers automatically.",
                    "3. Set your preferred frequency: 5 min, 15 min, 30 min, 1 hour, 2 hours, 6 hours, 12 hours, or 24 hours.",
                    "4. Enable 'Shuffle Mode' for randomized selection across your library.",
                    "5. Build a custom playlist in the visual selector: click checkmarks on specific wallpapers to include only your favorites.",
                    "6. Configure Time-of-Day Rules: Click 'Add Time Rule' to schedule specific wallpapers at exact times (e.g. Sunrise at 07:00, Cyberpunk at 21:00)."
                ],
                tips: [
                    "Timed rules take priority over interval rotations, ensuring your desktop always matches your time of day.",
                    "The slideshow engine runs smoothly in the background with zero CPU consumption between transition cycles."
                ],
                shortcutsOrPaths: [
                    (label: "Frequencies", value: "5m, 15m, 30m, 1h, 2h, 6h, 12h, 24h"),
                    (label: "Transition", value: "Smooth cross-fade GPU shader transition")
                ]
            ),
            
            // 5. Multi-Monitor Displays
            GuideTopic(
                id: "displays",
                category: .displays,
                title: "Multi-Monitor Configuration & Ultra-Wide Display Spanning",
                summary: "Configure per-screen wallpapers or span a single 32:9 wallpaper across all monitors.",
                badge: "DISPLAYS",
                badgeColor: .orange,
                steps: [
                    "1. Open the 'Displays' tab from the sidebar to inspect all currently connected monitors.",
                    "2. Per-Display Mode: Click on any screen in the preview canvas and choose an independent wallpaper for that specific display.",
                    "3. Ultra-Wide Spanning Mode: In Settings > Default Display & Multi-Monitor Settings, toggle 'Span Live Wallpaper Across All Connected Displays' ON.",
                    "4. When Spanning is active, a single high-resolution wallpaper (e.g. 5120x1440 or 7680x2160) will stretch continuously across all your displays seamlessly."
                ],
                tips: [
                    "MacAuraLive automatically detects monitor connection and disconnection events (DisplayConfigChanged) and recalibrates screen coordinates without needing a restart."
                ],
                shortcutsOrPaths: [
                    (label: "Display Spanning", value: "Settings > Span Live Wallpaper Across All Connected Displays"),
                    (label: "Hot-Plug Detection", value: "Automatic native CoreGraphics reconfiguration")
                ]
            ),
            
            // 6. Sound & Audio Settings
            GuideTopic(
                id: "audio",
                category: .audio,
                title: "Sound & Audio Controls: Volume, Muting & VU Meters",
                summary: "Full audio management for video wallpapers with background sound tracks.",
                badge: "AUDIO",
                badgeColor: .indigo,
                steps: [
                    "1. Wallpapers with audio tracks are marked with an 'Audio' badge and an animated VU meter in the gallery.",
                    "2. Use the persistent sidebar footer audio widget to instantly Mute or Unmute audio with 1 click.",
                    "3. Adjust the Volume Slider from 0% to 100% to set your preferred ambiance level.",
                    "4. In Settings > Wallpaper Sound & Audio Settings, toggle 'Mute audio automatically when app loses focus' if you only want wallpaper audio when viewing your desktop."
                ],
                tips: [
                    "MacAuraLive uses Apple AVFoundation audio mixing so wallpaper audio harmoniously blends with your Apple Music, Spotify, or video calls without clipping."
                ],
                shortcutsOrPaths: [
                    (label: "Sidebar Audio Widget", value: "Always visible at the bottom of the left sidebar"),
                    (label: "Audio Formats", value: "AAC, ALAC, MP3, Linear PCM embedded in MP4/MOV")
                ]
            ),
            
            // 7. AI Workshop & WebGL Shaders
            GuideTopic(
                id: "aiworkshop",
                category: .aiWorkshop,
                title: "AI Workshop & Interactive WebGL Shader Generation",
                summary: "Generate 60fps interactive generative shaders with Google Gemini, OpenRouter, or Ollama.",
                badge: "AI STUDIO",
                badgeColor: .pink,
                steps: [
                    "1. Open 'AI Workshop' from the sidebar.",
                    "2. Select your AI provider: OpenRouter (DeepSeek R1, Llama 3, Claude), Google Gemini (Gemini 2.0 Flash / Pro), or Local Ollama (100% offline).",
                    "3. Enter your AI API key in the dedicated settings card and click 'Save Key'.",
                    "4. Type a natural language prompt describing the shader you want (e.g. 'Cyberpunk neon rain ripples on dark asphalt with glowing reflections').",
                    "5. Click 'Generate Live Shader Wallpaper' to generate complete, executable WebGL/HTML5 code with live terminal logs.",
                    "6. The generated shader is automatically saved to ~/Documents/MacAuraLiveApp/animatedcode/ and applied to your desktop!"
                ],
                tips: [
                    "Generated shaders are 100% standalone standard WebGL/HTML5 files that run locally at 60fps on Apple Silicon GPUs without continuous internet connection."
                ],
                shortcutsOrPaths: [
                    (label: "Code Storage Path", value: "~/Documents/MacAuraLiveApp/animatedcode/"),
                    (label: "Frame Rate", value: "Smooth 60fps Metal WebKit Canvas")
                ]
            ),
            
            // 8. Performance & Battery Saver
            GuideTopic(
                id: "performance",
                category: .performance,
                title: "Smart Performance & Battery Saver: Zero Resource Overhead",
                summary: "Optimizing GPU and CPU usage for maximum MacBook battery life.",
                badge: "PERFORMANCE",
                badgeColor: .yellow,
                steps: [
                    "1. Open Settings > Smart Performance & Battery Saver.",
                    "2. Enable 'Pause live wallpaper when on battery power': When unplugging your MacBook, the wallpaper automatically pauses rendering to preserve 100% battery life.",
                    "3. Enable 'Pause when full-screen applications/games are focused': When you play games or edit 4K video full-screen, the engine pauses to yield 100% GPU/CPU power to your game.",
                    "4. Grant Screen Recording permission when prompted so MacAuraLive can detect active full-screen windows (no screen data is ever recorded or transmitted)."
                ],
                tips: [
                    "MacAuraLive uses native Apple Silicon Metal acceleration and AVPlayerLayer hardware decoders, typically consuming less than 1-2% CPU when active."
                ],
                shortcutsOrPaths: [
                    (label: "Battery Saver", value: "Settings > Pause on Battery Power"),
                    (label: "Gaming Mode", value: "Settings > Pause on Full-Screen Apps")
                ]
            ),
            
            // 9. Troubleshooting & System Permissions
            // Multi-Selection & Batch Management
            GuideTopic(
                id: "multiselect",
                category: .quickStart,
                title: "Multi-Selection & Batch Media Operations",
                summary: "Select multiple wallpapers simultaneously to delete, clear, or manage your library in bulk.",
                badge: "NEW v1.8.0",
                badgeColor: .blue,
                steps: [
                    "1. Open either the 'Live Wallpapers' or 'Static Wallpapers' tab.",
                    "2. Click the 'Select Items' button located in the top header action bar.",
                    "3. Click on any wallpaper cards to toggle their selection, or click 'Select All' to highlight all custom items at once.",
                    "4. The header action bar displays your selection count (e.g. '3 of 12 selected').",
                    "5. Click 'Clear Selected (X)' to permanently batch remove the chosen wallpapers and their local disk files, or click 'Done' to exit selection mode."
                ],
                tips: [
                    "Built-in default wallpapers cannot be deleted to ensure your app always has a stable fallback wallpaper.",
                    "Card footers dynamically display both the resolution tag and exact file size (e.g., '4K UHD • 12.4 MB')."
                ],
                shortcutsOrPaths: [
                    (label: "Multi-Select Toggle", value: "Header 'Select Items' Button"),
                    (label: "Batch Delete Action", value: "Header 'Clear Selected (X)' Button")
                ]
            ),
            
            // Duplicate Scanner, Backup & Granular Reset
            GuideTopic(
                id: "datamanagement",
                category: .performance,
                title: "Duplicate Media Scanner, Settings Backup & Targeted Reset",
                summary: "Find and remove duplicate files, export/import JSON configurations, or perform granular resets.",
                badge: "NEW v1.8.0",
                badgeColor: .purple,
                steps: [
                    "1. Open Settings > Duplicate Media Scanner & Cleaner and click 'Scan for Duplicates'.",
                    "2. The SHA-256 byte scanner detects duplicate video, image, or GIF files and calculates the total wasted storage space.",
                    "3. Click 'Clean All Duplicates' to reclaim disk space in 1 click (keeps the primary original copy).",
                    "4. In Settings > Settings Backup & Migration, click 'Export Settings (JSON)...' to save a portable backup of all preferences and display assignments.",
                    "5. To restore your setup on any Mac, click 'Import Settings (JSON)...' and choose your backup file.",
                    "6. In Settings > Data Management & Reset, use 'Reset Only Media' to wipe custom wallpapers without touching settings, 'Reset Only Preferences' to reset options without losing media, or 'Full Factory Reset' for a complete wipe."
                ],
                tips: [
                    "Reset Only Media clears ~/Library/Application Support/MacAuraLive/Media/ and re-extracts the bundled high-resolution wallpaper pack without wiping API keys or preferences.",
                    "Exported JSON backups are lightweight (<100 KB) and human-readable."
                ],
                shortcutsOrPaths: [
                    (label: "Duplicate Scanner", value: "Settings > Duplicate Media Scanner & Cleaner"),
                    (label: "Settings Backup", value: "Settings > Settings Backup & Migration"),
                    (label: "Media Reset", value: "Settings > Reset Only Media")
                ]
            ),
            
            // 9. Help, Permissions & FAQ
            GuideTopic(
                id: "faq",
                category: .troubleshoot,
                title: "Troubleshooting, Permissions & Local Storage Directory Guide",
                summary: "Common questions, file permissions, local storage paths, and reset instructions.",
                badge: "HELP & FAQ",
                badgeColor: .red,
                steps: [
                    "1. Where are my wallpapers stored? All user files and marketplace downloads are stored in ~/Library/Application Support/MacAuraLive/Media/ divided into livewallpaper/, staticwallpaper/, gif/, and animatedcode/.",
                    "2. How do I add my own video loops or images? Simply copy your MP4, MOV, GIF, or JPEG files into the respective subfolder in ~/Library/Application Support/MacAuraLive/Media/, then click 'Sync Now' in Settings > Monitored Local Folder.",
                    "3. Screen Recording Permission: Required exclusively for full-screen application detection so the engine can pause during gaming. If needed, toggle it in System Settings > Privacy & Security > Screen Recording.",
                    "4. Launch at Login: In Settings > General Settings & Startup, enable 'Launch MacAuraLive at System Startup' to run silently in the menu bar on boot.",
                    "5. Resetting Settings: In Settings > Data Management & Reset, choose 'Reset Only Media', 'Reset Only Preferences', or 'Full Factory Reset'."
                ],
                tips: [
                    "If you ever need to clear API keys, use the 'Clear' button next to each key in Settings > Marketplace & Content Plugins or delete the app support cache."
                ],
                shortcutsOrPaths: [
                    (label: "Root Folder", value: "~/Library/Application Support/MacAuraLive/Media/"),
                    (label: "Video Loops", value: "~/Library/Application Support/MacAuraLive/Media/livewallpaper/"),
                    (label: "Static 4K", value: "~/Library/Application Support/MacAuraLive/Media/staticwallpaper/"),
                    (label: "GIF Animations", value: "~/Library/Application Support/MacAuraLive/Media/gif/"),
                    (label: "Code Shaders", value: "~/Library/Application Support/MacAuraLive/Media/animatedcode/")
                ]
            )
        ]
    }
    
    private var filteredTopics: [GuideTopic] {
        allTopics.filter { topic in
            let matchesCategory = selectedCategory == .all || topic.category == selectedCategory
            let matchesSearch = searchQuery.isEmpty ||
                topic.title.localizedCaseInsensitiveContains(searchQuery) ||
                topic.summary.localizedCaseInsensitiveContains(searchQuery) ||
                topic.steps.contains { $0.localizedCaseInsensitiveContains(searchQuery) } ||
                topic.tips.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            return matchesCategory && matchesSearch
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Bar
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("User Guide & Documentation")
                        .font(.system(size: 26, weight: .bold))
                    Text("Complete step-by-step manuals, feature how-tos, keyboard shortcuts, and architecture references.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Search Input
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    TextField("Search guides, shortcuts...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .frame(width: 200)
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .macaSubcardStyle(cornerRadius: 8)
            }
            
            // Category Filter Pills with unified styling
            FlowLayout(spacing: 6) {
                ForEach(GuideCategory.allCases) { category in
                    let isSelected = selectedCategory == category
                    let isClassic = AppSettings.shared.appTheme == "classic"
                    Button(action: { selectedCategory = category }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.caption2)
                            Text(category.rawValue)
                                .font(.system(size: 11.5, weight: isSelected ? .bold : .medium, design: isClassic ? .monospaced : .default))
                                .fixedSize()
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .frame(minHeight: 28)
                        .background(
                            isSelected
                                ? (isClassic ? MacaThemeTokens.classicOlive : Color.accentColor)
                                : (isClassic ? MacaThemeTokens.classicButtonBg : Color(NSColor.controlBackgroundColor))
                        )
                        .foregroundColor(
                            isSelected
                                ? Color.white
                                : (isClassic ? MacaThemeTokens.classicTextDark : Color.primary)
                        )
                        .cornerRadius(isClassic ? 2 : 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: isClassic ? 2 : 8)
                                .stroke(isClassic ? MacaThemeTokens.classicBorder : (isSelected ? Color.clear : Color(NSColor.separatorColor)), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
            
            Divider()
            
            // Guide Topics List
            if filteredTopics.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 38))
                        .foregroundColor(.secondary)
                    Text("No matching documentation found")
                        .font(.headline)
                    Text("Try searching for terms like 'API Key', 'Lock Screen', 'Stretch', 'Mute', or 'Storage Path'.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Clear Search") {
                        searchQuery = ""
                        selectedCategory = .all
                    }
                    .macaButtonStyle(.primary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(filteredTopics) { topic in
                            InteractiveGuideCard(
                                topic: topic,
                                isExpanded: expandedTopicId == topic.id,
                                onToggle: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if expandedTopicId == topic.id {
                                            expandedTopicId = nil
                                        } else {
                                            expandedTopicId = topic.id
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .padding(24)
    }
}

// MARK: - Interactive Expandable Guide Card Component

private struct InteractiveGuideCard: View {
    let topic: UserGuideView.GuideTopic
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        let isClassic = AppSettings.shared.appTheme == "classic"
        let textPrimaryColor: Color = isClassic ? MacaThemeTokens.classicTextDark : Color.primary
        let textSecondaryColor: Color = isClassic ? MacaThemeTokens.classicTextMuted : Color.secondary
        
        VStack(alignment: .leading, spacing: 0) {
            // Card Header (Always Visible)
            Button(action: onToggle) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: isClassic ? 2 : 10)
                            .fill(isClassic ? MacaThemeTokens.classicSubcardBg : Color.accentColor.opacity(0.12))
                            .frame(width: 38, height: 38)
                        Image(systemName: topic.category.iconName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(isClassic ? MacaThemeTokens.classicOlive : .accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(topic.title)
                                .font(.system(size: 14.5, weight: .bold, design: isClassic ? .monospaced : .default))
                                .foregroundColor(textPrimaryColor)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(topic.badge)
                                .font(.system(size: 9, weight: .bold, design: isClassic ? .monospaced : .default))
                                .fixedSize()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(isClassic ? MacaThemeTokens.classicSubcardBg : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(textPrimaryColor)
                                .cornerRadius(isClassic ? 2 : 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: isClassic ? 2 : 4)
                                        .stroke(isClassic ? MacaThemeTokens.classicBorder : Color.clear, lineWidth: 0.8)
                                )
                        }
                        
                        Text(topic.summary)
                            .font(.caption)
                            .foregroundColor(textSecondaryColor)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.system(size: 18))
                        .foregroundColor(isExpanded ? (isClassic ? MacaThemeTokens.classicOlive : .accentColor) : textSecondaryColor)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            // Expanded Detailed Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    // Step-by-Step Instructions
                    VStack(alignment: .leading, spacing: 10) {
                        Text("STEP-BY-STEP INSTRUCTIONS")
                            .font(.system(size: 11, weight: .bold, design: isClassic ? .monospaced : .default))
                            .foregroundColor(textSecondaryColor)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(topic.steps, id: \.self) { step in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.headline)
                                        .foregroundColor(isClassic ? MacaThemeTokens.classicOlive : topic.badgeColor)
                                    Text(step)
                                        .font(.system(size: 13, design: isClassic ? .monospaced : .default))
                                        .foregroundColor(textPrimaryColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Pro Tips Box
                    if !topic.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(isClassic ? MacaThemeTokens.classicOlive : .orange)
                                    .font(.caption)
                                Text("PRO TIP")
                                    .font(.system(size: 10, weight: .bold, design: isClassic ? .monospaced : .default))
                                    .foregroundColor(isClassic ? MacaThemeTokens.classicOlive : .orange)
                            }
                            
                            ForEach(topic.tips, id: \.self) { tip in
                                Text(tip)
                                    .font(.caption)
                                    .foregroundColor(textPrimaryColor)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(12)
                        .background(isClassic ? MacaThemeTokens.classicSubcardBg : Color.orange.opacity(0.08))
                        .cornerRadius(isClassic ? 2 : 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: isClassic ? 2 : 8)
                                .stroke(isClassic ? MacaThemeTokens.classicBorder : Color.orange.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // Key Shortcuts or File Paths Table
                    if !topic.shortcutsOrPaths.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("REFERENCE & SHORTCUTS")
                                .font(.system(size: 11, weight: .bold, design: isClassic ? .monospaced : .default))
                                .foregroundColor(textSecondaryColor)
                            
                            VStack(spacing: 6) {
                                ForEach(topic.shortcutsOrPaths, id: \.label) { item in
                                    HStack {
                                        Text(item.label)
                                            .font(.caption)
                                            .foregroundColor(textSecondaryColor)
                                        Spacer()
                                        Text(item.value)
                                            .font(.system(size: 11, design: .monospaced))
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(isClassic ? MacaThemeTokens.classicSubcardBg : Color(NSColor.controlBackgroundColor))
                                            .cornerRadius(isClassic ? 2 : 6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: isClassic ? 2 : 6)
                                                    .stroke(isClassic ? MacaThemeTokens.classicBorder : Color.clear, lineWidth: 0.8)
                                            )
                                            .foregroundColor(textPrimaryColor)
                                    }
                                }
                            }
                            .padding(12)
                            .macaSubcardStyle(cornerRadius: isClassic ? 2 : 8)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .macaCardStyle(cornerRadius: isClassic ? 2 : 14)
    }
}
