import Foundation

public enum WallpaperType: String, Codable, CaseIterable {
    case builtInWeb
    case video
    case gif
    case image
    case webUrl
}

public struct WallpaperItem: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var category: String // "MP4 Video", "GIF", "GenAI"
    public var resolutionTag: String // "1080p", "2K", "4K UHD", "Dynamic"
    public var type: WallpaperType
    public var pathOrUrl: String
    public var thumbnailIcon: String
    public var hasAudio: Bool
    public var author: String
    public var description: String
    
    // SDK customization and structured manifest metadata support
    public var manifest: WallpaperManifest?
    public var customSettings: [String: String]?
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        category: String = "GenAI",
        resolutionTag: String = "4K UHD",
        type: WallpaperType,
        pathOrUrl: String,
        thumbnailIcon: String = "sparkles",
        hasAudio: Bool = false,
        author: String = "MacAuraLive",
        description: String = "",
        manifest: WallpaperManifest? = nil,
        customSettings: [String: String]? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.resolutionTag = resolutionTag
        self.type = type
        self.pathOrUrl = pathOrUrl
        self.thumbnailIcon = thumbnailIcon
        self.hasAudio = hasAudio
        self.author = author
        self.description = description
        self.manifest = manifest
        self.customSettings = customSettings
    }
}
