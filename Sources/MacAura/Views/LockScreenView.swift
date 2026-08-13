import SwiftUI

public struct LockScreenView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var lockManager = LockScreenManager.shared
    @ObservedObject var storage = WallpaperStorageManager.shared
    @ObservedObject var engine = WallpaperEngine.shared
    
    @State private var currentTimeString: String = ""
    @State private var currentDateString: String = ""
    @State private var showSnapshotConfirm: Bool = false
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    public init() {}

    public var selectedLockWallpaper: WallpaperItem? {
        storage.wallpapers.first(where: { $0.id == settings.lockScreenWallpaperId }) ?? storage.getActiveWallpaper()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Lock Screen Live Wallpaper")
                    .font(.system(size: 28, weight: .bold))
                Text("Customize your live wallpaper animation for macOS lock screen and user switching sessions.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Live Lock Screen Preview Card
            ZStack {
                // Background Wallpaper Preview Card
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    if let wp = selectedLockWallpaper {
                        VStack(spacing: 8) {
                            Image(systemName: wp.thumbnailIcon)
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(radius: 8)
                            Text(wp.title)
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                            Text(wp.category + " • " + wp.resolutionTag)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .frame(height: 220)

                // Simulated macOS Lock Screen Clock & User Profile Overlay
                VStack(spacing: 6) {
                    Spacer()
                    Text(currentTimeString.isEmpty ? "12:34" : currentTimeString)
                        .font(.system(size: 48, weight: .thin, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)
                    
                    Text(currentDateString.isEmpty ? "Thursday, August 13" : currentDateString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 16))
                        Text("macOS Lock Screen Session")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .onReceive(timer) { _ in
                updateTimeAndDate()
            }
            .onAppear {
                updateTimeAndDate()
            }
            
            // Lock Screen Configuration Options
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Live Wallpaper on Lock Screen")
                            .font(.headline)
                        Text("Maintains live video or shader playback when macOS locks.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $settings.enableLockScreenWallpaper)
                        .toggleStyle(.switch)
                }
                
                if settings.enableLockScreenWallpaper {
                    Divider()
                    
                    HStack(spacing: 16) {
                        Text("Lock Screen Wallpaper:")
                            .font(.subheadline)
                            .bold()
                        
                        Picker("", selection: $settings.lockScreenWallpaperId) {
                            ForEach(storage.wallpapers) { item in
                                Text(item.title).tag(item.id)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(minWidth: 220)
                        
                        Button("Sync with Desktop Wallpaper") {
                            settings.lockScreenWallpaperId = storage.activeWallpaperId
                            engine.reloadEngine()
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // How Lock Screen Works – Info Card
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.cyan)
                        .font(.title3)
                    Text("How Lock Screen Wallpaper Works")
                        .font(.headline)
                        .bold()
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    FeatureRow(
                        icon: "display",
                        iconColor: .blue,
                        title: "While Unlocked",
                        description: "Full live animated wallpaper plays on your desktop at the desktop window layer."
                    )
                    FeatureRow(
                        icon: "lock.fill",
                        iconColor: .purple,
                        title: "On Screen Lock",
                        description: "MacAura elevates the wallpaper window to the screen-saver layer, then captures the current frame as a PNG and sets it as your system desktop wallpaper. macOS lock screen automatically mirrors the desktop wallpaper."
                    )
                    FeatureRow(
                        icon: "lock.open.fill",
                        iconColor: .green,
                        title: "On Unlock",
                        description: "The live engine resumes at full quality on the desktop layer."
                    )
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                
                // Note about macOS limitation
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Note: Apple does not provide a public API to display custom video on the lock screen password overlay. The snapshot approach gives the best visual match possible.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Test Snapshot Button
                HStack(spacing: 12) {
                    Button {
                        lockManager.captureAndSetDesktopSnapshot()
                        showSnapshotConfirm = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showSnapshotConfirm = false
                        }
                    } label: {
                        Label("Test: Snapshot Current Wallpaper", systemImage: "camera.viewfinder")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    
                    if showSnapshotConfirm {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Done! Lock your screen to see it.")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .transition(.opacity)
                    }
                    
                    Spacer()
                }
                
                if !lockManager.snapshotStatus.isEmpty {
                    Text(lockManager.snapshotStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: showSnapshotConfirm)
            
            Spacer()
        }
    }
    
    private func updateTimeAndDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        currentTimeString = formatter.string(from: Date())
        
        let dateForm = DateFormatter()
        dateForm.dateFormat = "EEEE, MMMM d"
        currentDateString = dateForm.string(from: Date())
    }
}

// MARK: - Supporting View

private struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}
