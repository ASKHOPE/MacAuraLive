import Foundation

public enum MoodPlaybackMode: String, Codable, CaseIterable {
    case single = "Single Active Wallpaper"
    case randomCycle = "Shuffle & Cycle"
    case sequenceCycle = "Sequential Cycle"
}

public enum LinkedMacOSMode: String, Codable, CaseIterable {
    case none = "Manual Only (No Trigger)"
    case doNotDisturb = "Do Not Disturb / Focus Mode"
    case sleep = "macOS Sleep / Screen Dimmed"
    case appearanceDark = "System Dark Mode"
    case appearanceLight = "System Light Mode"
    case powerBattery = "On Battery Power"
    case powerAC = "On AC Power / Plugged In"
    
    public var iconName: String {
        switch self {
        case .none: return "hand.tap.fill"
        case .doNotDisturb: return "moon.fill"
        case .sleep: return "powersleep"
        case .appearanceDark: return "moon.stars.fill"
        case .appearanceLight: return "sun.max.fill"
        case .powerBattery: return "battery.75"
        case .powerAC: return "bolt.fill"
        }
    }
}

public struct MoodProfile: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var description: String
    public var icon: String
    public var accentColorHex: String
    public var wallpaperIDs: [String]
    public var playbackMode: MoodPlaybackMode
    public var cycleIntervalMinutes: Double
    public var isMuted: Bool?
    public var linkedMode: LinkedMacOSMode
    public var isBuiltIn: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String = "",
        icon: String = "sparkles",
        accentColorHex: String = "#8A2BE2",
        wallpaperIDs: [String] = [],
        playbackMode: MoodPlaybackMode = .single,
        cycleIntervalMinutes: Double = 15.0,
        isMuted: Bool? = nil,
        linkedMode: LinkedMacOSMode = .none,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.accentColorHex = accentColorHex
        self.wallpaperIDs = wallpaperIDs
        self.playbackMode = playbackMode
        self.cycleIntervalMinutes = cycleIntervalMinutes
        self.isMuted = isMuted
        self.linkedMode = linkedMode
        self.isBuiltIn = isBuiltIn
    }
}
