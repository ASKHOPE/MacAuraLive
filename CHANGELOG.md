# MacAuraLive Changelog

## [1.8.0] - 2026-08-17

### Added & Enhancements
- **🌐 Interactive In-Browser macOS App Simulator (`docs/index.html`)**: Complete interactive web simulation of the MacAuraLive desktop dashboard featuring real-time 60 FPS Metal canvas shaders, 9-tab sidebar navigation, live speed sliders, AI terminal compiling, duplicate scanner demo, and marketplace actions.
- **🌓 Dynamic Dark & Day/Light Mode Gallery Showcase**: Added a complete side-by-side screenshot gallery across all 9 application tabs with interactive switching between macOS Dark and Day appearances.
- **🏝️ Ultra-Sleek Floating Island Glass Pill Navbar**: Modern Apple-grade floating pill navbar with `blur(28px)` frosted glass, rounded pill container, prominent `Live Preview` action button, compact `🌙 / ☀️` Theme Switcher, and GitHub link.
- **⚡ Dynamic GitHub Release & Asset Resolution**: Webpage dynamically queries GitHub's public REST API (`/releases/latest`) to auto-populate download buttons with the newest `.dmg` installer, live megabyte sizing, release tags, and download statistics.
- **🔒 Checksum & Package Integrity Modal**: Integrated an immediate post-download verification dialog displaying official SHA-256 and MD5 cryptographic hashes, quick terminal verification commands, and 1-click clipboard copying.
- **🍎 Uncropped Native App Branding**: Standardized icon rendering to use uncropped native Apple squircle aspect ratios across navigation bars, headers, and window titlebars.
- **🚀 Universal 2 Dual-Architecture Release**: Native dual-architecture Mach-O binary (`arm64` + `x86_64`) running natively on Apple Silicon (M1/M2/M3/M4) and Intel Macs on macOS 13 (Ventura), 14 (Sonoma), and 15 (Sequoia).

## [1.7.0] - 2026-08-17

### Added & Enhancements
- **🚀 Universal 2 & Multi-Architecture Compilation**: Native dual-architecture Mach-O binary supporting both **Apple Silicon (ARM64)** and **Intel (x86_64)** Macs with a stripped ~4.4 MB footprint.
- **☀️ High-Contrast Adaptive Light & Dark Themes**: Overhauled UI system using `.macaCardStyle()` and `.macaSubcardStyle()` with native macOS `NSColor.controlBackgroundColor`, 1pt separator borders, and soft depth shadows, eliminating washed-out white containers in Light Mode.
- **🗑️ Default Wallpaper Deletion & Restoration**: All wallpapers (including built-in bundled items) can now be individually or batch deleted. Performing **Reset Media** or **Full Factory Reset** immediately restores the full default catalog.
- **🔍 SHA-256 Duplicate Media Scanner & 1-Click Cleaner**: Scans wallpaper library for duplicate files byte-for-byte, calculates wasted disk space, and provides 1-click cleanup.
- **💾 Settings Backup & Migration**: Export complete application configurations, display placement settings, and slideshow rules to JSON or import them to restore settings on any Mac.
- **🎯 Granular Reset System**: Granular options in Settings to **Reset Only Media** (clears custom imported files and restores bundled pack), **Reset Only Preferences**, or **Full Factory Reset**.
- **📊 Real-Time File Size Badges & Multi-Select**: Displays formatted file sizes on all card footers and quick-look modals, with batch selection mode and deletion counter.
- **Apple Privacy Manifest (`PrivacyInfo.xcprivacy`)**: Fully integrated Apple's official privacy manifest specification declaring zero data tracking, zero third-party telemetry, and declared reasons for UserDefaults and FileTimestamp.
- **Comprehensive Third-Party Licensing Suite (`THIRD_PARTY_LICENSES.md`)**: Full legal attribution and licensing details for all bundled video loops, photography, procedural canvas shaders, and platform APIs.
- **Production DMG Packager**: Automated Universal 2 installer DMG generation with bundled legal documents and SHA-256/MD5 cryptographic checksums.

## [1.6.0] - 2026-08-14

### Added
- **Native Static Wallpaper Engine (`StaticWallpaperView`)**: Implemented high-performance native AppKit CoreGraphics/Metal image rendering with high interpolation, replacing web-view emulation for static images.
- **Default Original Resolution (macOS Native Fit)**: Set Original Resolution as the application-wide default placement mode, ensuring wallpapers render in their exact 1:1 pixel dimensions and native aspect ratios without forced zoom or stretch.
- **Sizing & Crop Toolbar Controls**: Added an interactive "Sizing & Crop" selector in the Gallery header and Full Wallpaper Preview modal with quick toggles for Original (1:1), Fit to Screen, Crop to Fill, Stretch, and Zoom.
- **In-Built Storage & Resource Breakdown**: A dedicated analytics dashboard in Settings displaying real-time disk space usage broken down by App Binary & Metal Engine (~7.5 MB), Live Shaders & Video Loops (~15.0 MB), Static 4K/8K Wallpapers (~0.4 MB), Animated GIFs, AI Generations, and Runtime Cache. Includes a macOS-style multi-color storage bar, percentage breakdown pills, and quick "Clear Cache" and "Open Documents" actions.
- **Sidebar Playback Speed Slider**: Added a dedicated real-time Playback Speed slider (0.25x to 3.0x) in the sidebar footer that works dynamically across both Video and Web/GenAI procedural canvas shaders.
- **API Key Action Trio (Save, Test, Clear)**: Added dedicated "Save Key", "Test Key", and "Clear Key" buttons across all AI Workshop providers (Google Gemini & OpenRouter) with live server validation.
- **Settings Release Notes & Changelog Viewer**: Embedded an interactive "What's New in v1.6.0" Changelog modal directly into Settings and Update cards.

### Fixed & Enhanced
- **Live Wallpaper Slowdown & WebKit Resource Thrashing**: Resolved an issue where live HTML wallpapers (such as Matrix Digital Rain) ran slowly when selected from the Gallery view by eliminating background preview WebViews and implementing explicit `dismantleNSView` teardown.
- **Liquid Glass Layout Synchronization**: Standardized all Settings cards to full equal width (`maxWidth: .infinity`) with consistent macOS glassmorphism styling.

## [1.2.0] - 2026-08-11
### Added
- **Dynamic User Guide**: A comprehensive, search-enabled documentation view providing guides, troubleshooting steps, and configuration help built directly into the app.
- **Web Wallpaper Engine improvements**: Complete SDK for JS interoperability across HTML wallpapers.
- **Sandbox Compliance & Directory Management**: Core resources automatically copy to App Support directory for robust handling of GenAI wallpapers.

## [1.0.0] - Initial Release
- Launched MacAuraLive Live Wallpaper Engine for Apple Silicon.
- Supported Wallpaper formats: Video (mp4), Web/HTML5 shaders, Static Images (jpg/png), and GIFs.
- Custom Playlist/Slideshow scheduler.
- Multiple Display Support.
- Built-in App Sandbox architecture.
