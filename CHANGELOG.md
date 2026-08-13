# MacAuraLive Changelog

## [1.4.0] - 2026-08-14

### Fixed
- **Slideshow Clear Selection**: Clearing the slideshow playlist selection no longer incorrectly falls back to playing all wallpapers. The UI accurately reflects 0 items selected when the list is cleared.
- **Permission Prompts on Downloads**: Addressed repeated permission prompts by bypassing the `AVAssetReader` check on application startup. Now, custom downloaded wallpapers reside in `~/Documents/MacAuraLiveApp/` and the audio verification is only triggered when importing new wallpapers.
- **User Guide UI Overflow**: Converted the User Guide topic filters to use a wrapping `FlowLayout`. The filters now properly wrap and fit across multiple lines instead of being pushed offscreen or hidden behind window edges.
- **Wallpaper Scaling & Placement Syncing**: Implemented `WKNavigationDelegate`'s `webView(_:didFinish:)` handler in `WebWallpaperView`. Wallpapers transitioned via the Slideshow Manager (like GenAI, HTML or GIF wallpapers) will now wait until the DOM is fully loaded to apply the global Zoom/Placement user settings.

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
