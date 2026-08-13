# MacAuraLive — Live Wallpaper Engine for macOS

<p align="center">
  <img src="Sources/MacAuraLive/Resources/Assets/AppIcon.png" width="120" alt="MacAuraLive Icon"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013.0%2B-lightgrey?style=flat-square&logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.9%2F6.0-orange?style=flat-square&logo=swift" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%28ARM64%29-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" />
  <img src="https://img.shields.io/badge/Status-Active-purple?style=flat-square" />
</p>

> **MacAuraLive** is an open-source, hardware-accelerated live wallpaper engine for macOS — built entirely in Swift and SwiftUI, with zero external dependencies.

---

## ✨ Features
## 📸 Application User Interface Gallery

| 01. Live Wallpapers Gallery | 02. Static Wallpapers |
| :---: | :---: |
| ![Live Wallpapers](Documentation/Screenshots/01_live_wallpapers.png) | ![Static Wallpapers](Documentation/Screenshots/02_static_wallpapers.png) |

| 03. Slideshow & Schedule | 04. Multi-Monitor Displays |
| :---: | :---: |
| ![Slideshow & Schedule](Documentation/Screenshots/03_slideshow_schedule.png) | ![Displays](Documentation/Screenshots/04_displays.png) |

| 05. macOS Lock Screen | 06. Built-in User Guide |
| :---: | :---: |
| ![Lock Screen](Documentation/Screenshots/05_lock_screen.png) | ![User Guide](Documentation/Screenshots/06_user_guide.png) |

| 07. AI Workshop (Google Gemini / OpenRouter) | 08. Software Updates & Settings |
| :---: | :---: |
| ![AI Workshop](Documentation/Screenshots/07_ai_workshop.png) | ![Settings](Documentation/Screenshots/08_settings.png) |

---

### 🎬 Live Wallpaper Engine & Video Controls
- **Video Wallpapers** — Hardware-accelerated 1080p / 2K / 4K / 8K video loops via `AVFoundation` (H.264, HEVC/H.265, ProRes)
- **Interactive Video Seek Slider** — Real-time playback timeline slider with `MM:SS` duration tracking and live seeking for video wallpapers
- **Interactive WebGL Shaders** — Full HTML5/WebGL/Canvas procedural wallpapers rendered in `WKWebView`
- **Built-in Shader Pack** — Aurora Borealis, Matrix Digital Rain, Cyberpunk Synthwave, 3D Particle Wave
- **Static Wallpapers** — High-res image support (JPEG, PNG, HEIC) via `NSWorkspace`

### ⏰ Slideshow & Timed Rotation Engine
- **Interval Slideshow** — Automatically rotate active wallpapers on a configurable timer (30 sec, 5 min, 15 min, 1 hr, 24 hr)
- **Time-of-Day Schedules** — Assign specific wallpapers to automatically trigger at exact times (e.g. 08:00 AM Morning Sunrise, 18:00 PM Sunset, 22:00 PM Night Cosmos)
- **Shuffle & Next Trigger** — Sequential or randomized rotation with instant manual "Rotate Now" action button

### 🚀 System Startup & Launch at Login
- **Launch at Boot / Startup** — Powered by macOS `SMAppService.mainApp`
- **Live Status Indicator** — Real-time feedback (`Active`, `Requires Approval`, `Not Registered`) in Settings & menu bar
- **Quick Access Menu** — Toggle launch at login directly from the status bar menu bar icon

### 🔒 Independent Lock Screen Wallpaper
- **Separate Lock Screen Image** — Choose an independent static wallpaper image for your macOS lock screen while keeping your animated live wallpaper running on desktop
- **Instant Preview & Selector** — Interactive preview card showing lock screen clock overlay with your selected image

### 🖥️ Multi-Monitor Support
- Assign individual wallpapers per display or mirror across all screens
- Dynamic hot-plug detection (`didChangeScreenParametersNotification`)
- Per-display zoom, fit, fill, and stretch placement modes

### ⚡ Smart Power Management
- Auto-pause on battery with configurable threshold
- Full-screen app detection pauses rendering to give 100% GPU to active apps
- Performance tiers: Full (60fps), Balanced (30fps), Low Power (15fps), Paused

### 🎛️ Menu Bar App & Window Controls
- Runs silently in background with status bar menu bar icon
- Quick pause/resume, mute/unmute, volume control, and Launch at Login toggles
- **Reliable Dashboard Window Launcher** — Quick "Open Dashboard" menu action surfacing the window regardless of Dock visibility or window state

### 🤖 AI Wallpaper Generator *(Early Access)*
- Generate custom HTML5/WebGL live wallpapers using natural language prompts
- Supports OpenAI GPT-4, Claude 3, Gemini 1.5 Flash, OpenRouter
- All API keys stored securely in macOS **Keychain** — never on disk

### 📁 Document Library
- Auto-creates `~/Documents/MacauraApp/` folder structure on first launch
- Import custom `.mp4`, `.mov`, `.m4v`, `.gif`, `.html`, `.jpg`, `.png` wallpapers via drag & drop or file scanner

---

## 🛠️ Architecture

```
MacAuraLive/
├── Package.swift                      # Swift Package Manifest (macOS 13.0+)
├── Scripts/
│   └── build_app.sh                  # Release build + .app bundle packager
└── Sources/MacAuraLive/
    ├── MacAuraLiveApp.swift               # @main entry, NSStatusItem, Dock & Launch at Login toggles
    ├── Models/
    │   ├── WallpaperItem.swift        # Wallpaper data model
    │   ├── AppSettings.swift          # UserDefaults + Keychain settings & LaunchAtLogin status
    │   └── DisplayInfo.swift          # Display/monitor state
    ├── Core/
    │   ├── WallpaperEngine.swift      # Multi-monitor window orchestrator & playback position state
    │   ├── WallpaperWindow.swift      # Below-desktop-icons NSWindow
    │   ├── VideoWallpaperView.swift   # AVPlayerLooper 4K video renderer + seek & time observer
    │   ├── WebWallpaperView.swift     # WKWebView HTML5/WebGL renderer + MacAuraLive SDK
    │   ├── WallpaperStorageManager.swift # Library persistence & file import
    │   ├── SlideshowManager.swift     # Interval slideshow timer & time-of-day scheduled rules
    │   ├── AIGenerationManager.swift  # Multi-provider AI wallpaper generation
    │   ├── KeychainManager.swift      # Secure API key storage
    │   ├── LockScreenManager.swift    # Lock screen static wallpaper application
    │   ├── PerformanceManager.swift   # Battery, thermal, FPS management
    │   └── DisplayManager.swift       # NSScreen multi-monitor manager
    ├── Views/
    │   ├── MainWindowView.swift       # SwiftUI dashboard, sidebar navigation & video seek bar widget
    │   ├── GalleryView.swift          # Wallpaper grid, importer, preview cards
    │   ├── SlideshowView.swift        # Interval rotation & time-of-day schedule manager UI
    │   ├── SettingsView.swift         # Preferences, Launch at Login status badge, About, TOS, Privacy
    │   ├── AIConfigurationView.swift  # AI provider setup + prompt playground
    │   ├── DisplayManagerView.swift   # Per-display wallpaper assignment
    │   ├── LockScreenView.swift       # Lock screen wallpaper picker & live preview
    │   └── AdminGateView.swift        # Early-access passcode gate (hashed)
    └── Resources/
        ├── Assets/
        │   ├── AppIcon.png            # Web-compatible browser App icon (1024x1024 PNG)
        │   ├── AppIcon.icns           # macOS bundle App icon
        │   └── StatusBarIcon.png      # Menu bar icon (18×18 @1x)
        └── Wallpapers/
            ├── Aurora/                # Aurora Borealis WebGL shader
            ├── Matrix/                # Matrix digital rain shader
            ├── Cyberpunk/             # Synthwave/cyberpunk shader
            └── ParticleWave/          # 3D particle wave shader
```

---

## 🚀 Getting Started

### Prerequisites
- macOS 13.0 Ventura or newer
- Xcode Command Line Tools (`xcode-select --install`)
- Apple Silicon Mac (ARM64) — Intel build possible with minor script edits

### Build & Run

```bash
# 1. Clone repository
git clone https://github.com/ASKHOPE/MacAuraLive.git
cd MacAuraLive

# 2. Build the signed .app bundle
./Scripts/build_app.sh

# 3. Launch MacAuraLive
open build/MacAuraLive.app

# 4. Verify Installer Integrity (SHA-256)
shasum -a 256 build/MacAuraLive_v1.2.0_Installer_AppleSilicon.dmg
```

### 🔑 Cryptographic Checksums (v1.2.0)
- **SHA-256**: `b48626c9675cbd99395779c52dbad00b9793ceda4aae74f0e11f7fee66250fed`
- **MD5**: `64eaeefc879fdeb4cd62c96db38b8d15`

### First Launch
On first launch, MacAuraLive will:
1. Create `~/Documents/MacauraApp/` with subfolders for your wallpaper library
2. Appear in your **menu bar** and **Dock**
3. Request **Screen Recording** permission (required to detect full-screen apps and auto-pause rendering)

---

## 🔐 Security & Privacy

| Area | Approach |
|---|---|
| API Keys | Stored in macOS **Keychain** via `Security.framework` — never written to disk or UserDefaults |
| Admin Passcode | Verified against **SHA-256 hash** only — plaintext never in source |
| Wallpaper Data | 100% local — no telemetry, no analytics, no cloud sync |
| Network | Only outbound calls are to AI provider APIs *you configure* |
| Permissions | Screen Recording (full-screen detection only), no microphone/camera |

---

## 📦 MacAuraLive SDK (for Wallpaper Developers)

Custom HTML5 wallpapers can tap into the MacAuraLive SDK injected into every `WKWebView`:

```javascript
window.macAura.onInit(function(config) {
  // Called once when wallpaper loads
  console.log(config.settings); // user custom settings
});

window.macAura.onUpdate(function(state) {
  // Called every frame (~60fps)
  const { batteryLevel, isPluggedIn, performanceTier, fps } = state.system;
  const { x, y } = state.mouse; // real-time mouse position
});
```

---

## ⚖️ Legal & Security Documentation

| Document | Description |
| :--- | :--- |
| **[LICENSE](LICENSE)** | Open-Source MIT License Grant |
| **[EULA.md](EULA.md)** | End User License Agreement & Software Grant |
| **[TERMS_OF_SERVICE.md](TERMS_OF_SERVICE.md)** | Terms of Service, User Responsibilities & Media Copyright Rules |
| **[PRIVACY_POLICY.md](PRIVACY_POLICY.md)** | 100% On-Device Privacy Policy & Permission Usage |
| **[SECURITY.md](SECURITY.md)** | Security Architecture, Vulnerability Reporting & Keychain Protection |
| **[DMCA.md](DMCA.md)** | DMCA Copyright Policy & Takedown Notice Procedures |

### Disclaimer
> MacAuraLive is provided **"as-is"** without warranty of any kind. The authors are not responsible for any damage to hardware, software, data loss, or system instability arising from use of this application. Use at your own risk.
>
> Setting live wallpapers increases GPU and CPU load. Ensure your Mac has adequate cooling. MacAuraLive is not responsible for overheating, hardware degradation, or reduced battery lifespan resulting from continuous use.

### Trademarks
Apple, macOS, Metal, AVFoundation, SwiftUI, and related marks are trademarks of **Apple Inc.** MacAuraLive is an independent project and is not affiliated with, endorsed by, or sponsored by Apple Inc.

---

<p align="center">Made with ❤️ for macOS</p>
