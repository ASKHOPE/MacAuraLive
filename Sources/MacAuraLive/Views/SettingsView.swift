import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var engine = WallpaperEngine.shared
    @ObservedObject var storage = WallpaperStorageManager.shared
    @ObservedObject var updater = UpdateManager.shared
    @ObservedObject var storageAnalytics = StorageAnalyticsManager.shared
    @ObservedObject var duplicateFinder = DuplicateFinderManager.shared
    @ObservedObject var backupManager = SettingsBackupManager.shared
    
    @State private var syncStatusMessage: String? = nil
    @State private var showTOSModal: Bool = false
    @State private var showLicenseModal: Bool = false
    @State private var showDisclaimerModal: Bool = false
    @State private var showChangelogModal: Bool = false
    @State private var showOnboardingWizard: Bool = false
    @State private var showResetMediaAlert: Bool = false
    @State private var showResetPreferencesAlert: Bool = false
    @State private var showFactoryResetAlert: Bool = false
    @State private var resetStatusBanner: String? = nil

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title Header
            VStack(alignment: .leading, spacing: 6) {
                Text("App Preferences & Settings")
                    .font(.system(size: 28, weight: .bold))
                Text("Configure startup, appearance, multi-monitor display spanning, and storage.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    systemLaunchCard
                    appThemeCard
                    wallpaperPlacementCard
                    displaySpanningCard
                    directoriesCard
                    monitoredFolderCard
                    adminSecurityCard
                    performanceCard
                    marketplacePluginsCard
                    storageAnalyticsCard
                    softwareUpdatesCard
                    duplicateCleanerCard
                    settingsBackupCard
                    dataManagementResetCard
                    aboutAppCard
                }
            }
        }
        .alert("Reset Only Media & Wallpapers?", isPresented: $showResetMediaAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Media", role: .destructive) {
                storage.resetWallpapersLibrary()
                storageAnalytics.calculateStorage()
                resetStatusBanner = "Media library restored to factory bundled defaults. Preferences kept intact."
            }
        } message: {
            Text("This will delete all custom imported video loops, static photos, and GIF files from ~/Library/Application Support/MacAuraLive/Media/ and restore all bundled wallpapers without changing any settings.")
        }
        .alert("Reset Only Preferences?", isPresented: $showResetPreferencesAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Preferences", role: .destructive) {
                storage.resetOnlyPreferences()
                resetStatusBanner = "All app preferences reset to factory defaults. Media library was preserved."
            }
        } message: {
            Text("This will restore default playback rate, display placement, audio volume, theme, and startup options without deleting any of your wallpapers.")
        }
        .alert("Full Factory Reset?", isPresented: $showFactoryResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Perform Full Reset", role: .destructive) {
                storage.performFullFactoryReset()
                storageAnalytics.calculateStorage()
                resetStatusBanner = "Full Factory Reset complete. All default wallpapers, settings, and caches have been restored to initial factory defaults."
            }
        } message: {
            Text("This will restore all original default wallpapers, clear imported media, reset all app preferences, and reinitialize all engines back to factory state.")
        }
        .sheet(isPresented: $showTOSModal) {
            tosModalView
        }
        .sheet(isPresented: $showLicenseModal) {
            licenseModalView
        }
        .sheet(isPresented: $showDisclaimerModal) {
            disclaimerModalView
        }
        .sheet(isPresented: $showChangelogModal) {
            changelogModalView
        }
        .sheet(isPresented: $showOnboardingWizard) {
            OnboardingView(isPresented: $showOnboardingWizard)
        }
    }
    
    // MARK: - Sub-Cards
    
    @ViewBuilder
    private var systemLaunchCard: some View {
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
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private var appThemeCard: some View {
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
            
            Toggle(isOn: $settings.enableTransparency) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable macOS Frosted Glass Vibrancy & Translucency")
                        .font(.body)
                    Text("Uses native NSVisualEffectView behind-window blur for an ultra-premium liquid macOS glass aesthetic.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
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
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private var wallpaperPlacementCard: some View {
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
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private var displaySpanningCard: some View {
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
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private var directoriesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                Text("Default MacAuraLive Media Directories")
                    .font(.title3)
                    .bold()
                Spacer()
                Text("Application Support/MacAuraLive/Media")
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
            
            Text("MacAuraLive automatically maintains native storage inside macOS Application Support (no Documents permission prompt needed):")
                .font(.caption)
                .foregroundColor(.secondary)
            
            FolderTreeHierarchyView()
            
            HStack {
                Spacer()
                Button("Open Media Folder in Finder") {
                    let path = WallpaperStorageManager.shared.documentsDirectory
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path.path)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private var monitoredFolderCard: some View {
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
                    .macaSubcardStyle(cornerRadius: 6)
                
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
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private var adminSecurityCard: some View {
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
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private var performanceCard: some View {
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
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private var marketplacePluginsCard: some View {
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
                APIKeyCardRow(
                    title: "Unsplash API Key",
                    subtitle: "Free 4K curated photography & ultra-HD static wallpapers",
                    iconName: "camera.fill",
                    iconColor: .blue,
                    placeholder: "Enter Unsplash Access Key",
                    key: $settings.unsplashApiKey,
                    helpUrl: "https://unsplash.com/developers"
                )
                
                APIKeyCardRow(
                    title: "Pixabay API Key",
                    subtitle: "Royalty-free HD/4K video motion loops & audio wallpapers",
                    iconName: "photo.stack.fill",
                    iconColor: .green,
                    placeholder: "Enter Pixabay API Key",
                    key: $settings.pixabayApiKey,
                    helpUrl: "https://pixabay.com/api/docs/"
                )
                
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
            .macaSubcardStyle(cornerRadius: 12)
            
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
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private var storageAnalyticsCard: some View {
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
                    
                Button(action: { storageAnalytics.calculateStorage() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .help("Recalculate storage breakdown")
            }
            
            Text("Live analytics of disk space occupied by compiled Metal code, built-in shaders, user wallpapers, and runtime cache.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            StorageSegmentBarView(
                categories: storageAnalytics.categories,
                totalBytes: storageAnalytics.totalSizeBytes
            )
            .frame(height: 12)
            
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
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private var softwareUpdatesCard: some View {
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
            
            renderUpdateStatusContent()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private func renderUpdateStatusContent() -> some View {
        switch updater.status {
        case .idle:
            HStack {
                Text("Current Version: \(AppVersion.current.fullVersionString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showChangelogModal = true }) {
                    Label("What's New (Changelog)", systemImage: "sparkles")
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
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Querying GitHub API for latest MacAuraLive release...")
                    .font(.caption)
                    .foregroundColor(.cyan)
            }
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
        case .updateAvailable(let newVer, let notes, _):
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("New Update Available: v\(newVer)!")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.purple)
                    Spacer()
                    
                    Button("Update Now (In-App)") {
                        updater.startInAppUpdate()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
                
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
            }
            .padding(14)
            .background(Color.purple.opacity(0.12))
            .cornerRadius(10)
        case .downloading(let progress, let written, let total):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Downloading Update...")
                        .font(.subheadline)
                        .bold()
                    Spacer()
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.caption)
                        .monospacedDigit()
                        .bold()
                    Button("Cancel") {
                        updater.cancelDownload()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                ProgressView(value: progress)
                    .tint(.purple)
                
                let writtenMB = Double(written) / (1024 * 1024)
                let totalMB = Double(total) / (1024 * 1024)
                Text(String(format: "%.1f MB / %.1f MB", writtenMB, max(writtenMB, totalMB)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color.purple.opacity(0.12))
            .cornerRadius(10)
        case .verifying:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Verifying update package integrity...")
                    .font(.caption)
                    .foregroundColor(.purple)
            }
            .padding(12)
            .background(Color.purple.opacity(0.12))
            .cornerRadius(10)
        case .readyToInstall(let dmgPath, let version):
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("v\(version) Ready to Install")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.green)
                    Text("Click to restart and apply update seamlessly.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Restart & Update") {
                    updater.installAndRelaunch(dmgPath: dmgPath)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(14)
            .background(Color.green.opacity(0.12))
            .cornerRadius(10)
        case .installing:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Installing update and preparing relaunch...")
                    .font(.subheadline)
                    .bold()
            }
            .padding(14)
            .background(Color.blue.opacity(0.12))
            .cornerRadius(10)
        case .error(let msg):
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.orange)
                Spacer()
                Button("Retry") {
                    updater.checkForUpdates()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(10)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var duplicateCleanerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "doc.on.doc.fill")
                    .font(.title3)
                    .foregroundColor(.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Duplicate Media Scanner & Cleaner")
                        .font(.title3)
                        .bold()
                    Text("Detect identical wallpaper files and reclaim wasted disk space.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                if duplicateFinder.isScanning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button(action: { duplicateFinder.scanForDuplicates() }) {
                        Label("Scan for Duplicates", systemImage: "sparkle.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .tint(.cyan)
                }
            }
            
            if let msg = duplicateFinder.scanMessage {
                HStack {
                    Image(systemName: duplicateFinder.duplicateGroups.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(duplicateFinder.duplicateGroups.isEmpty ? .green : .orange)
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(duplicateFinder.duplicateGroups.isEmpty ? .green : .orange)
                    Spacer()
                }
                .padding(10)
                .background((duplicateFinder.duplicateGroups.isEmpty ? Color.green : Color.orange).opacity(0.12))
                .cornerRadius(8)
            }
            
            if !duplicateFinder.duplicateGroups.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(duplicateFinder.duplicateGroups) { group in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.original.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("\(group.duplicates.count) duplicate copy found • \(group.formattedWastedSize) wasted")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Clean Duplicate") {
                                duplicateFinder.cleanDuplicates(in: group)
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            .font(.caption)
                        }
                        .padding(8)
                        .macaSubcardStyle(cornerRadius: 6)
                    }
                    
                    Button(role: .destructive, action: { duplicateFinder.cleanAllDuplicates() }) {
                        Label("Clean All Duplicates (Reclaim \(duplicateFinder.formattedTotalWastedSize))", systemImage: "trash.fill")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private var settingsBackupCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "arrow.up.arrow.down.square.fill")
                    .font(.title3)
                    .foregroundColor(.purple)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Settings Backup & Migration")
                        .font(.title3)
                        .bold()
                    Text("Export your settings to JSON or import an existing configuration.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            if let backupMsg = backupManager.statusMessage {
                HStack {
                    Image(systemName: backupManager.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(backupManager.isSuccess ? .green : .red)
                    Text(backupMsg)
                        .font(.caption)
                        .foregroundColor(backupManager.isSuccess ? .green : .red)
                    Spacer()
                }
                .padding(10)
                .background((backupManager.isSuccess ? Color.green : Color.red).opacity(0.12))
                .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                Button(action: { backupManager.exportSettings() }) {
                    Label("Export Settings (JSON)...", systemImage: "square.and.arrow.up")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                
                Button(action: { backupManager.importSettings() }) {
                    Label("Import Settings (JSON)...", systemImage: "square.and.arrow.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .macaCardStyle(cornerRadius: 14)
    }
    
    @ViewBuilder
    private var dataManagementResetCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)
                Text("Data Management & Reset")
                    .font(.title3)
                    .bold()
            }
            
            Text("Granular options to clear only imported media, reset only preferences, or perform a complete factory reset.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let banner = resetStatusBanner {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(banner)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.green)
                    Spacer()
                    Button("Dismiss") {
                        resetStatusBanner = nil
                    }
                    .font(.caption2)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                .padding(10)
                .background(Color.green.opacity(0.12))
                .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                Button(role: .destructive) {
                    showResetMediaAlert = true
                } label: {
                    Label("Reset Only Media", systemImage: "photo.stack")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                
                Button(role: .destructive) {
                    showResetPreferencesAlert = true
                } label: {
                    Label("Reset Only Preferences", systemImage: "gearshape.arrow.triangle.2.circlepath")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                
                Button(role: .destructive) {
                    showFactoryResetAlert = true
                } label: {
                    Label("Full Factory Reset...", systemImage: "exclamationmark.arrow.triangle.2.circlepath")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.red.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.red.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var aboutAppCard: some View {
        // Orion-style About panel layout
        HStack(alignment: .top, spacing: 24) {
            // Large app icon on the left
            ZStack {
                if let appIcon = NSImage(named: "AppIcon") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(
                            colors: [Color(hue: 0.75, saturation: 0.7, brightness: 0.9),
                                     Color(hue: 0.65, saturation: 0.8, brightness: 0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 4)

            // Right side: name, version, info, buttons
            VStack(alignment: .leading, spacing: 10) {
                // App name
                Text("MacAuraLive")
                    .font(.system(size: 22, weight: .bold))

                // Version line
                let appVersion = AppVersion.current.version
                let buildNumber = AppVersion.current.build
                VStack(alignment: .leading, spacing: 3) {
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)

                    Text("Universal 2 Native (Apple Silicon + Intel)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text("macOS 13.0 Ventura or later  •  Metal 3, WebKit, AVFoundation")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // Copyright + tagline
                Text("MacAuraLive by ASKHOPE. Copyright © 2026 MacAuraLive.\nAll rights reserved. Live your walls.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)

                // Action buttons row
                HStack(spacing: 8) {
                    Button {
                        showChangelogModal = true
                    } label: {
                        Text("What's New")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Button {
                        if let url = URL(string: "https://github.com/ASKHOPE/MacAuraLive/issues") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Text("Send Feedback")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Button {
                        showLicenseModal = true
                    } label: {
                        Text("Licenses")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .macaCardStyle(cornerRadius: 14)
    }
    
    // MARK: - Modals
    
    private var tosModalView: some View {
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
                }
                .padding(.vertical, 8)
            }
        }
        .padding(24)
        .frame(width: 580, height: 480)
    }
    
    private var licenseModalView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("MIT Open-Source License")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Close") { showLicenseModal = false }
            }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Copyright (c) 2026 MacAuraLive Contributors")
                        .font(.subheadline)
                        .bold()
                    
                    Text("""
                    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
                    
                    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
                    
                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                    """)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(24)
        .frame(width: 580, height: 420)
    }
    
    private var disclaimerModalView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Disclaimer & Hardware Compatibility")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Close") { showDisclaimerModal = false }
            }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Apple Inc. Trademark Disclaimer")
                        .font(.headline)
                    Text("MacAuraLive is an independent open-source software project. Apple, macOS, Mac, Metal, AVFoundation, and SwiftUI are trademarks of Apple Inc., registered in the U.S. and other countries. MacAuraLive is not affiliated with, endorsed by, or sponsored by Apple Inc.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("GPU & Battery Usage")
                        .font(.headline)
                    Text("Live wallpapers utilize hardware-accelerated video decoding (AVFoundation) and WebGL Metal rendering. While optimized for energy efficiency, continuous animated rendering uses more battery power than a static image. Enable 'Pause live wallpaper when on battery power' in Settings to conserve charge.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(24)
        .frame(width: 580, height: 420)
    }
    
    private var changelogModalView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MacAuraLive v1.8.0 Release Notes")
                        .font(.title2)
                        .bold()
                    Text("Build 120 • Production Release • Universal 2 (Apple Silicon & Intel)")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
                Spacer()
                Button("Done") { showChangelogModal = false }
                    .buttonStyle(.borderedProminent)
            }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🚀 Universal 2 & Multi-Architecture Release")
                            .font(.headline)
                            .foregroundColor(.pink)
                        Text("• Native compilation for both Apple Silicon (ARM64) and Intel (x86_64) Macs.\n• Stripped and minified binary footprint (~4.4 MB total).\n• Full macOS 13 (Ventura), 14 (Sonoma), and 15 (Sequoia) compatibility.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔍 Duplicate Media Scanner & 1-Click Cleaner")
                            .font(.headline)
                            .foregroundColor(.cyan)
                        Text("• Automated SHA-256 byte-level duplicate wallpaper scanner.\n• Identifies duplicate media files across library and calculates wasted space.\n• 1-Click batch clean action to reclaim disk storage.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💾 Settings Backup & Migration")
                            .font(.headline)
                            .foregroundColor(.purple)
                        Text("• Export all app settings, preferences, and display configurations to portable JSON.\n• 1-Click import to restore preferences on any Mac.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🎯 Granular Reset Controls & File Sizes")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("• Reset Only Media: Wipes imported files without touching preferences or API keys.\n• Multi-Select in Gallery with Select All, selection counter, and batch deletion.\n• Real-time file sizes shown on all wallpaper card footers and quick-look modals.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(24)
        .frame(width: 580, height: 500)
    }

    private func openReferenceFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Reference Folder"
        panel.message = "Choose a folder containing wallpapers to auto-sync with MacAuraLive"

        if panel.runModal() == .OK, let selectedURL = panel.url {
            let path = selectedURL.path
            storage.referencedFolderURL = path
            let count = storage.syncReferencedFolder()
            engine.reloadEngine()
            syncStatusMessage = "Reference folder set to \(selectedURL.lastPathComponent). Synced \(count) items."
        }
    }
}

// MARK: - Reusable Helper Views

struct APIKeyCardRow: View {
    let title: String
    let subtitle: String
    let iconName: String
    let iconColor: Color
    let placeholder: String
    @Binding var key: String
    let helpUrl: String
    
    @State private var isEditing: Bool = false
    @State private var tempKey: String = ""
    @State private var saveStatus: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption)
                        .bold()
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                if !key.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Active")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.green)
                    }
                }
                
                Button(action: {
                    if let url = URL(string: helpUrl) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("Get Free Key ↗")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 8) {
                if isEditing {
                    SecureField(placeholder, text: $tempKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    
                    Button("Save") {
                        key = tempKey
                        isEditing = false
                        saveStatus = "Saved!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            saveStatus = nil
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                    
                    Button("Cancel") {
                        isEditing = false
                        tempKey = ""
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                } else {
                    HStack {
                        Text(key.isEmpty ? "No API key configured (using public rate limits)" : "••••••••••••••••••••••••••••••••")
                            .font(.caption)
                            .foregroundColor(key.isEmpty ? .secondary : .primary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .macaSubcardStyle(cornerRadius: 6)
                    
                    Button(key.isEmpty ? "Set Key" : "Update") {
                        tempKey = key
                        isEditing = true
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    
                    if !key.isEmpty {
                        Button(role: .destructive) {
                            key = ""
                            saveStatus = "Cleared"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                saveStatus = nil
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
            }
            
            if let status = saveStatus {
                Text(status)
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding(10)
        .macaSubcardStyle(cornerRadius: 8)
    }
}

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
        .background(Color(NSColor.separatorColor).opacity(0.4))
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
        .macaSubcardStyle(cornerRadius: 8)
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

struct FolderTreeHierarchyView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "folder.fill").foregroundColor(.blue)
                Text("~/Library/Application Support/MacAuraLive/Media/").bold().font(.subheadline)
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
        .macaSubcardStyle(cornerRadius: 10)
    }
}
