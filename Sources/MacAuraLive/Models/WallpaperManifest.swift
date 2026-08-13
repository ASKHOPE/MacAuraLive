import Foundation

public struct WallpaperSettingSchema: Codable, Hashable, Identifiable {
    public var id: String { key }
    public let key: String
    public let type: String // "color", "slider", "toggle", "text"
    public let label: String
    public let defaultValue: String // String-encoded value: "#ff0088", "300", "true", etc.
    public let min: Double?
    public let max: Double?
    
    enum CodingKeys: String, CodingKey {
        case key
        case type
        case label
        case defaultValue = "default"
        case min
        case max
    }
}

public struct WallpaperPerformanceConfig: Codable, Hashable {
    public let targetFps: Int?
    public let allowThrottle: Bool?
    
    enum CodingKeys: String, CodingKey {
        case targetFps = "target_fps"
        case allowThrottle = "allow_throttle"
    }
}

public struct WallpaperManifest: Codable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let version: String
    public let author: String
    public let type: String // "webgl", "canvas2d", "legacy"
    public let entryPoint: String
    public let performance: WallpaperPerformanceConfig?
    public let settings: [WallpaperSettingSchema]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case version
        case author
        case type
        case entryPoint = "entry_point"
        case performance
        case settings
    }
}
