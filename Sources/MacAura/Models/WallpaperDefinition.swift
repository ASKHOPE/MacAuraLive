import Foundation

public struct SceneBackgroundConfig: Codable, Hashable {
    public let type: String // "solid", "gradient"
    public let colors: [String]
    
    public init(type: String = "gradient", colors: [String] = ["#040711", "#0b112c"]) {
        self.type = type
        self.colors = colors
    }
}

public struct SceneCameraConfig: Codable, Hashable {
    public let parallax: Double?
    
    public init(parallax: Double? = 0.1) {
        self.parallax = parallax
    }
}

public struct EffectConfig: Codable, Hashable, Identifiable {
    public var id: String { type }
    public let type: String // "rain", "snow", "stars", "aurora", "neon", "fog"
    public let enabled: Bool
    public var parameters: [String: String]
    
    public init(type: String, enabled: Bool = true, parameters: [String: String] = [:]) {
        self.type = type
        self.enabled = enabled
        self.parameters = parameters
    }
}

public struct AudioMappingConfig: Codable, Hashable {
    public let source: String // "bass", "mid", "treble", "energy"
    public let target: String // e.g., "rain.density"
    public let multiplier: Double
    public let smoothing: Double?
    
    public init(source: String, target: String, multiplier: Double = 1.0, smoothing: Double? = 0.8) {
        self.source = source
        self.target = target
        self.multiplier = multiplier
        self.smoothing = smoothing
    }
}

public struct WallpaperDefinition: Codable, Hashable {
    public let version: String
    public let name: String
    public let background: SceneBackgroundConfig?
    public let effects: [EffectConfig]
    public let audioMappings: [AudioMappingConfig]?
    public let camera: SceneCameraConfig?
    public let seed: Int?
    
    enum CodingKeys: String, CodingKey {
        case version
        case name
        case background
        case effects
        case audioMappings = "audio_mappings"
        case camera
        case seed
    }
    
    public init(
        version: String = "1.0",
        name: String,
        background: SceneBackgroundConfig? = SceneBackgroundConfig(),
        effects: [EffectConfig],
        audioMappings: [AudioMappingConfig]? = nil,
        camera: SceneCameraConfig? = SceneCameraConfig(),
        seed: Int? = 1001
    ) {
        self.version = version
        self.name = name
        self.background = background
        self.effects = effects
        self.audioMappings = audioMappings
        self.camera = camera
        self.seed = seed
    }
}
