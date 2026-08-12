# MacAura — Live Wallpaper Engine for macOS

<p align="center">
  <img src="Sources/MacAura/Resources/Assets/AppIcon.icns" width="120" alt="MacAura Icon"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013.0%2B-lightgrey?style=flat-square&logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.9%2F6.0-orange?style=flat-square&logo=swift" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%28ARM64%29-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" />
  <img src="https://img.shields.io/badge/Status-Alpha-purple?style=flat-square" />
</p>

> **MacAura** is an open-source, hardware-accelerated live wallpaper engine for macOS — built entirely in Swift and SwiftUI, with zero dependencies.

---

## ✨ Features

### 🎬 Live Wallpaper Engine
- **Video Wallpapers** — Hardware-accelerated 1080p / 2K / 4K / 8K video loops via `AVFoundation` (H.264, HEVC/H.265, ProRes)
- **Interactive WebGL Shaders** — Full HTML5/WebGL/Canvas procedural wallpapers rendered in `WKWebView`
- **Built-in Shader Pack** — Aurora Borealis, Matrix Digital Rain, Cyberpunk Synthwave, 3D Particle Wave
- **Static Wallpapers** — High-res image support (JPEG, PNG, HEIC) via `NSWorkspace`

### 🖥️ Multi-Monitor Support
- Assign individual wallpapers per display or mirror across all screens
- Dynamic hot-plug detection (`didChangeScreenParametersNotification`)
- Per-display zoom, fit, fill, and stretch placement modes

### ⚡ Smart Power Management
- Auto-pause on battery with configurable threshold
- Full-screen app detection pauses rendering to give 100% GPU to active apps
- Performance tiers: Full (60fps), Balanced (30fps), Low Power (15fps), Paused

### 🎛️ Menu Bar App
- Runs silently in the background — no Dock clutter (toggle via menu)
- Quick pause/resume, mute/unmute from menu bar
- **Remove from Dock** toggle persists across restarts

### 🤖 AI Wallpaper Generator *(Early Access)*
- Generate custom HTML5/WebGL live wallpapers using natural language prompts
- Supports OpenAI GPT-4, Claude 3, Gemini 1.5 Flash, OpenRouter
- All API keys stored securely in macOS **Keychain** — never on disk

### 🔒 Lock Screen Integration *(Early Access)*
- Sync live wallpaper to macOS lock screen via `com.apple.screenIsLocked` notification
- Admin passcode protected for stability during testing

### 📁 Document Library
- Auto-creates `~/Documents/MacauraApp/` folder structure on first launch
- Import custom `.mp4`, `.mov`, `.m4v`, `.gif`, `.html` wallpapers via drag & drop or folder scan

---

## 🛠️ Architecture

```
MacAura/
├── Package.swift                      # Swift Package Manifest (macOS 13.0+)
├── Scripts/
│   └── build_app.sh                  # Release build + .app bundle packager
└── Sources/MacAura/
    ├── MacAuraApp.swift               # @main entry, NSStatusItem, Dock toggle
    ├── Models/
    │   ├── WallpaperItem.swift        # Wallpaper data model
    │   ├── AppSettings.swift          # UserDefaults + Keychain settings
    │   └── DisplayInfo.swift          # Display/monitor state
    ├── Core/
    │   ├── WallpaperEngine.swift      # Multi-monitor desktop window orchestrator
    │   ├── WallpaperWindow.swift      # Below-desktop-icons NSWindow
    │   ├── VideoWallpaperView.swift   # AVPlayerLooper 4K video renderer
    │   ├── WebWallpaperView.swift     # WKWebView HTML5/WebGL renderer + MacAura SDK
    │   ├── WallpaperStorageManager.swift # Library persistence & file import
    │   ├── AIGenerationManager.swift  # Multi-provider AI wallpaper generation
    │   ├── KeychainManager.swift      # Secure API key storage
    │   ├── LockScreenManager.swift    # Session lock/unlock observer
    │   ├── PerformanceManager.swift   # Battery, thermal, FPS management
    │   └── DisplayManager.swift       # NSScreen multi-monitor manager
    ├── Views/
    │   ├── MainWindowView.swift       # SwiftUI dashboard + sidebar navigation
    │   ├── GalleryView.swift          # Wallpaper grid, importer, preview cards
    │   ├── SettingsView.swift         # Preferences, About, TOS, Privacy
    │   ├── AIConfigurationView.swift  # AI provider setup + prompt playground
    │   ├── DisplayManagerView.swift   # Per-display wallpaper assignment
    │   ├── LockScreenView.swift       # Lock screen wallpaper settings
    │   └── AdminGateView.swift        # Early-access passcode gate (hashed)
    └── Resources/
        ├── Assets/
        │   ├── AppIcon.icns           # App icon (place your .icns here)
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
# 1. Clone
git clone https://github.com/YOUR_USERNAME/wallpapermacs.git
cd wallpapermacs

# 2. Build the .app bundle
./Scripts/build_app.sh

# 3. Launch
open build/MacAura.app
```

### First Launch
On first launch, MacAura will:
1. Create `~/Documents/MacauraApp/` with subfolders for your wallpaper library
2. Appear in your **Dock** and **menu bar**
3. Request **Screen Recording** permission (required to detect full-screen apps)

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

## 📦 MacAura SDK (for Wallpaper Developers)

Custom HTML5 wallpapers can tap into the MacAura SDK injected into every `WKWebView`:

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

## 🗺️ Roadmap

- [ ] **GIF Wallpapers** — Animated GIF support via `ImageIO`
- [ ] **Animated Code Wallpapers** — Live-coding terminal aesthetic
- [ ] **Music Reactive Wallpapers** — Audio-reactive shaders (in design)
- [ ] **iCloud Sync** — Cross-device wallpaper library
- [ ] **App Store Release** — Notarized distribution
- [ ] **Intel (x86_64) Support**

---

## ⚖️ Legal

### License
MIT License — see [LICENSE](LICENSE)

### Disclaimer
> MacAura is provided **"as-is"** without warranty of any kind. The authors are not responsible for any damage to hardware, software, data loss, or system instability arising from use of this application. Use at your own risk.
>
> Setting live wallpapers increases GPU and CPU load. Ensure your Mac has adequate cooling. MacAura is not responsible for overheating, hardware degradation, or reduced battery lifespan resulting from continuous use.

### Trademarks
Apple, macOS, Metal, AVFoundation, SwiftUI, and related marks are trademarks of **Apple Inc.** MacAura is an independent project and is not affiliated with, endorsed by, or sponsored by Apple Inc.

### Privacy
MacAura collects **zero** user data. No analytics, no crash reports sent externally, no usage tracking. All processing is on-device.

---

## 👤 Author

Built as a portfolio project demonstrating:
- Native macOS app development with **SwiftUI + AppKit**
- **Multi-window desktop-level rendering** below the Finder icon layer
- Hardware-accelerated **AVFoundation** video pipelines
- **WebKit/WKWebView** embedding with custom JavaScript bridge
- **Keychain** secure storage integration
- Real-time **AI code generation** via multiple LLM providers
- Clean **MVVM architecture** with Combine publishers

---

<p align="center">Made with ❤️ for macOS</p>
