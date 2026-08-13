import SwiftUI

public struct DisplayManagerView: View {
    @ObservedObject var engine = WallpaperEngine.shared
    @ObservedObject var storage = WallpaperStorageManager.shared
    @ObservedObject var settings = AppSettings.shared
    
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header Section
            VStack(alignment: .leading, spacing: 6) {
                Text("Connected Displays")
                    .font(.system(size: 28, weight: .bold))
                Text("Configure per-monitor live wallpapers or span a single background across all screens.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Mirroring / Span Mode Card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Span Wallpaper Across Displays")
                        .font(.headline)
                    Text("Apply active wallpaper across all connected displays simultaneously.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $settings.spanAcrossDisplays)
                    .toggleStyle(.switch)
            }
            .padding(18)
            .background(Color.white.opacity(0.06))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            Text("Active Monitors (\(engine.displays.count))")
                .font(.title3)
                .bold()
                .padding(.top, 8)
            
            ScrollView {
                VStack(spacing: 18) {
                    ForEach(engine.displays) { display in
                        DisplayCardView(display: display)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

public struct DisplayCardView: View {
    let display: DisplayInfo
    @ObservedObject var engine = WallpaperEngine.shared
    @ObservedObject var storage = WallpaperStorageManager.shared
    @ObservedObject var settings = AppSettings.shared

    private var currentSelectionBinding: Binding<String> {
        Binding(
            get: { engine.getWallpaperIdForDisplay(displayID: display.id) },
            set: { newId in
                engine.setWallpaperForDisplay(displayID: display.id, wallpaperID: newId)
            }
        )
    }

    public var body: some View {
        HStack(spacing: 24) {
            // Monitor Icon Card
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.35), Color.purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 150, height: 95)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                VStack(spacing: 6) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                    Text(display.resolutionCategory)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            // Monitor Details & Picker
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(display.name)
                        .font(.title3)
                        .bold()
                    
                    if display.isMain {
                        Text("MAIN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
                
                Text(display.resolutionString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !settings.spanAcrossDisplays {
                    HStack(spacing: 12) {
                        Text("Assigned Wallpaper:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: currentSelectionBinding) {
                            ForEach(storage.wallpapers) { wp in
                                Text(wp.title).tag(wp.id)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(minWidth: 200)
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
