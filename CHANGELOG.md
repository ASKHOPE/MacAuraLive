# MacAuraLive Changelog

## [1.9.4.1] - 2026-08-20

### Added & Refined
- **🖼️ Transparent Logo & Sidebar Header Sync**: Replaced asset loading with a dedicated `NSImage.appLogo` resolver that eliminates dark background artifacts on transparent PNGs, and displays the full uncropped brand logo in both Sidebar and About panels.
- **🔄 Instant Theme Switching & Zero Lingering Styles**: Attached `.id(settings.appTheme)` to the root window view tree to force a complete and instantaneous re-evaluation of all UI styles and color tokens whenever toggling between Classic, Day, and Night themes.
- **📐 2pt Sharp Modal Chassis for Classic OS**: Added rectangular clipping and vintage border chassis overlays to Mood Editor, API Key Manager, Terms & Licensing, Disclaimer, and Changelog modal sheets.
- **↔️ Horizontal Tag & Discovery Scrollbars**: Enabled smooth horizontal scrollbars on category chips and Marketplace quick discovery tag carousels.

## [1.9.4] - 2026-08-20

### Added & Refined
- **📐 Universal Retro Form Inputs (`MacaTextFieldModifier`)**: Replaced all high-radius `.textFieldStyle(.roundedBorder)` across the entire app with `.macaTextFieldStyle()` enforcing vintage 2pt rectangular borders, classic paper background, and monospaced typography in Classic OS mode.
- **🖼️ Lock Screen Library Thumbnail 2pt Retro Radius**: Updated the Lock Screen Library wallpaper horizontal strip to use adaptive 2pt corner radius and vintage background ribbons in Classic OS theme.
- **🎛️ Comprehensive Settings & Modal Button Theming**: Audited and converted all action buttons across Storage Management (`Clear Temporary Cache`, `Open Storage Folder`), Software Updates (`Check for Updates`, `What's New`), Duplicate Cleaner, Settings Backup (`Export/Import JSON`), and API Key configuration to `.macaButtonStyle()`.
- **🛍️ Marketplace Alignment & Terms Retro Theming**: Fixed card footer action button alignment and padding, and fully themed the Marketplace Terms & Licensing modal with classic canvas backgrounds and retro subcards.

## [1.9.3.1] - 2026-08-20

### Added & Refined
- **🎚️ Custom Hardware Retro Sliders (`MacaRetroSlider`)**: Built vintage 3D beveled hardware sliders with deep inset track groove, vertical grip ridges, and tick marks for Seek, Speed, Volume, and Zoom controls.
- **🛡️ Data Management & Reset Retro Theming**: Styled the Data Management & Reset card with sharp 2pt corners and `.macaButtonStyle()` actions.
- **📐 Form Spacing & Modal Layouts**: Cleaned up section spacing and wallpaper picker grid in Mood Editor Sheet, API Keys modal, and legal dialogs.
- **🏷️ Dynamic Category Wrapping & Equalized Buttons**: Added horizontal scrolling to category chips and balanced action button sizing in Gallery toolbar.

## [1.9.3] - 2026-08-20

### Added & UI/UX Polish
- **🖥️ Authentic OS Classic Design Suite & Sharp 2pt Radii**: Reduced card, thumbnail, subcard, modal dialog, and button corner radii to sharp 2pt across all screens in Classic OS theme for an authentic vintage chassis aesthetic.
- **🕹️ Global Retro Component Architecture (`MacaThemeButtonStyle` & `MacaRetroToggle`)**: Replaced remaining ad-hoc toggles and default buttons across Slideshow scheduled rules, Mood editor, and Onboarding with unified retro bevels and hardware toggles.
- **🔒 Context-Aware Frosted Glass Toggle & Tooltip**: Frosted glass vibrancy is automatically disabled with an informative explanatory tooltip when Classic OS theme is active.
- **📖 Solid High-Contrast User Guide Typography**: Fixed documentation text visibility with adaptive solid black `#1D1C19` text on light/classic backgrounds and high-contrast typography across all guide cards.
- **🛍️ Retro Themed Marketplace Tags & Action Row Alignment**: Restyled top provider chips, media filters (`All Types`, `4K Photos`, `Video Loops`), and discovery tags to match retro olive/beige themes, and fixed `Download & Set` button spacing.
- **🎛️ Mood Profile Action Controls Alignment**: Refactored `MoodCard` action row with flexible spacing to prevent button overlapping on smaller screen widths.
- **🧹 Settings Cleanup**: Removed redundant duplicate copyright notice outside the About card.

## [1.9.2] - 2026-08-20

### Added & Major Features
- **🎨 Complete OS Classic Sidebar & UI Transformation**: Custom grouped monospaced sidebar with `#5C5744` olive selection pills, classic wireframe icons, raised beveled import buttons, and Braun/System 7 radio buttons in Settings and Marketplace.
- **🛡️ Cryptographic SHA-256 Checksum & Disk Image Verification**: Automated checksum validation and Apple disk image integrity verification before showing "Install & Restart" to ensure downloaded updates are authentic and not compromised in transit.
- **⚡ Atomic Bundle Replacement & Clean Relaunch**: Failsafe background process that waits for the active app to terminate cleanly, replaces `/Applications/MacAuraLive.app` atomically, detaches the mounted DMG, clears quarantine flags, and relaunches the new version without user friction.
- **✨ Mood Selector & Custom Profile Templates**: Create, save, and cycle customized playlists and mood profiles (e.g., Deep Focus, Night Sanctuary, Day Flow & Energy, Cyber Lounge).
- **🌙 Automatic macOS Mode Sync**: Seamlessly syncs with macOS system states — automatically activating linked mood profiles on **Do Not Disturb / Focus Mode**, **macOS Sleep / Screen Dimmed**, and **Dark / Light Appearance** changes.
- **💾 Live Storage Capacity & Free Disk Space Monitor**: Real-time volume capacity breakdown, available disk space indicators, and 1-click temporary cache cleaner.
- **📦 Official macOS Setup Wizard Package (`.pkg`)**: Apple-standard installation wizard with introductory feature overview, full Terms of Service agreement step, and automated destination staging.
- **🎨 Orion-Style Modern About Panel**: Overhauled About section in Settings with an 80pt Apple squircle icon, dynamic version metadata, live taglines, and quick actions ("What's New", "Send Feedback", "Licenses").
- **🏷️ Dynamic Versioning & Single Source of Truth**: Centralized `version.json` and runtime `AppVersion` model eliminating hardcoded version discrepancies across builds and release channels.
- **🔒 Rollback Safety & Release Manifests**: Built-in build history tracking (`build_history.json`) and automated rollback CLI tool (`Scripts/rollback.sh`).

## [1.8.1] - 2026-08-20

### Fixed
- **🐛 Wallpaper window covers Dock & all apps after screen lock / sleep**: When the Mac locked, slept, or turned off the display, the wallpaper window was raised to screen-saver level for the lock-screen wallpaper feature but was never lowered back to the desktop level on unlock/wake. All windows and the Dock were hidden behind the wallpaper window on login. Fixed by calling `reloadEngine()` on both `com.apple.screenIsUnlocked` and `NSWorkspace.sessionDidBecomeActiveNotification`, and by adding a `NSWorkspace.didWakeNotification` observer in `WallpaperEngine` to reassert the correct window level after display-on / wake from sleep.
- **✨ Menu bar icon now shows app name tooltip**: Hovering over the status bar icon now displays **"MacAuraLive Live Wallpaper"** as a native macOS tooltip.
- **🚫 App no longer pins to the Dock**: MacAuraLive now runs as a pure menu-bar app (`activationPolicy = .accessory`). The Dock icon only appears temporarily while the Dashboard window is open, and disappears again when the window is closed — matching the behaviour of apps like Fantastical and Alfred.

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
- **In-Built Storage & Resource Breakdown**: A dedicated analytics dashboard in Settings displaying real-time disk space usage broken down by App Binary & Metal Engine (~4.8 MB), Live Shaders & Video Loops (~11 MB), Static 4K/8K Wallpapers (~14 MB), Animated GIFs, AI Generations, and Runtime Cache (~36 KB). Includes a macOS-style multi-color storage bar, percentage breakdown pills, and quick "Clear Cache" and "Open Documents" actions. *(All figures are approximate and measured from the release build; actual sizes may vary ±5–10% depending on macOS version and APFS compression.)*
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
