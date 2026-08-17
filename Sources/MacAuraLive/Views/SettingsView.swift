import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var engine = WallpaperEngine.shared
    @ObservedObject var storage = WallpaperStorageManager.shared
    @ObservedObject var updater = UpdateManager.shared
    @ObservedObject var storageAnalytics = StorageAnalyticsManager.shared
    
    @State private var syncStatusMessage: String? = nil
    @State private var showTOSModal: Bool = false
    @State private var showLicenseModal: Bool = false
    @State private var showDisclaimerModal: Bool = false
    @State private var showChangelogModal: Bool = false
    @State private var showOnboardingWizard: Bool = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title Header
            VStack(alignment: .leading, spacing: 6) {
                Text("App Preferences & Settings")
                    .font(.system(size: 28, weight: .bold))
                Text("Configure startup, multi-monitor display spanning, and monitored reference folders.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Launch at Login Toggle
                    VStack(alignment: .leading, spacing: 14) {
                        Text("System Launch Options")
                            .font(.title3)
                            .bold()
                        
                        HStack(alignment: .top, spacing: 12) {
                            Toggle(isOn: $settings.launchAtLogin) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Launch MacAuraLive on System Startup / Login")
                                        .font(.body)
                                    Text("Automatically starts MacAuraLive and restores your active live wallpaper when macOS boots.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Status badge
                            let statusColor: Color = {
                                switch settings.launchAtLoginStatus {
                                case "Active": return .green
                                case "Requires Approval": return .orange
                                case _ where settings.launchAtLoginStatus.contains("Not Found"): return .red
                                default: return .secondary
                                }
                            }()
                            Text(settings.launchAtLoginStatus)
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor.opacity(0.18))
                                .foregroundColor(statusColor)
                                .cornerRadius(6)
                                .fixedSize()
                        }
                        
                        // Guidance if status requires action
                        if settings.launchAtLoginStatus.contains("Requires Approval") {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Approval Required")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.orange)
                                    Text("Open System Settings › General › Login Items & Extensions and allow MacAuraLive.")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Open System Settings") {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                            .padding(10)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                        } else if settings.launchAtLoginStatus.contains("Not Found") {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.badge.questionmark")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Move App to Applications Folder")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.red)
                                    Text("SMAppService requires MacAuraLive to be located in /Applications. Move the app there and try again.")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        if let error = settings.launchAtLoginError {
                            Text("⚠️ \(error)")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )

                    
                    // App Theme & macOS Appearance Customization Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .font(.title3)
                                .foregroundColor(.pink)
                            Text("App Theme & macOS Appearance")
                                .font(.title3)
                                .bold()
                            Spacer()
                            Text(settings.appTheme == "system" ? "AUTO (macOS)" : settings.appTheme.uppercased())
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.pink.opacity(0.18))
                                .foregroundColor(.pink)
                                .cornerRadius(6)
                        }
                        
                        Text("Customize dashboard appearance to follow native macOS settings with glassmorphic transparency and auto-adapting Day/Night wallpapers.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Theme Selection Segmented Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Appearance Mode")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Picker("Appearance Mode", selection: $settings.appTheme) {
                                Text("💻 Follow macOS Native (Auto)").tag("system")
                                Text("🌙 Dark Mode").tag("dark")
                                Text("☀️ Light Mode").tag("light")
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        Divider()
                            .padding(.vertical, 2)
                        
                        // Frosted Glass Transparency & Vibrancy Toggle
                        Toggle(isOn: $settings.enableTransparency) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable macOS Frosted Glass Vibrancy & Translucency")
                                    .font(.body)
                                Text("Uses native NSVisualEffectView behind-window blur for an ultra-premium liquid macOS glass aesthetic.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Day/Night Automatic Wallpaper Adaptation
                        Toggle(isOn: $settings.autoDayNightWallpapers) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dynamic Day & Night Wallpaper Auto-Adaptation")
                                    .font(.body)
                                Text("Automatically activates Night wallpapers when macOS Dark Mode triggers, and Day wallpapers when Light Mode triggers.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Wallpaper Placement & Scaling Options Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Wallpaper Placement & Scaling")
                            .font(.title3)
                            .bold()
                        
                        Text("Configure how static images, video loops, and live WebGL wallpapers fit your desktop displays.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Placement Mode", selection: $settings.wallpaperPlacement) {
                            Text("Original Resolution (Default - macOS Native Fit)").tag("original")
                            Text("Fit to Screen (Preserve Aspect Ratio)").tag("fit")
                            Text("Crop to Fill Screen (Aspect Fill)").tag("fill")
                            Text("Stretch to Fill Screen").tag("stretch")
                            Text("Custom Zoom & Scale").tag("zoom")
                        }
                        .pickerStyle(.menu)
                        
                        if settings.wallpaperPlacement == "zoom" || settings.wallpaperPlacement == "center" {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Zoom Scale Level")
                                        .font(.subheadline)
                                    Spacer()
                                    Text(String(format: "%.0f%%", settings.wallpaperZoom * 100))
                                        .font(.subheadline)
                                        .bold()
                                        .monospacedDigit()
                                }
                                
                                Slider(value: $settings.wallpaperZoom, in: 0.25...3.0, step: 0.05)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Display & Spanning Configuration Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Multi-Monitor Display Spanning")
                            .font(.title3)
                            .bold()
                        
                        Toggle(isOn: $settings.spanAcrossDisplays) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Span Live Wallpaper Across All Connected Displays")
                                    .font(.body)
                                Text("Stretches a single ultra-wide 4K/8K live wallpaper across multiple monitors without black screens.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Default Application Directories Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                            Text("Default MacAuraLive Document Directories")
                                .font(.title3)
                                .bold()
                            Spacer()
                            Text("Documents/MacAuraLiveApp")
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                        
                        Text("MacAuraLive automatically maintains the following folder structure inside your macOS Documents directory:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill").foregroundColor(.blue)
                                Text("~/Documents/MacAuraLiveApp/").bold().font(.subheadline)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("├──").foregroundColor(.secondary)
                                    Image(systemName: "film").foregroundColor(.purple)
                                    Text("livewallpaper").font(.caption).bold()
                                    Text("(Live Video & WebGL loops)").font(.caption2).foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 8) {
                                    Text("├──").foregroundColor(.secondary)
                                    Image(systemName: "photo").foregroundColor(.green)
                                    Text("staticwallpaper").font(.caption).bold()
                                    Text("(Static High-Res Images)").font(.caption2).foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 8) {
                                    Text("├──").foregroundColor(.secondary)
                                    Image(systemName: "play.square").foregroundColor(.orange)
                                    Text("gif").font(.caption).bold()
                                    Text("(Animated GIF wallpapers)").font(.caption2).foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 8) {
                                    Text("└──").foregroundColor(.secondary)
                                    Image(systemName: "chevron.left.forwardslash.chevron.right").foregroundColor(.pink)
                                    Text("animatedcode").font(.caption).bold()
                                    Text("(HTML5 / WebGL Canvas Runtimes)").font(.caption2).foregroundColor(.secondary)
                                }
                            }
                            .padding(.leading, 16)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(10)
                        
                        HStack {
                            Spacer()
                            Button("Open MacAuraLiveApp in Finder") {
                                if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                                    let path = docs.appendingPathComponent("MacAuraLiveApp")
                                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path.path)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Monitored Reference Folder Configuration Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Monitored Bulk Reference Folder")
                                .font(.title3)
                                .bold()
                            Spacer()
                            Text("Auto-Sync")
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.3))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                        
                        Text("Select a local folder (e.g., ~/Movies/Wallpapers). MacAuraLive will continuously monitor and auto-import all MP4, GIF, and Image wallpapers.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(storage.referencedFolderURL ?? "No folder selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .padding(8)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(6)
                            
                            Spacer()
                            
                            Button("Select Folder...") {
                                openReferenceFolderPicker()
                            }
                            .buttonStyle(.bordered)
                            
                            if storage.referencedFolderURL != nil {
                                Button("Sync Now") {
                                    let count = WallpaperStorageManager.shared.syncReferencedFolder()
                                    engine.reloadEngine()
                                    syncStatusMessage = "Synced \(count) new item(s) from reference folder."
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        
                        if let statusMsg = syncStatusMessage {
                            Text(statusMsg)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Admin Passcode & Early Access Security Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .font(.title3)
                                .foregroundColor(.purple)
                            Text("Early Access & Admin Security")
                                .font(.title3)
                                .bold()
                            Spacer()
                            Text(settings.isAdminUnlocked ? "UNLOCKED" : "LOCKED")
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(settings.isAdminUnlocked ? Color.green.opacity(0.2) : Color.purple.opacity(0.2))
                                .foregroundColor(settings.isAdminUnlocked ? .green : .purple)
                                .cornerRadius(6)
                        }
                        
                        Text("Early access features (AI Configuration) are protected by Admin Passcode.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(settings.isAdminUnlocked ? "Admin Early Access Active" : "Early Access Features Locked")
                                    .font(.body)
                                    .bold()
                                Text(settings.isAdminUnlocked ? "You have full access to Lock Screen and AI Configuration features." : "Passcode required to access early testing features.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if settings.isAdminUnlocked {
                                Button("Lock Features Now") {
                                    settings.isAdminUnlocked = false
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.purple)
                            } else {
                                Text("Passcode Gate Active")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Smart Performance Options
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Smart Performance & Battery Saver")
                            .font(.title3)
                            .bold()
                        
                        Toggle(isOn: $settings.pauseOnBattery) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pause live wallpaper when on battery power")
                                    .font(.body)
                                Text("Saves battery life by pausing GPU/CPU video & shader rendering when unplugged.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Toggle(isOn: $settings.pauseOnFullScreen) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pause when full-screen applications/games are focused")
                                    .font(.body)
                                Text("Frees 100% GPU/CPU resources when playing games or editing full-screen video.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Marketplace & Content Provider API Plugins
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "globe.americas.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                            Text("Marketplace & Content Plugins")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }
                        
                        Text("Connect Unsplash, Pixabay, and Pexels plugins to discover and download 4K wallpapers and video loops directly to your Mac.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 14) {
                            // Unsplash
                            APIKeyCardRow(
                                title: "Unsplash API Key",
                                subtitle: "Free 4K curated photography & ultra-HD static wallpapers",
                                iconName: "camera.fill",
                                iconColor: .blue,
                                placeholder: "Enter Unsplash Access Key",
                                key: $settings.unsplashApiKey,
                                helpUrl: "https://unsplash.com/developers"
                            )
                            
                            // Pixabay
                            APIKeyCardRow(
                                title: "Pixabay API Key",
                                subtitle: "Royalty-free HD/4K video motion loops & audio wallpapers",
                                iconName: "photo.stack.fill",
                                iconColor: .green,
                                placeholder: "Enter Pixabay API Key",
                                key: $settings.pixabayApiKey,
                                helpUrl: "https://pixabay.com/api/docs/"
                            )
                            
                            // Pexels
                            APIKeyCardRow(
                                title: "Pexels API Key",
                                subtitle: "Trending 4K photos & cinematic video wallpaper loops",
                                iconName: "film.stack.fill",
                                iconColor: .teal,
                                placeholder: "Enter Pexels API Key",
                                key: $settings.pexelsApiKey,
                                helpUrl: "https://www.pexels.com/api/"
                            )
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(12)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("Stored securely in macOS Keychain (Hardware Enclave). Downloaded wallpapers are saved permanently to your Mac.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // In-Built App Storage & Resource Footprint Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "internaldrive.fill")
                                .font(.title3)
                                .foregroundColor(.indigo)
                            Text("Inbuilt Storage & Resource Breakdown")
                                .font(.title3)
                                .bold()
                            Spacer()
                            
                            Text(storageAnalytics.formattedTotalSize)
                                .font(.subheadline)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.indigo.opacity(0.2))
                                .foregroundColor(.indigo)
                                .cornerRadius(8)
                                
                            Button(action: { storageAnalytics.refresh() }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .help("Recalculate storage breakdown")
                        }
                        
                        Text("Live analytics of disk space occupied by compiled Metal code, built-in shaders, user wallpapers, and runtime cache.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Multi-color macOS segmented Storage Bar
                        StorageSegmentBarView(
                            categories: storageAnalytics.categories,
                            totalBytes: storageAnalytics.totalSizeBytes
                        )
                        .frame(height: 12)
                        
                        // Category Breakdown Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(storageAnalytics.categories) { item in
                                StorageCategoryPillView(
                                    item: item,
                                    percentage: storageAnalytics.percentage(for: item)
                                )
                            }
                        }
                        
                        HStack {
                            Button(action: {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: WallpaperStorageManager.shared.documentsDirectory.path)
                            }) {
                                Label("Open Documents Folder", systemImage: "folder.fill")
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                            
                            Spacer()
                            
                            Button(action: { storageAnalytics.clearCache() }) {
                                Label("Clear Temporary Cache", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                            .foregroundColor(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Software Updates & Releases Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                .font(.title3)
                                .foregroundColor(.cyan)
                            Text("Software Updates & Releases")
                                .font(.title3)
                                .bold()
                            Spacer()
                            
                            Button(action: {
                                updater.checkForUpdates()
                            }) {
                                HStack(spacing: 6) {
                                    if updater.status == .checking {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text(updater.status == .checking ? "Checking..." : "Check for Updates")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                            .disabled(updater.status == .checking)
                        }
                        
                        switch updater.status {
                        case .idle:
                            HStack {
                                Text("Current Version: v1.6.0 (Build 100)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: { showChangelogModal = true }) {
                                    Label("What's New in v1.6.0 (Changelog)", systemImage: "sparkles")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .buttonStyle(.bordered)
                                .tint(.cyan)
                                
                                if let lastDate = updater.lastCheckedDate {
                                    Text("Last checked: \(lastDate.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        case .checking:
                            Text("Querying GitHub API for latest MacAuraLive release...")
                                .font(.caption)
                                .foregroundColor(.cyan)
                        case .upToDate(let ver):
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("MacAuraLive is up to date! (v\(ver))")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.green)
                                Spacer()
                                if let lastDate = updater.lastCheckedDate {
                                    Text("Checked: \(lastDate.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        case .updateAvailable(let newVer, let notes, let downloadUrl):
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.purple)
                                    Text("New Update Available: v\(newVer)!")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.purple)
                                    Spacer()
                                    
                                    Button("Download v\(newVer) Installer") {
                                        updater.openDownloadPage(url: downloadUrl)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.purple)
                                }
                                
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(4)
                            }
                            .padding(12)
                            .background(Color.purple.opacity(0.12))
                            .cornerRadius(10)
                        case .error(let msg):
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(msg)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // About MacAuraLive, Licensing & TOS Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            ZStack {
                                if let appIcon = NSImage(named: "AppIcon") {
                                    Image(nsImage: appIcon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 54, height: 54)
                                        .cornerRadius(12)
                                } else {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 54, height: 54)
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("MacAuraLive Live Wallpaper Engine")
                                    .font(.title2)
                                    .bold()
                                Text("v1.6.0 (Build 100) • Production Release • Apple Silicon (ARM64)")
                                    .font(.caption)
                                    .foregroundColor(.cyan)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            
                            Button {
                                showOnboardingWizard = true
                            } label: {
                                Label("Setup Wizard", systemImage: "wand.and.stars")
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("App Version:").bold().font(.caption)
                                Text("1.6.0 (Build 100)").font(.caption).foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Architecture:").bold().font(.caption)
                                Text("Apple Silicon Native (ARM64)").font(.caption).foregroundColor(.secondary)
                            }
                            HStack {
                                Text("macOS Compatibility:").bold().font(.caption)
                                Text("macOS 13.0 (Ventura) or later").font(.caption).foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Rendering Engine:").bold().font(.caption)
                                Text("Metal 3, WebGL 2.0, AVFoundation, WebKit JS").font(.caption).foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Privacy Policy:").bold().font(.caption)
                                Text("100% On-Device Processing. Zero Cloud Telemetry.").font(.caption).foregroundColor(.green)
                            }
                        }
                        
                        HStack(spacing: 10) {
                            Button("Terms of Service") {
                                showTOSModal = true
                            }
                            .buttonStyle(.bordered)
                            
                            Button("MIT License") {
                                showLicenseModal = true
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Disclaimer") {
                                showDisclaimerModal = true
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                if let url = URL(string: "https://github.com/ASKHOPE/MacAuraLive") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Label("Visit Repo", systemImage: "link")
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                            
                            Button(action: { showChangelogModal = true }) {
                                Label("Changelog", systemImage: "doc.plaintext.fill")
                            }
                            .buttonStyle(.bordered)
                            .tint(.purple)
                            
                            Spacer()
                            
                            Text("© 2026 MacAuraLive")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
        .sheet(isPresented: $showTOSModal) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("MacAuraLive Terms of Service & Use")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button("Close") { showTOSModal = false }
                }
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("1. Acceptance & Agreement")
                            .font(.headline)
                        Text("By downloading, installing, running, or using MacAuraLive Live Wallpaper ('Software'), you expressly acknowledge and agree to be bound by these Terms of Service. If you do not agree to all terms, you are not authorized to install or use this Software.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("2. Privacy & 100% Local On-Device Processing")
                            .font(.headline)
                        Text("MacAuraLive is engineered with strict privacy principles. All video loops, WebGL canvas shaders, and user preferences are executed and stored 100% locally in your Mac's RAM and file system. MacAuraLive collects zero analytics, telemetry, personal identifier data, or usage logs, and never transmits data to any external server or cloud service.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("3. Permitted Personal Use & Copyright Responsibility")
                            .font(.headline)
                        Text("MacAuraLive is provided solely for personal, non-commercial desktop customization. You are solely responsible for ensuring that any third-party video, audio, GIF, or image assets you import into the software comply with applicable intellectual property and copyright laws.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("4. Software Modifications & Updates")
                            .font(.headline)
                        Text("The developers reserve the right to modify, suspend, or discontinue any feature, preview build, or component of the Software at any time without prior notice or liability.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .padding()
            .frame(width: 540, height: 460)
        }
        .sheet(isPresented: $showLicenseModal) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Software License & End User License Agreement (EULA)")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button("Close") { showLicenseModal = false }
                }
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Open-Source License Grant (MIT)")
                            .font(.headline)
                        Text("MacAuraLive source code and binaries are released under the MIT License. You are granted a free, worldwide, royalty-free license to use, study, modify, merge, publish, distribute, sublicense, and sell copies of the software, subject to the conditions set forth in the LICENSE file.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Third-Party Media & Content Platform Licenses")
                            .font(.headline)
                        Text("Bundled video loops and static wallpapers are credited and used under their respective creator licenses (Pixabay Content License, Unsplash License, NASA Public Domain). See THIRD_PARTY_LICENSES.md for full author credits and attribution links.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Native Apple Frameworks")
                            .font(.headline)
                        Text("MacAuraLive is built using native Apple macOS subsystems including SwiftUI, AppKit, AVFoundation, WebKit, CryptoKit, and Security.framework.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .padding()
            .frame(width: 540, height: 460)
        }
        .sheet(isPresented: $showDisclaimerModal) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Legal Disclaimers & Hardware Liability Waiver")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button("Close") { showDisclaimerModal = false }
                }
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("1. EXCLUSION OF HARDWARE & SOFTWARE LIABILITY")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("IN NO EVENT SHALL MACAURA, ITS DEVELOPERS, AUTHORS, OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING BUT NOT LIMITED TO HARDWARE DAMAGE, OVERHEATING, THERMAL DEGRADATION, BATTERY DRAIN, DISPLAY BURN-IN, SYSTEM INSTABILITY, LOSS OF DATA, OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE INSTALLATION, OPERATION, OR USE OF THIS SOFTWARE.")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Text("2. 'AS IS' & 'AS AVAILABLE' WARRANTY DISCLAIMER")
                            .font(.headline)
                        Text("THE SOFTWARE IS PROVIDED 'AS IS' AND 'AS AVAILABLE' WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, ACCURACY, OR UNINTERRUPTED OPERATION. USER ASSUMES ALL RISKS ASSOCIATED WITH GPU/CPU RESOURCE UTILIZATION.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("3. Hardware & Battery Saver Best Practices")
                            .font(.headline)
                        Text("High-resolution video wallpapers (4K/8K loops) and continuous 60fps WebGL 3D shader runtimes naturally increase GPU energy consumption. Users operating MacBook laptops on battery power are strongly advised to enable 'Pause on Battery' in App Preferences.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("4. Third-Party Trademarks")
                            .font(.headline)
                        Text("Apple, macOS, Apple Music, ScreenCaptureKit, Metal, and Spotify are registered trademarks of Apple Inc. and Spotify AB. MacAuraLive is an independent software application and is not affiliated with, endorsed by, or sponsored by Apple Inc. or Spotify AB.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .padding()
            .frame(width: 540, height: 480)
        }
        .sheet(isPresented: $showChangelogModal) {
            ChangelogModalView(isPresented: $showChangelogModal)
        }
        .sheet(isPresented: $showOnboardingWizard) {
            OnboardingView(isPresented: $showOnboardingWizard)
        }
        .onChange(of: settings.wallpaperPlacement) { newPlacement in
            WallpaperEngine.shared.updatePlacementSettings(placement: newPlacement, zoom: settings.wallpaperZoom)
        }
        .onChange(of: settings.wallpaperZoom) { newZoom in
            WallpaperEngine.shared.updatePlacementSettings(placement: settings.wallpaperPlacement, zoom: newZoom)
        }
    }
    
    private func openReferenceFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let folderURL = panel.url {
            WallpaperStorageManager.shared.referencedFolderURL = folderURL.path
            let count = WallpaperStorageManager.shared.importFolderWallpapers(folderURL: folderURL)
            engine.reloadEngine()
            syncStatusMessage = "Monitored folder set. Imported \(count) file(s)."
        }
    }
    
    private func colorForStorageItem(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "pink": return .pink
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "cyan": return .cyan
        default: return .secondary
        }
    }
}

// MARK: - Dedicated Secure API Key Card Row Component
struct APIKeyCardRow: View {
    let title: String
    let subtitle: String
    let iconName: String
    let iconColor: Color
    let placeholder: String
    @Binding var key: String
    let helpUrl: String?
    
    @State private var isRevealed: Bool = false
    @State private var tempKey: String = ""
    @State private var showSavedBanner: Bool = false
    @State private var isTesting: Bool = false
    @State private var testFeedback: (Bool, String)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerView
            inputRowView
            if let feedback = testFeedback {
                feedbackBannerView(isSuccess: feedback.0, message: feedback.1)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            tempKey = key
        }
        .onChange(of: key) { newKey in
            tempKey = newKey
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    
                    if !key.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 8))
                            Text("CONFIGURED")
                        }
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    } else {
                        Text("OPTIONAL / UNSET")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.secondary)
                            .cornerRadius(4)
                    }
                }
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let urlString = helpUrl, let url = URL(string: urlString) {
                Link("Get Key ↗", destination: url)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var inputRowView: some View {
        HStack(spacing: 8) {
            HStack {
                if isRevealed {
                    TextField(placeholder, text: $tempKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                } else {
                    SecureField(placeholder, text: $tempKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                }
                
                Button(action: { isRevealed.toggle() }) {
                    Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.black.opacity(0.25))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            
            // Save Key
            Button(action: saveAction) {
                HStack(spacing: 4) {
                    Image(systemName: showSavedBanner ? "checkmark" : "square.and.arrow.down.fill")
                    Text(showSavedBanner ? "Saved!" : "Save Key")
                }
                .font(.caption)
                .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(showSavedBanner ? .green : .blue)
            .controlSize(.regular)
            .disabled(tempKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            // Test Key
            Button(action: testAction) {
                HStack(spacing: 4) {
                    if isTesting {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                    }
                    Text(isTesting ? "Testing..." : "Test Key")
                }
                .font(.caption)
                .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .tint(.green)
            .controlSize(.regular)
            .disabled(tempKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)
            
            // Clear Key
            Button(action: {
                tempKey = ""
                key = ""
                testFeedback = nil
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                    Text("Clear")
                }
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(key.isEmpty && tempKey.isEmpty)
        }
    }
    
    private func feedbackBannerView(isSuccess: Bool, message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isSuccess ? .green : .orange)
            Text(message)
                .font(.caption2)
                .foregroundColor(isSuccess ? .green : .orange)
                .lineLimit(2)
            Spacer()
            Button(action: { testFeedback = nil }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background((isSuccess ? Color.green : Color.orange).opacity(0.12))
        .cornerRadius(6)
    }
    
    private func saveAction() {
        let clean = tempKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            testFeedback = (false, "Cannot save empty key.")
            return
        }
        key = clean
        testFeedback = (true, "Key saved securely to Keychain.")
        withAnimation {
            showSavedBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showSavedBanner = false
            }
        }
    }
    
    private func testAction() {
        let clean = tempKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            testFeedback = (false, "Please enter an API key before testing.")
            return
        }
        isTesting = true
        testFeedback = nil
        
        AIGenerationManager.shared.validateAPIKey(provider: title, apiKey: clean, endpoint: "", model: "") { result in
            DispatchQueue.main.async {
                isTesting = false
                switch result {
                case .success(let msg):
                    testFeedback = (true, msg)
                case .failure(let err):
                    testFeedback = (false, err.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Changelog / What's New Release Notes Modal Component
struct ChangelogModalView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.purple)
                    Text("MacAuraLive Release Notes & Changelog")
                        .font(.title2)
                        .bold()
                }
                Spacer()
                Button("Done") { isPresented = false }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Version 1.6.0
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Version 1.6.0 (Current Release)")
                                .font(.headline)
                                .bold()
                            Spacer()
                            Text("2026-08-14")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.25))
                                .foregroundColor(.purple)
                                .cornerRadius(6)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Native Static Wallpaper Rendering: High-performance CoreGraphics/Metal drawing with zero layout artifacts.")
                            Text("• Default Original Resolution (macOS Native): Renders wallpapers in original 1:1 pixel dimensions and aspect ratios without forced zoom or stretch.")
                            Text("• Sizing & Aspect Ratio Quick Controls: Instant Sizing and Crop selector in Gallery and Full Preview modals.")
                            Text("• Live Wallpaper Acceleration: Removed background preview WebViews from gallery cards, restoring 60 FPS performance to desktop shaders.")
                            Text("• Real-Time Playback Speed Slider: Fluid 0.25x to 3.0x speed control in the sidebar footer.")
                            Text("• API Key Validation & Live Testing: Test Key, Save Key, and Clear Key action controls across all AI Workshop providers.")
                            Text("• Dedicated In-Built Storage Analytics Card: Live disk footprint breakdown in Settings.")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Version 1.2.0
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Version 1.2.0")
                                .font(.headline)
                                .bold()
                            Spacer()
                            Text("2026-08-11")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Dynamic User Guide & Documentation viewer built directly into app.")
                            Text("• Web Wallpaper Engine Polyfill SDK for Javascript interoperability.")
                            Text("• Local sandbox document directory routing (~/Documents/MacAuraLiveApp/).")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(12)
                    
                    // Version 1.0.0
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Version 1.0.0 (Initial Release)")
                                .font(.headline)
                                .bold()
                            Spacer()
                            Text("2026-08-01")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Official release of MacAuraLive Wallpaper Engine for Apple Silicon.")
                            Text("• Video (mp4), Web/HTML5 shaders, Static Images (jpg/png), and GIFs.")
                            Text("• Custom Playlist / Slideshow Scheduler & Multi-Monitor support.")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(12)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(24)
        .frame(width: 580, height: 500)
    }
}

// MARK: - Storage Breakdown UI Components
struct StorageSegmentBarView: View {
    let categories: [StorageCategoryItem]
    let totalBytes: Int64
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(categories) { item in
                    let pct = totalBytes > 0 ? Double(item.sizeBytes) / Double(totalBytes) : 0
                    if pct > 0.005 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(colorForStorageItem(item.colorName))
                            .frame(width: max(4.0, geo.size.width * CGFloat(pct)))
                    }
                }
            }
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(6)
    }
    
    private func colorForStorageItem(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "pink": return .pink
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "cyan": return .cyan
        default: return .secondary
        }
    }
}

struct StorageCategoryPillView: View {
    let item: StorageCategoryItem
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(colorForStorageItem(item.colorName))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.name)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text(item.formattedSize)
                        .font(.caption)
                        .bold()
                        .monospacedDigit()
                }
                
                Text(String(format: "%.1f%% of total", percentage))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
    
    private func colorForStorageItem(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "pink": return .pink
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "cyan": return .cyan
        default: return .secondary
        }
    }
}
