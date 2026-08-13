# MacAuraLive — Complete User Guide & Comprehensive Documentation

Welcome to **MacAuraLive**, the high-performance native Live Wallpaper Engine for macOS, engineered with Apple Silicon Metal acceleration, AVFoundation hardware video decoders, WebGL 60fps shader runtimes, and an integrated Online Marketplace.

---

## Table of Contents

1. [Quick Start & Basic Usage](#1-quick-start--basic-usage)
2. [Wallpaper Placement & Scale Modes](#2-wallpaper-placement--scale-modes)
3. [Audio Engine & Sound Controls](#3-audio-engine--sound-controls)
4. [Online Marketplace & API Plugins](#4-online-marketplace--api-plugins)
   - [Unsplash Plugin](#unsplash-plugin)
   - [Pixabay Plugin](#pixabay-plugin)
   - [Pexels Plugin](#pexels-plugin)
5. [Local Storage Directory Structure](#5-local-storage-directory-structure)
6. [Lock Screen Wallpaper Setup](#6-lock-screen-wallpaper-setup)
7. [Slideshow & Scheduled Rotations](#7-slideshow--scheduled-rotations)
8. [Multi-Monitor Displays & Ultra-Wide Spanning](#8-multi-monitor-displays--ultra-wide-spanning)
9. [AI Workshop & WebGL Shader Creation](#9-ai-workshop--webgl-shader-creation)
10. [Smart Performance & Battery Saver](#10-smart-performance--battery-saver)
11. [Troubleshooting, Permissions & FAQs](#11-troubleshooting-permissions--faqs)

---

## 1. Quick Start & Basic Usage

### Applying a Wallpaper
1. Launch **MacAuraLive**.
2. From the left sidebar, select **Live Wallpapers** (motion videos, loops, and WebGL code shaders) or **Static Wallpapers** (ultra-HD 4K/8K photography).
3. Hover over any wallpaper card to see its motion preview, or click the **Eye Icon (Quick Look)** to open a high-resolution full preview modal.
4. Click anywhere on the card or click **Apply Wallpaper**.
5. The wallpaper renders immediately on your desktop directly underneath Finder desktop icons.

### Finder Desktop Icon Interactivity
- MacAuraLive creates a specialized low-level desktop window layer positioned behind Finder's icon canvas.
- All desktop shortcuts, folders, files, and Stage Manager widgets remain 100% interactive.
- The **Dynamic Contrast Engine** computes average wallpaper luminance in real time to adapt Finder text shadows for optimal readability.

---

## 2. Wallpaper Placement & Scale Modes

MacAuraLive supports 5 distinct placement engines configured under **Settings > Live Wallpaper Placement**:

| Placement Mode | Description | Ideal Use Case |
| :--- | :--- | :--- |
| **Stretch to Fill Screen (Default)** | Fills the entire screen dimensions edge-to-edge without black bars or letterboxing. | Ultra-wide monitors, 16:10 MacBook displays, 4K displays. |
| **Fill Screen (Aspect Ratio)** | Preserves the native aspect ratio while cropping excess edges to fill the display. | High-detail scenic wallpapers. |
| **Fit to Screen (Contain)** | Preserves aspect ratio with clean letterboxing / pillarboxing. | Aspect-sensitive artwork. |
| **Center** | Renders wallpaper at native pixel dimensions centered on screen. | Pixel art or smaller loops. |
| **Custom Zoom (0.5x – 2.5x)** | Precision slider zoom allowing fine adjustment of visual composition. | Custom framing. |

---

## 3. Audio Engine & Sound Controls

Many motion wallpapers include ambient soundscapes (rain, waves, synth music).

### Audio Features:
- **Sidebar Footer Audio Widget**: Located at the bottom of the left sidebar, providing instant **Mute/Unmute**, volume slider (0% to 100%), and percentage display.
- **Audio VU Meter**: Wallpapers with embedded audio tracks display an animated equalizer VU meter badge in the gallery.
- **Auto-Mute on App Focus**: In **Settings > Wallpaper Sound & Audio Settings**, toggle *“Mute audio automatically when app loses focus”* to silence wallpaper audio when working in other applications.
- **Playback Speed**: Adjust video playback rate from **0.25x (ultra slow motion)** to **2.0x (fast motion)** in the sidebar status widget.

---

## 4. Online Marketplace & API Plugins

MacAuraLive integrates an online marketplace powered by modular API plugins.

### Configuring API Plugins:
1. Go to **Settings > Marketplace & Content Plugins** (or click *Configure API Keys* in the Marketplace tab).
2. Enter your API key in the dedicated input field.
3. Click **Save Key**. The key is validated and encrypted in the **macOS Keychain Hardware Enclave**.
4. Click **Clear** at any time to remove your key.

### Free Provider Plugins:
- **Unsplash API**:
  - Curated 4K/8K landscape, architectural, and abstract photography.
  - Sign up: [unsplash.com/developers](https://unsplash.com/developers)
- **Pixabay API**:
  - Royalty-free 4K/HD video loops, atmospheric animations, and audio wallpapers.
  - Sign up: [pixabay.com/api/docs/](https://pixabay.com/api/docs/)
- **Pexels API**:
  - Curated 4K photography and high-fps motion video loops.
  - Sign up: [pexels.com/api/](https://www.pexels.com/api/)

### Downloading:
- **Download & Set**: Downloads the 4K asset directly and sets it as your desktop wallpaper immediately.
- **Save to Library**: Downloads the asset to your Mac for future use without changing your current wallpaper.

---

## 5. Local Storage Directory Structure

MacAuraLive stores all user files and downloaded wallpapers permanently in your user Documents folder:

```
~/Documents/MacAuraLiveApp/
├── livewallpaper/       # MP4, MOV, and M4V video motion loops
├── staticwallpaper/     # JPEG, PNG, HEIC, TIFF, and WebP 4K photos
├── gif/                 # Animated GIF loops
└── animatedcode/        # WebGL / HTML5 generative shaders & runtimes
```

### Adding Custom Wallpapers:
1. Drop any video, photo, GIF, or HTML file directly into the appropriate folder above.
2. In **Settings > Local Reference Folder & Storage Path**, click **Sync Now**.
3. Your media will appear in the library with thumbnails and resolution tags.

---

## 6. Lock Screen Wallpaper Setup

macOS lock screens display high-resolution static images. MacAuraLive allows you to set an independent static wallpaper on your lock screen while running live video on your desktop.

### Steps:
1. Select **Lock Screen** from the sidebar.
2. Select any static image from your library or click **Browse Image…** to pick any photo from your Mac.
3. Click **Set as Lock Screen Wallpaper**.
4. Test by pressing **Control + Command + Q** (`^⌘Q`).

---

## 7. Slideshow & Scheduled Rotations

Automate your desktop atmosphere with interval timers or specific times of day.

### Interval Rotation:
1. Open **Slideshow & Schedule**.
2. Toggle **Interval Slideshow Engine** ON.
3. Choose rotation frequency: `5 min`, `15 min`, `30 min`, `1 hour`, `2 hours`, `6 hours`, `12 hours`, or `24 hours`.
4. Enable **Shuffle Mode** for randomized selection.
5. Use the visual playlist selector to select which wallpapers rotate.

### Time-of-Day Rules:
- Click **Add Time Rule** to create scheduled triggers (e.g., *Sunrise* at 07:00, *Ocean Breeze* at 12:00, *Neon Cyberpunk* at 21:00).

---

## 8. Multi-Monitor Displays & Ultra-Wide Spanning

### Per-Display Mode:
1. Open **Displays** from the sidebar.
2. Click any connected monitor thumbnail.
3. Assign an independent wallpaper to that specific screen.

### Ultra-Wide Spanning Mode:
1. In **Settings > Default Display & Scaling**, enable **Span Live Wallpaper Across All Connected Displays**.
2. A single high-resolution wallpaper (e.g., 32:9 or 48:9) will span continuously across all connected monitors.
3. Monitor connects and disconnects are automatically detected with zero downtime.

---

## 9. AI Workshop & WebGL Shader Creation

Generate bespoke 60fps interactive shaders from natural language prompts.

### Supported AI Providers:
- **OpenRouter**: DeepSeek R1, Llama 3.3 70B, Claude 3.5 Sonnet.
- **Google Gemini**: Gemini 2.0 Flash / Pro.
- **Local Ollama**: 100% offline local LLM generation.

### How to Generate:
1. Open **AI Workshop** from the sidebar.
2. Type a prompt (e.g., *“Bioluminescent ocean jellyfish swimming through deep dark water with glowing particles”*).
3. Click **Generate Live Shader Wallpaper**.
4. Watch the live terminal console as the AI produces clean WebKit Metal canvas code.
5. The generated shader is saved to `~/Documents/MacAuraLiveApp/animatedcode/` and applied immediately.

---

## 10. Smart Performance & Battery Saver

MacAuraLive is designed for ultra-low power consumption:

- **Pause on Battery**: In **Settings > Smart Performance & Battery Saver**, enable *“Pause live wallpaper when on battery power”*. When unplugged, rendering pauses, preserving 100% of your MacBook battery.
- **Pause on Full-Screen Apps**: Enable *“Pause when full-screen applications/games are focused”*. When gaming or editing 4K video full-screen, GPU rendering completely pauses.
- **Zero Idle GPU**: When static wallpapers are selected, the video playback loop is unloaded from memory.

---

## 11. Troubleshooting, Permissions & FAQs

### Permissions Required:
- **Screen Recording**: Used strictly to detect when another application is in full-screen mode to pause playback. No screen content is recorded or transmitted.
- **Keychain**: Used to store your optional API keys securely in the Apple Hardware Secure Enclave.

### Useful Shortcuts:
| Action | Shortcut / Location |
| :--- | :--- |
| **Lock Screen** | `Control + Command + Q` (`^⌘Q`) |
| **Mute / Unmute** | Sidebar Footer Audio Button |
| **Menu Bar Quick Menu** | Click the MacAuraLive icon in macOS Menu Bar |
| **Open Settings** | `Command + ,` (`⌘,`) |

---

*MacAuraLive — Native macOS Live Wallpaper Engine*
