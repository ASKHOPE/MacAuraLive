import SwiftUI

public struct UserGuideView: View {
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("User Guide & Documentation")
                    .font(.system(size: 28, weight: .bold))
                Text("Complete manual for managing live wallpapers, lock screen, schedules, and permissions.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Guide Section 1: Quick Start
                    GuideCard(
                        icon: "play.circle.fill",
                        color: .blue,
                        title: "1. Quick Start & Applying Wallpapers",
                        description: "How to activate live video, WebGL shaders, or static wallpapers.",
                        content: """
                        • Browse the 'Live Wallpapers' or 'Static Wallpapers' tab in the left sidebar.
                        • Hover over any wallpaper card and click 'Apply Wallpaper'.
                        • The live engine will immediately render the wallpaper on your desktop underneath your Finder desktop icons.
                        • Adjust audio volume, mute status, or playback speed (0.25x - 2.0x) from the sidebar controls widget.
                        """
                    )
                    
                    // Guide Section 2: Lock Screen Wallpaper
                    GuideCard(
                        icon: "lock.rectangle.on.rectangle.fill",
                        color: .purple,
                        title: "2. Lock Screen Wallpaper Setup",
                        description: "Set an independent static image for your macOS Lock Screen.",
                        content: """
                        • Open the 'Lock Screen' tab.
                        • Click 'Browse Image…' to select any photo from your Mac, or select a static image from your MacAura library.
                        • Click 'Set as Lock Screen Wallpaper'.
                        • macOS lock screen mirrors your desktop wallpaper — your static image will display on lock screen, while keeping your live wallpaper active on desktop!
                        """
                    )
                    
                    // Guide Section 3: Slideshow & Timed Schedules
                    GuideCard(
                        icon: "clock.arrow.2.circlepath",
                        color: .cyan,
                        title: "3. Slideshow & Scheduled Rotation",
                        description: "Automate wallpaper rotation on timers or specific times of day.",
                        content: """
                        • Interval Slideshow: Toggle 'Interval Slideshow Engine' ON, set your rotation frequency (5 min, 15 min, 1 hour, etc.), and optional Shuffle mode.
                        • Custom Playlist: Use the 'Slideshow Playlist Selection' image picker with Search and Zoom Slider to select which wallpapers rotate.
                        • Time-of-Day Schedules: Click 'Add Time Rule' to set specific wallpapers for exact times (e.g., Morning Sunrise at 08:00, Night Cosmos at 22:00).
                        """
                    )
                    
                    // Guide Section 4: Multi-Monitor Displays
                    GuideCard(
                        icon: "desktopcomputer",
                        color: .green,
                        title: "4. Multi-Monitor & Display Spanning",
                        description: "Configure wallpaper behavior across multiple screens.",
                        content: """
                        • Per-Display Assignment: Open the 'Displays' tab to assign different live wallpapers to individual monitors.
                        • Ultra-Wide Spanning: Enable 'Span Live Wallpaper Across All Connected Displays' in Settings to stretch a single live wallpaper continuously across all connected screens.
                        """
                    )
                    
                    // Guide Section 5: Troubleshooting & Permissions
                    GuideCard(
                        icon: "exclamationmark.shield.fill",
                        color: .orange,
                        title: "5. Troubleshooting & Permissions",
                        description: "Permissions guidance and performance tips.",
                        content: """
                        • Screen Recording Permission: Required for full-screen application detection so MacAura can pause and give 100% GPU to games or video editors.
                        • Launch at Login: Enable in Settings to launch MacAura silently in your menu bar on system boot.
                        • Menu Bar Icon: Click the MacAura icon in your macOS status bar for quick play/pause, volume control, or 'Open Dashboard'.
                        """
                    )
                }
                .padding(.bottom, 20)
            }
        }
    }
}

private struct GuideCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3)
                        .bold()
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            Text(content)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
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
