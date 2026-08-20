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
                MacaRetroToggle("", isOn: $settings.spanAcrossDisplays)
            }
            .padding(18)
            .macaCardStyle(cornerRadius: 14)
            
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
                RoundedRectangle(cornerRadius: settings.appTheme == "classic" ? 4 : 12)
                    .fill(
                        settings.appTheme == "classic"
                            ? MacaThemeTokens.classicSubcardBg
                            : Color.blue.opacity(0.35)
                    )
                    .frame(width: 150, height: 95)
                    .overlay(
                        RoundedRectangle(cornerRadius: settings.appTheme == "classic" ? 4 : 12)
                            .stroke(settings.appTheme == "classic" ? MacaThemeTokens.classicBorder : Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                VStack(spacing: 6) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 28))
                        .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextDark : .white)
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
                            .background(settings.appTheme == "classic" ? MacaThemeTokens.classicOlive : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(settings.appTheme == "classic" ? 3 : 6)
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
        .macaCardStyle(cornerRadius: 16)
    }
}
