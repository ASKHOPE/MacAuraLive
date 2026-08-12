import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var engine = WallpaperEngine.shared
    @ObservedObject var storage = WallpaperStorageManager.shared
    
    @State private var syncStatusMessage: String? = nil
    @State private var showTOSModal: Bool = false
    @State private var showLicenseModal: Bool = false
    @State private var showDisclaimerModal: Bool = false

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
                        
                        Toggle(isOn: $settings.launchAtLogin) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Launch MacAura on System Startup / Login")
                                    .font(.body)
                                Text("Automatically starts MacAura and restores your active live wallpaper when macOS boots.")
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
                    
                    // Wallpaper Placement & Scaling Options Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Wallpaper Placement & Scaling")
                            .font(.title3)
                            .bold()
                        
                        Text("Configure how static images, video loops, and live WebGL wallpapers fit your desktop displays.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Placement Mode", selection: $settings.wallpaperPlacement) {
                            Text("Fill Screen (Aspect Cover)").tag("fill")
                            Text("Fit to Screen (Aspect Contain)").tag("fit")
                            Text("Stretch to Fill Screen").tag("stretch")
                            Text("Center (Original Size)").tag("center")
                            Text("Custom Zoom Level").tag("zoom")
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
                                
                                Slider(value: $settings.wallpaperZoom, in: 0.5...2.5, step: 0.05)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Display & Spanning Configuration Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Multi-Monitor & Lock Screen Settings")
                                .font(.title3)
                                .bold()
                            Spacer()
                            Text("ALPHA - TESTING")
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(6)
                        }
                        
                        Toggle(isOn: $settings.spanAcrossDisplays) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Span Live Wallpaper Across All Connected Displays")
                                    .font(.body)
                                Text("Stretches a single ultra-wide 4K/8K live wallpaper across multiple monitors without black screens.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Toggle(isOn: $settings.enableLockScreenWallpaper) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Live Wallpaper on macOS Lock Screen")
                                    .font(.body)
                                Text("Maintains 60fps live wallpaper rendering when your screen is locked.")
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
                    
                    // Default Application Directories Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                            Text("Default MacAura Document Directories")
                                .font(.title3)
                                .bold()
                            Spacer()
                            Text("Documents/MacauraApp")
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                        
                        Text("MacAura automatically maintains the following folder structure inside your macOS Documents directory:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill").foregroundColor(.blue)
                                Text("~/Documents/MacauraApp/").bold().font(.subheadline)
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
                            Button("Open MacauraApp in Finder") {
                                if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                                    let path = docs.appendingPathComponent("MacauraApp")
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
                        
                        Text("Select a local folder (e.g., ~/Movies/Wallpapers). MacAura will continuously monitor and auto-import all MP4, GIF, and Image wallpapers.")
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
                        
                        Text("Early access features (Lock Screen Wallpaper & AI Configuration) are protected by Admin Passcode.")
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
                    
                    // About MacAura, Licensing & TOS Card
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
                                Text("MacAura Live Wallpaper")
                                    .font(.title2)
                                    .bold()
                                Text("Version 1.0.0 (Build 1) • Apple Silicon Native")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Developer & Author:").bold().font(.caption)
                                Text("MacAura Team & Open Source Contributors").font(.caption).foregroundColor(.secondary)
                            }
                            HStack {
                                Text("macOS Compatibility:").bold().font(.caption)
                                Text("macOS 13.0 (Ventura) or later").font(.caption).foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Rendering Engines:").bold().font(.caption)
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
                            
                            Button("Licenses & EULA") {
                                showLicenseModal = true
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Legal Disclaimers") {
                                showDisclaimerModal = true
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Text("© 2026 MacAura")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
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
                    Text("MacAura Terms of Service & Use")
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
                        Text("By downloading, installing, running, or using MacAura Live Wallpaper ('Software'), you expressly acknowledge and agree to be bound by these Terms of Service. If you do not agree to all terms, you are not authorized to install or use this Software.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("2. Privacy & 100% Local On-Device Processing")
                            .font(.headline)
                        Text("MacAura is engineered with strict privacy principles. All video loops, WebGL canvas shaders, and user preferences are executed and stored 100% locally in your Mac's RAM and file system. MacAura collects zero analytics, telemetry, personal identifier data, or usage logs, and never transmits data to any external server or cloud service.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("3. Permitted Personal Use & Copyright Responsibility")
                            .font(.headline)
                        Text("MacAura is provided solely for personal, non-commercial desktop customization. You are solely responsible for ensuring that any third-party video, audio, GIF, or image assets you import into the software comply with applicable intellectual property and copyright laws.")
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
                        Text("End User License Agreement (EULA)")
                            .font(.headline)
                        Text("MacAura Live Wallpaper is licensed, not sold. Subject to your compliance with this Agreement, you are granted a non-exclusive, non-transferable, revocable license to install and execute the Software on compatible macOS devices owned or controlled by you.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Open-Source & Platform Framework Acknowledgments")
                            .font(.headline)
                        Text("MacAura incorporates native macOS and open-source rendering technologies:\n• Apple Accelerate Framework (vDSP FFT real-time DSP processing)\n• Apple ScreenCaptureKit & AVFoundation (Native macOS Media Subsystems)\n• WebGL 2.0 & Three.js Canvas Shader Runtimes (MIT License)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Restrictions")
                            .font(.headline)
                        Text("You may not reverse-engineer, decompile, disassemble, rent, lease, distribute, or create derivative commercial works based upon MacAura except as expressly permitted under open-source license components.")
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
                        Text("Apple, macOS, Apple Music, ScreenCaptureKit, Metal, and Spotify are registered trademarks of Apple Inc. and Spotify AB. MacAura is an independent software application and is not affiliated with, endorsed by, or sponsored by Apple Inc. or Spotify AB.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .padding()
            .frame(width: 540, height: 480)
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
}
