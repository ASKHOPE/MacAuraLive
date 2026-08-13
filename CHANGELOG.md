# MacAuraLive Changelog

## [1.5.0] - 2026-08-14

### Added
- **In-Built Storage & Resource Breakdown**: A dedicated analytics dashboard in Settings displaying real-time disk space usage broken down by App Binary & Metal Engine (~7.5 MB), Live Shaders & Video Loops (~15.0 MB), Static 4K/8K Wallpapers (~0.4 MB), Animated GIFs, AI Generations, and Runtime Cache. Includes a macOS-style multi-color storage bar, percentage breakdown pills, and quick "Clear Cache" and "Open Documents" actions.
- **Sidebar Playback Speed Slider**: Added a dedicated real-time Playback Speed slider (0.25x to 3.0x) in the sidebar footer that works dynamically across both Video and Web/GenAI procedural canvas shaders.
- **API Key Action Trio (Save, Test, Clear)**: Added dedicated "Save Key", "Test Key", and "Clear Key" buttons across all AI Workshop providers (Google Gemini & OpenRouter) with live server validation.
- **Settings Release Notes & Changelog Viewer**: Embedded an interactive "What's New in v1.5.0" Changelog modal directly into Settings and Update cards.

### Fixed & Enhanced
- **Live Wallpaper Slowdown & WebKit Resource Thrashing**: Resolved an issue where live HTML wallpapers (such as Matrix Digital Rain) ran slowly when selected from the Gallery view by eliminating background preview WebViews and implementing explicit `dismantleNSView` teardown.
- **Full Viewport Static Wallpaper Placement**: Fixed top-center alignment and sizing offsets for static images and GIFs in `WebWallpaperView`, ensuring 100% full-screen fitting across all display modes (`fill`, `fit`, `stretch`, `center`, `zoom`).
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
