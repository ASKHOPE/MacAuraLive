import Foundation

public enum WallpaperSourceProvider: String, CaseIterable, Identifiable, Codable {
    case all = "All Providers"
    case unsplash = "Unsplash"
    case pixabay = "Pixabay"
    case pexels = "Pexels"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .all: return "globe"
        case .unsplash: return "camera.fill"
        case .pixabay: return "photo.stack.fill"
        case .pexels: return "film.stack.fill"
        }
    }
    
    public var brandColorHex: String {
        switch self {
        case .all: return "#00f2fe"
        case .unsplash: return "#111111"
        case .pixabay: return "#02be6e"
        case .pexels: return "#05a081"
        }
    }
    
    public var termsUrl: String {
        switch self {
        case .all: return "https://macauralive.app/terms"
        case .unsplash: return "https://unsplash.com/terms"
        case .pixabay: return "https://pixabay.com/service/terms/"
        case .pexels: return "https://www.pexels.com/terms/"
        }
    }
    
    public var licenseUrl: String {
        switch self {
        case .all: return "https://macauralive.app/license"
        case .unsplash: return "https://unsplash.com/license"
        case .pixabay: return "https://pixabay.com/service/license-summary/"
        case .pexels: return "https://www.pexels.com/license/"
        }
    }
    
    public var developerPortalUrl: String {
        switch self {
        case .all: return "https://macauralive.app"
        case .unsplash: return "https://unsplash.com/developers"
        case .pixabay: return "https://pixabay.com/api/docs/"
        case .pexels: return "https://www.pexels.com/api/"
        }
    }
    
    public var attributionRequirementNotice: String {
        switch self {
        case .all:
            return "Content from each provider must be credited according to their respective guidelines."
        case .unsplash:
            return "Photos provided under the Unsplash License. Attribute photographers with direct profile links."
        case .pixabay:
            return "Free for commercial and personal use under the Pixabay Content License. No attribution strictly required, but appreciated."
        case .pexels:
            return "Free to use under the Pexels License. Giving credit to the photographer or Pexels is appreciated."
        }
    }
}

public struct OnlineWallpaperItem: Identifiable, Hashable, Codable {
    public let id: String
    public let provider: WallpaperSourceProvider
    public let title: String
    public let authorName: String
    public let authorUrl: String?
    public let authorAvatarUrl: String?
    public let previewUrl: String
    public let downloadUrl: String
    public let mediaType: WallpaperType // .image or .video
    public let resolutionTag: String
    public let width: Int?
    public let height: Int?
    public let durationSeconds: Double?
    public let hasAudio: Bool
    public let licenseNotice: String
    public let sourcePageUrl: String?
    
    public init(
        id: String = UUID().uuidString,
        provider: WallpaperSourceProvider,
        title: String,
        authorName: String,
        authorUrl: String? = nil,
        authorAvatarUrl: String? = nil,
        previewUrl: String,
        downloadUrl: String,
        mediaType: WallpaperType,
        resolutionTag: String = "4K UHD",
        width: Int? = nil,
        height: Int? = nil,
        durationSeconds: Double? = nil,
        hasAudio: Bool = false,
        licenseNotice: String = "Free for Personal Use",
        sourcePageUrl: String? = nil
    ) {
        self.id = id
        self.provider = provider
        self.title = title
        self.authorName = authorName
        self.authorUrl = authorUrl
        self.authorAvatarUrl = authorAvatarUrl
        self.previewUrl = previewUrl
        self.downloadUrl = downloadUrl
        self.mediaType = mediaType
        self.resolutionTag = resolutionTag
        self.width = width
        self.height = height
        self.durationSeconds = durationSeconds
        self.hasAudio = hasAudio
        self.licenseNotice = licenseNotice
        self.sourcePageUrl = sourcePageUrl
    }
}

public protocol OnlineWallpaperPlugin {
    var provider: WallpaperSourceProvider { get }
    var isConfigured: Bool { get }
    var apiKey: String { get set }
    
    func fetchWallpapers(
        query: String,
        page: Int,
        perPage: Int,
        mediaType: WallpaperType?
    ) async throws -> [OnlineWallpaperItem]
    
    func testConnection() async -> (success: Bool, message: String)
}
