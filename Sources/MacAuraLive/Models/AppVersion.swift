import Foundation

/// Centralized dynamic version resolution provider
public struct AppVersion: Codable {
    public let version: String
    public let build: String
    public let channel: String
    public let minOS: String
    
    public static let fallbackVersion = "1.9.4"
    public static let fallbackBuild = "1.9.4"
    
    /// Global dynamic singleton resolved at runtime
    public static let current: AppVersion = {
        // 1. Try reading from Bundle Info.plist (Standard inside .app bundle)
        let infoDict = Bundle.main.infoDictionary
        let bundleVersion = infoDict?["CFBundleShortVersionString"] as? String
        let bundleBuild = infoDict?["CFBundleVersion"] as? String
        
        // 2. Try loading bundled or relative version.json
        if let jsonVersion = loadFromJSON() {
            return jsonVersion
        }
        
        // 3. Fallback to Bundle info or static defaults
        let finalVersion = bundleVersion ?? fallbackVersion
        let finalBuild = bundleBuild ?? fallbackBuild
        return AppVersion(version: finalVersion, build: finalBuild, channel: "stable", minOS: "13.0")
    }()
    
    public var fullVersionString: String {
        if build.isEmpty || build == version {
            return "v\(version)"
        }
        return "v\(version) (\(build))"
    }
    
    private static func loadFromJSON() -> AppVersion? {
        // Search in main bundle resources
        if let url = Bundle.main.url(forResource: "version", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(AppVersion.self, from: data) {
            return decoded
        }
        
        // Search in module resources if available
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: "version", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(AppVersion.self, from: data) {
            return decoded
        }
        #endif
        
        // Search in root directory (development fallback)
        let localPath = "version.json"
        if FileManager.default.fileExists(atPath: localPath),
           let data = try? Data(contentsOf: URL(fileURLWithPath: localPath)),
           let decoded = try? JSONDecoder().decode(AppVersion.self, from: data) {
            return decoded
        }
        
        return nil
    }
}
