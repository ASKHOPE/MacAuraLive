import SwiftUI

public struct LockScreenView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var lockManager = LockScreenManager.shared
    @ObservedObject var storage = WallpaperStorageManager.shared
    @ObservedObject var engine = WallpaperEngine.shared
    
    @State private var currentTimeString: String = ""
    @State private var currentDateString: String = ""
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
