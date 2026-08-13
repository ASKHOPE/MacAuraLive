import SwiftUI
import AppKit

public struct OnboardingView: View {
    @ObservedObject var settings = AppSettings.shared
    @Binding var isPresented: Bool
    
    @State private var currentStep: Int = 1
    @State private var hasScreenRecordingPermission: Bool = false
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Bar / Progress indicator
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.blue : Color.white.opacity(0.15))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 24)
            
            Spacer()
            
            // Step Content
            switch currentStep {
            case 1:
                welcomeStep
            case 2:
                permissionsStep
            default:
                completeStep
            }
            
            Spacer()
            
            // Bottom Action Bar
            HStack {
                if currentStep > 1 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentStep < 3 {
                    Button("Continue") {
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                } else {
                    Button("Get Started with MacAuraLive") {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 24)
        }
        .frame(width: 580, height: 440)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            checkPermissions()
        }
    }
    
    // MARK: - Steps
    
    @ViewBuilder
    private var welcomeStep: some View {
        VStack(spacing: 18) {
            if let icon = NSImage(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(18)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
            }
            
            VStack(spacing: 6) {
                Text("Welcome to MacAuraLive")
                    .font(.system(size: 26, weight: .bold))
                Text("Hardware-accelerated live wallpapers for macOS.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                FeaturePointRow(icon: "play.rectangle.fill", color: .blue, title: "60 FPS Live Engine", subtitle: "Renders 4K videos & WebGL shaders directly on your desktop.")
                FeaturePointRow(icon: "lock.rectangle.on.rectangle.fill", color: .purple, title: "Lock Screen Wallpaper", subtitle: "Set custom static wallpapers for your macOS lock screen.")
                FeaturePointRow(icon: "clock.arrow.2.circlepath", color: .cyan, title: "Slideshow & Schedules", subtitle: "Automate wallpaper rotation on timers or time-of-day rules.")
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
        }
        .padding(.horizontal, 30)
    }
    
    @ViewBuilder
    private var permissionsStep: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Permissions & Setup")
                    .font(.system(size: 22, weight: .bold))
                Text("MacAuraLive uses system permissions for optimal performance.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 14) {
                // Permission 1: Screen Recording (for full screen detection)
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(hasScreenRecordingPermission ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: hasScreenRecordingPermission ? "checkmark" : "rectangle.dashed.badge.record")
                            .foregroundColor(hasScreenRecordingPermission ? .green : .orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screen Recording Permission")
                            .font(.subheadline)
                            .bold()
                        Text("Allows MacAuraLive to detect full-screen apps and auto-pause to save battery & GPU.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(hasScreenRecordingPermission ? "Granted" : "Grant") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    .disabled(hasScreenRecordingPermission)
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                
                // Permission 2: App Location Check
                let isInApplications = Bundle.main.bundlePath.hasPrefix("/Applications")
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isInApplications ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: isInApplications ? "checkmark" : "folder.fill")
                            .foregroundColor(isInApplications ? .green : .blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Applications Folder")
                            .font(.subheadline)
                            .bold()
                        Text(isInApplications ? "MacAuraLive is installed in /Applications." : "Recommended: Move MacAuraLive to /Applications for auto-launch support.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                
                // Permission 3: Launch at Login
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(settings.launchAtLogin ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "power")
                            .foregroundColor(settings.launchAtLogin ? .green : .secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start MacAuraLive on System Login")
                            .font(.subheadline)
                            .bold()
                        Text("Automatically start your live wallpaper when macOS boots.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settings.launchAtLogin)
                        .toggleStyle(.switch)
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 30)
    }
    
    @ViewBuilder
    private var completeStep: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 6) {
                Text("Setup Complete!")
                    .font(.system(size: 24, weight: .bold))
                Text("MacAuraLive is ready to transform your desktop.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "menubar.arrow.up.rectangle")
                        .foregroundColor(.blue)
                    Text("MacAuraLive runs in your menu bar for quick access.")
                        .font(.caption)
                }
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("Explore WebGL Shaders, 4K Videos, and AI Generation.")
                        .font(.caption)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
        }
        .padding(.horizontal, 30)
    }
    
    private func checkPermissions() {
        if #available(macOS 10.15, *) {
            hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
        }
    }
}

private struct FeaturePointRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
