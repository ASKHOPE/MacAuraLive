import SwiftUI

public struct LockScreenView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var lockManager = LockScreenManager.shared
    @ObservedObject var storage = WallpaperStorageManager.shared

    @State private var selectedImageId: String = ""
    @State private var previewImage: NSImage? = nil
    @State private var currentTimeString: String = ""
    @State private var currentDateString: String = ""
    @State private var didApply: Bool = false

    private var currentLockPath: String { settings.lockScreenImagePath }
    private var currentLockImage: NSImage? {
        let p = currentLockPath
        guard !p.isEmpty else { return nil }
        return ImageCache.shared.image(forPath: p)
    }

    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    /// Only static images are valid for the lock screen
    private var staticWallpapers: [WallpaperItem] {
        storage.wallpapers.filter { $0.type == .image }
    }

    private var selectedWallpaper: WallpaperItem? {
        staticWallpapers.first(where: { $0.id == selectedImageId })
            ?? staticWallpapers.first
    }

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // ── Header ────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Text("Lock Screen Wallpaper")
                    .font(.system(size: 28, weight: .bold))
                Text("Choose a static image to display on your macOS lock screen.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // ── Preview Card ──────────────────────────────────────────
            ZStack {
                // Wallpaper background
                Group {
                    if let img = previewImage {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [Color.indigo.opacity(0.6), Color.purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(height: 230)
                .clipped()

                // Frosted glass overlay (simulates macOS lock screen)
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.4)

                // Clock overlay
                VStack(spacing: 4) {
                    Spacer()
                    Text(currentTimeString.isEmpty ? "22:45" : currentTimeString)
                        .font(.system(size: 54, weight: .thin, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 8)

                    Text(currentDateString.isEmpty ? "Wednesday, August 13" : currentDateString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.4), radius: 4)
                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                        Text("Lock Screen Preview")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.bottom, 14)
                }
            }
            .frame(maxWidth: .infinity)
            .cornerRadius(18)
            .clipped()
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .onReceive(timer) { _ in updateTimeAndDate() }
            .onAppear {
                updateTimeAndDate()
                if selectedImageId.isEmpty {
                    selectedImageId = settings.lockScreenWallpaperId
                }
                // Load from the persisted path first (most reliable)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    loadSavedPreview()
                }
            }
            .onChange(of: selectedImageId) { _ in
                loadPreviewImage()
                if previewImage == nil {
                    loadSavedPreview()
                }
            }

            // ── Current Selection + Picker ────────────────────────────
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Lock Screen Image")
                        .font(.headline)
                    Spacer()
                    // Separate wallpaper badge
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                        Text("Independent from Desktop")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(6)
                }

                // Current image card
                if let img = currentLockImage {
                    HStack(spacing: 14) {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 66)
                            .cornerRadius(8)
                            .clipped()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.purple, lineWidth: 2)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Currently Applied", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            let name = (currentLockPath as NSString).lastPathComponent
                            Text(name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text(currentLockPath)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                    )
                } else {
                    // No image applied yet
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No lock screen image selected yet")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Use Browse Image… below to choose any photo from your Mac.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
                }

                // Library thumbnails (if any static images exist in MacAuraLive library)
                if !staticWallpapers.isEmpty {
                    Text("From MacAuraLive Library")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(staticWallpapers) { item in
                                WallpaperThumbnailButton(
                                    item: item,
                                    isSelected: selectedImageId == item.id
                                ) {
                                    selectedImageId = item.id
                                    didApply = false
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                    }
                }

                // Action row
                HStack(spacing: 12) {
                    Button {
                        openImagePicker()
                    } label: {
                        Label("Browse Image…", systemImage: "folder.badge.plus")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)

                    if !staticWallpapers.isEmpty {
                        Button {
                            applyLockScreenWallpaper()
                        } label: {
                            Label("Apply Selected", systemImage: "lock.rectangle.on.rectangle.fill")
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedWallpaper == nil)
                    }

                    Spacer()

                    if didApply {
                        Label("Applied!", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: didApply)

                if !lockManager.applyStatus.isEmpty {
                    Text(lockManager.applyStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )

            // ── Info Note ─────────────────────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("macOS lock screen always mirrors your desktop wallpaper. Setting an image here will also update your desktop wallpaper on all connected displays.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)

            Spacer()
        }
    }

    // MARK: - Actions

    private func applyLockScreenWallpaper() {
        guard let wp = selectedWallpaper else { return }
        let url = URL(fileURLWithPath: wp.pathOrUrl)
        settings.lockScreenWallpaperId = wp.id
        settings.lockScreenImagePath = url.path   // persist for preview on next open
        lockManager.setStaticLockScreenWallpaper(url: url)
        didApply = true
        if let img = NSImage(contentsOfFile: url.path) {
            previewImage = img
        } else {
            refreshPreviewFromDesktop()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { didApply = false }
    }

    private func openImagePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.jpeg, .png, .heic, .tiff, .bmp, .gif]
        panel.message = "Choose an image for your lock screen"
        if panel.runModal() == .OK, let url = panel.url {
            settings.lockScreenImagePath = url.path   // persist for preview on next open
            lockManager.setStaticLockScreenWallpaper(url: url)
            if let img = NSImage(contentsOfFile: url.path) {
                previewImage = img
            } else if let img = NSImage(contentsOf: url) {
                previewImage = img
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    refreshPreviewFromDesktop()
                }
            }
            didApply = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { didApply = false }
        }
    }

    /// Load preview from the persisted lock screen image path in AppSettings.
    /// This is the most reliable source — it's the exact path we saved when the user last applied.
    private func loadSavedPreview() {
        let path = settings.lockScreenImagePath
        if !path.isEmpty, let img = NSImage(contentsOfFile: path) {
            previewImage = img
            return
        }
        // Fall back: try the selected wallpaper item's path
        loadPreviewImage()
        // Last resort: ask NSWorkspace what's currently set
        if previewImage == nil { refreshPreviewFromDesktop() }
    }

    /// Reads the current system desktop wallpaper via NSWorkspace — always valid
    /// since macOS just accepted it. Used as a guaranteed fallback for the preview.
    private func refreshPreviewFromDesktop() {
        for screen in NSScreen.screens {
            guard let url = NSWorkspace.shared.desktopImageURL(for: screen) else { continue }
            // Try .path first (more reliable for local files), then URL-based
            if let img = NSImage(contentsOfFile: url.path) {
                previewImage = img
                return
            } else if let img = NSImage(contentsOf: url) {
                previewImage = img
                return
            }
        }
    }

    // MARK: - Image Loading

    /// Loads the selected wallpaper image into `previewImage` state.
    /// Tries the absolute file path first, then bundle resources as a fallback.
    private func loadPreviewImage() {
        guard let wp = selectedWallpaper else {
            previewImage = nil
            return
        }

        // 1. Try direct absolute file path (user-imported images)
        if let img = NSImage(contentsOfFile: wp.pathOrUrl) {
            previewImage = img
            return
        }

        // 2. Try as a bundle resource path (built-in assets)
        if let resourcePath = Bundle.module.path(forResource: wp.pathOrUrl, ofType: nil, inDirectory: "Resources"),
           let img = NSImage(contentsOfFile: resourcePath) {
            previewImage = img
            return
        }

        // 3. Try the filename component inside the bundle Wallpapers folder
        let filename = (wp.pathOrUrl as NSString).lastPathComponent
        if let resourcePath = Bundle.module.path(forResource: filename, ofType: nil, inDirectory: "Resources/Wallpapers"),
           let img = NSImage(contentsOfFile: resourcePath) {
            previewImage = img
            return
        }

        // No image found — clear preview so the gradient shows
        previewImage = nil
    }

    private func updateTimeAndDate() {
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        currentTimeString = tf.string(from: Date())

        let df = DateFormatter()
        df.dateFormat = "EEEE, MMMM d"
        currentDateString = df.string(from: Date())
    }
}

// MARK: - Thumbnail Button

private struct WallpaperThumbnailButton: View {
    let item: WallpaperItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                Group {
                    if let img = NSImage(contentsOfFile: item.pathOrUrl) {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                        Image(systemName: item.thumbnailIcon)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 120, height: 80)
                .clipped()

                // Title strip
                Text(item.title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
            }
            .frame(width: 120, height: 80)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.purple : Color.white.opacity(0.12),
                            lineWidth: isSelected ? 2.5 : 1)
            )
            .shadow(color: isSelected ? Color.purple.opacity(0.4) : .clear, radius: 6)
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
