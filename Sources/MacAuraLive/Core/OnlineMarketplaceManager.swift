import Foundation
import Combine
import AppKit

@MainActor
public class OnlineMarketplaceManager: ObservableObject {
    public static let shared = OnlineMarketplaceManager()
    
    @Published public var wallpapers: [OnlineWallpaperItem] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var selectedProvider: WallpaperSourceProvider = .all
    @Published public var selectedMediaTypeFilter: WallpaperType? = nil // nil = all, .image = static, .video = live
    @Published public var searchQuery: String = ""
    @Published public var activeTag: String = "All"
    
    // Download Tracking
    @Published public var downloadingItemIds: Set<String> = []
    @Published public var downloadProgress: [String: Double] = [:]
    @Published public var downloadedItemIds: Set<String> = []
    @Published public var statusToast: String? = nil
    
    // Plugins
    public let unsplashPlugin = UnsplashPlugin()
    public let pixabayPlugin = PixabayPlugin()
    public let pexelsPlugin = PexelsPlugin()
    
    public var plugins: [OnlineWallpaperPlugin] {
        return [unsplashPlugin, pixabayPlugin, pexelsPlugin]
    }
    
    private let downloadsDirectory: URL
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        self.downloadsDirectory = appSupport
            .appendingPathComponent("MacAuraLive", isDirectory: true)
            .appendingPathComponent("Wallpapers", isDirectory: true)
            .appendingPathComponent("Downloads", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
        
        refreshDownloadedItems()
        
        // Initial fetch
        Task {
            await self.fetchMarketplaceWallpapers()
        }
    }
    
    public func refreshDownloadedItems() {
        let currentLocal = Set(WallpaperStorageManager.shared.wallpapers.map { $0.id })
        self.downloadedItemIds = currentLocal
    }
    
    public func fetchMarketplaceWallpapers() async {
        self.isLoading = true
        self.errorMessage = nil
        
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveQuery = query.isEmpty ? (activeTag == "All" ? "" : activeTag) : query
        let mediaFilter = self.selectedMediaTypeFilter
        
        let targetPlugins: [OnlineWallpaperPlugin]
        switch selectedProvider {
        case .all:
            targetPlugins = plugins
        case .unsplash:
            targetPlugins = [unsplashPlugin]
        case .pixabay:
            targetPlugins = [pixabayPlugin]
        case .pexels:
            targetPlugins = [pexelsPlugin]
        }
        
        var combined: [OnlineWallpaperItem] = []
        var errors: [String] = []
        
        for plugin in targetPlugins {
            do {
                let items = try await plugin.fetchWallpapers(
                    query: effectiveQuery,
                    page: 1,
                    perPage: 25,
                    mediaType: mediaFilter
                )
                combined.append(contentsOf: items)
            } catch {
                errors.append("\(plugin.provider.rawValue): \(error.localizedDescription)")
            }
        }
        
        // Filter by mediaType if selected
        if let mediaFilter = mediaFilter {
            combined = combined.filter { $0.mediaType == mediaFilter }
        }
        
        // Remove duplicates and sort
        var seenIds = Set<String>()
        var deduplicated: [OnlineWallpaperItem] = []
        for item in combined {
            if !seenIds.contains(item.id) {
                seenIds.insert(item.id)
                deduplicated.append(item)
            }
        }
        
        self.wallpapers = deduplicated
        self.isLoading = false
        if !errors.isEmpty && deduplicated.isEmpty {
            self.errorMessage = errors.joined(separator: "\n")
        }
    }
    
    public func downloadAndInstallWallpaper(_ item: OnlineWallpaperItem, applyImmediately: Bool = true) async -> Bool {
        self.downloadingItemIds.insert(item.id)
        self.downloadProgress[item.id] = 0.1
        
        guard let remoteURL = URL(string: item.downloadUrl) else {
            self.downloadingItemIds.remove(item.id)
            self.downloadProgress.removeValue(forKey: item.id)
            self.statusToast = "Invalid download URL for \(item.title)"
            return false
        }
        
        let providerFolder = downloadsDirectory.appendingPathComponent(item.provider.rawValue, isDirectory: true)
        try? FileManager.default.createDirectory(at: providerFolder, withIntermediateDirectories: true)
        
        let ext = item.mediaType == .video ? "mp4" : "jpg"
        let safeTitle = item.title
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
        let filename = "\(item.id)_\(safeTitle).\(ext)"
        let destinationURL = providerFolder.appendingPathComponent(filename)
        
        do {
            self.downloadProgress[item.id] = 0.3
            
            var request = URLRequest(url: remoteURL)
            request.timeoutInterval = 60.0
            
            // If Unsplash requires Client-ID on raw downloads
            if item.provider == .unsplash && unsplashPlugin.isConfigured {
                request.setValue("Client-ID \(unsplashPlugin.apiKey)", forHTTPHeaderField: "Authorization")
            }
            
            let (tempLocalURL, response) = try await URLSession.shared.download(for: request)
            
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "MarketplaceDownload", code: 400, userInfo: [NSLocalizedDescriptionKey: "Server returned HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)"])
            }
            
            self.downloadProgress[item.id] = 0.8
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try? FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.moveItem(at: tempLocalURL, to: destinationURL)
            
            // Create local WallpaperItem
            let categoryName = item.mediaType == .video ? "MP4 Video" : "Static"
            let iconName = item.mediaType == .video ? "play.rectangle.fill" : "photo.fill"
            let authorCred = "\(item.authorName) (\(item.provider.rawValue))"
            let desc = "\(item.title). License: \(item.licenseNotice). Downloaded from \(item.provider.rawValue)."
            
            let localItem = WallpaperItem(
                id: item.id,
                title: item.title,
                category: categoryName,
                resolutionTag: item.resolutionTag,
                type: item.mediaType,
                pathOrUrl: destinationURL.path,
                thumbnailIcon: iconName,
                hasAudio: item.hasAudio,
                author: authorCred,
                description: desc
            )
            
            // Remove existing if any
            WallpaperStorageManager.shared.wallpapers.removeAll(where: { $0.id == item.id })
            WallpaperStorageManager.shared.wallpapers.append(localItem)
            WallpaperStorageManager.shared.saveCustomWallpapers()
            
            self.downloadedItemIds.insert(item.id)
            self.downloadingItemIds.remove(item.id)
            self.downloadProgress.removeValue(forKey: item.id)
            
            if applyImmediately {
                WallpaperStorageManager.shared.setActiveWallpaper(localItem)
                self.statusToast = "Downloaded & set '\(item.title)' as wallpaper!"
            } else {
                self.statusToast = "Saved '\(item.title)' to your local library!"
            }
            
            return true
        } catch {
            self.downloadingItemIds.remove(item.id)
            self.downloadProgress.removeValue(forKey: item.id)
            self.statusToast = "Download failed: \(error.localizedDescription)"
            return false
        }
    }
}
