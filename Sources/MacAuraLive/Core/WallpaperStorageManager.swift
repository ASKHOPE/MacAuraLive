import Foundation
import Combine
import AVFoundation
import AppKit

public class WallpaperStorageManager: ObservableObject {
    public static let shared = WallpaperStorageManager()
    
    @Published public var wallpapers: [WallpaperItem] = []
    @Published public var activeWallpaperId: String = "aurora"
    @Published public var referencedFolderURL: String? {
        didSet {
            UserDefaults.standard.set(referencedFolderURL, forKey: "referencedFolderURL")
        }
    }
    
    private let appSupportDirectory: URL
    private let wallpapersDirectory: URL
    private let metaFileURL: URL
    
    private init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        self.appSupportDirectory = appSupport.appendingPathComponent("MacAuraLive", isDirectory: true)
        self.wallpapersDirectory = appSupportDirectory.appendingPathComponent("Wallpapers", isDirectory: true)
        self.metaFileURL = appSupportDirectory.appendingPathComponent("wallpapers.json")
        self.referencedFolderURL = UserDefaults.standard.string(forKey: "referencedFolderURL")
        
        try? fileManager.createDirectory(at: wallpapersDirectory, withIntermediateDirectories: true)
        setupDefaultDocumentDirectories()
        
        loadWallpapers()
    }
    
    public var userDocumentsRootURL: URL? {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return docsURL.appendingPathComponent("MacAuraLiveApp", isDirectory: true)
    }
    
    public var documentsDirectory: URL {
        return userDocumentsRootURL ?? appSupportDirectory
    }
    
    public func targetDirectory(for type: WallpaperType) -> URL {
        let root = userDocumentsRootURL ?? appSupportDirectory
        let subfolder: String
        switch type {
        case .video:
            subfolder = "livewallpaper"
        case .image:
            subfolder = "staticwallpaper"
        case .gif:
            subfolder = "gif"
        case .builtInWeb, .webUrl:
            subfolder = "animatedcode"
        }
        let target = root.appendingPathComponent(subfolder, isDirectory: true)
        if !FileManager.default.fileExists(atPath: target.path) {
            try? FileManager.default.createDirectory(at: target, withIntermediateDirectories: true, attributes: nil)
        }
        return target
    }
    
    private func setupDefaultDocumentDirectories() {
        let fm = FileManager.default
        guard let macauraRoot = userDocumentsRootURL else { return }
        
        let subfolders = ["livewallpaper", "staticwallpaper", "gif", "animatedcode"]
        for sub in subfolders {
            let folderURL = macauraRoot.appendingPathComponent(sub, isDirectory: true)
            if !fm.fileExists(atPath: folderURL.path) {
                try? fm.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            }
        }
        
        copyBundledWallpapersToUserDocuments()
    }
    
    public func copyBundledWallpapersToUserDocuments() {
        guard let root = userDocumentsRootURL else { return }
        let fm = FileManager.default
        
        let staticDir = root.appendingPathComponent("staticwallpaper", isDirectory: true)
        let liveDir = root.appendingPathComponent("livewallpaper", isDirectory: true)
        let codeDir = root.appendingPathComponent("animatedcode", isDirectory: true)
        
        // Bundle copy helper
        func copyResource(subpath: String, to destinationURL: URL) {
            if !fm.fileExists(atPath: destinationURL.path) {
                if let src = Bundle.module.url(forResource: subpath, withExtension: nil, subdirectory: "Resources/Wallpapers") ??
                             Bundle.module.url(forResource: subpath, withExtension: nil, subdirectory: "Resources") ??
                             Bundle.module.url(forResource: "Wallpapers/\(subpath)", withExtension: nil) {
                    try? fm.copyItem(at: src, to: destinationURL)
                    print("[WallpaperStorageManager] Successfully extracted \(subpath) to \(destinationURL.path)")
                }
            }
        }
        
        copyResource(subpath: "Static/TurbulentOcean/wallpaper.jpg", to: staticDir.appendingPathComponent("turbulent_ocean.jpg"))
        copyResource(subpath: "Static/MountainRidges/wallpaper.jpg", to: staticDir.appendingPathComponent("mountain_ridges.jpg"))
        copyResource(subpath: "Static/BlueCurves/wallpaper.jpg", to: staticDir.appendingPathComponent("blue_curves.jpg"))
        copyResource(subpath: "Static/DeepSpaceNebula/wallpaper.jpg", to: staticDir.appendingPathComponent("deep_space_nebula.jpg"))
        copyResource(subpath: "Static/AlpineGlacier/wallpaper.jpg", to: staticDir.appendingPathComponent("alpine_glacier.jpg"))
        copyResource(subpath: "Video/ShivaayWaves/wallpaper.mp4", to: liveDir.appendingPathComponent("shivaay_waves.mp4"))
    }
    
    public func resolveURL(for wallpaper: WallpaperItem) -> URL? {
        return resolveURL(forPath: wallpaper.pathOrUrl)
    }
    
    public func resolveURL(forPath pathOrUrl: String) -> URL? {
        let fm = FileManager.default
        
        // 1. Direct Web URL
        if pathOrUrl.hasPrefix("http://") || pathOrUrl.hasPrefix("https://") {
            return URL(string: pathOrUrl)
        }
        
        // 2. Direct Absolute File Path
        if fm.fileExists(atPath: pathOrUrl) {
            return URL(fileURLWithPath: pathOrUrl)
        }
        
        // 3. User Documents Directory (~/Documents/MacAuraLiveApp/)
        if let docsRoot = userDocumentsRootURL {
            let directDocs = docsRoot.appendingPathComponent(pathOrUrl)
            if fm.fileExists(atPath: directDocs.path) { return directDocs }
            
            let lastComponent = (pathOrUrl as NSString).lastPathComponent
            for sub in ["livewallpaper", "staticwallpaper", "gif", "animatedcode"] {
                let subDirect = docsRoot.appendingPathComponent(sub).appendingPathComponent(pathOrUrl)
                if fm.fileExists(atPath: subDirect.path) { return subDirect }
                
                let subByFileName = docsRoot.appendingPathComponent(sub).appendingPathComponent(lastComponent)
                if fm.fileExists(atPath: subByFileName.path) { return subByFileName }
            }
        }
        
        // 4. Swift Package Bundle Resources
        if let bundleURL = Bundle.module.url(forResource: pathOrUrl, withExtension: nil, subdirectory: "Resources/Wallpapers") ??
                           Bundle.module.url(forResource: pathOrUrl, withExtension: nil, subdirectory: "Resources") ??
                           Bundle.module.url(forResource: "Wallpapers/\(pathOrUrl)", withExtension: nil) ??
                           Bundle.module.url(forResource: (pathOrUrl as NSString).lastPathComponent, withExtension: nil) {
            return bundleURL
        }
        
        // 5. Application Support Directory Fallback
        let appSupportDirect = appSupportDirectory.appendingPathComponent("Wallpapers/\(pathOrUrl)")
        if fm.fileExists(atPath: appSupportDirect.path) { return appSupportDirect }
        
        return nil
    }
    
    public func resolveImage(for wallpaper: WallpaperItem) -> NSImage? {
        return resolveImage(forPath: wallpaper.pathOrUrl)
    }
    
    public func resolveImage(forPath pathOrUrl: String) -> NSImage? {
        if let url = resolveURL(forPath: pathOrUrl), url.isFileURL {
            if let img = NSImage(contentsOf: url) {
                return img
            }
        }
        if FileManager.default.fileExists(atPath: pathOrUrl),
           let img = NSImage(contentsOfFile: pathOrUrl) {
            return img
        }
        return nil
    }
    
    public func loadWallpapers() {
        setupDefaultDocumentDirectories()
        var items = getBuiltInWallpapers()
        
        if FileManager.default.fileExists(atPath: metaFileURL.path),
           let data = try? Data(contentsOf: metaFileURL),
           let saved = try? JSONDecoder().decode([WallpaperItem].self, from: data) {
            let builtInIds = Set(items.map { $0.id })
            var customItems = saved.filter { !builtInIds.contains($0.id) }
            
            // Removed expensive audio re-verification that triggered repeated permission prompts
            
            items.append(contentsOf: customItems)
        }
        
        self.wallpapers = items
        
        if let savedActiveId = UserDefaults.standard.string(forKey: "activeWallpaperId"),
           items.contains(where: { $0.id == savedActiveId }) {
            self.activeWallpaperId = savedActiveId
        } else if let first = items.first {
            self.activeWallpaperId = first.id
        }
    }
    
    // AVAssetReader PCM Audio Peak & RMS Waveform Sample Analyzer
    private func checkHasAudio(url: URL) -> Bool {
        let asset = AVAsset(url: url)
        let audioTracks: [AVAssetTrack]
        if #available(macOS 13.0, *) {
            let semaphore = DispatchSemaphore(value: 0)
            var loadedTracks: [AVAssetTrack] = []
            Task {
                loadedTracks = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 1.0)
            audioTracks = loadedTracks
        } else {
            audioTracks = asset.tracks(withMediaType: .audio)
        }
        guard !audioTracks.isEmpty, let track = audioTracks.first else { return false }
        
        guard let reader = try? AVAssetReader(asset: asset) else { return false }
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        reader.add(trackOutput)
        
        guard reader.startReading() else { return false }
        
        var maxAmplitude: Float = 0.0
        var totalSamplesRead = 0
        
        while reader.status == .reading && totalSamplesRead < 44100 * 5 {
            guard let sampleBuffer = trackOutput.copyNextSampleBuffer(),
                  let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { break }
            
            let length = CMBlockBufferGetDataLength(blockBuffer)
            var buffer = [Int16](repeating: 0, count: length / 2)
            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: &buffer)
            
            for sample in buffer {
                let norm = abs(Float(sample) / 32768.0)
                if norm > maxAmplitude {
                    maxAmplitude = norm
                }
            }
            totalSamplesRead += buffer.count
            if maxAmplitude > 0.02 { break }
        }
        
        reader.cancelReading()
        return maxAmplitude > 0.005
    }
    
    public func getBuiltInWallpapers() -> [WallpaperItem] {
        return [
            WallpaperItem(
                id: "aurora",
                title: "Aurora Borealis",
                category: "GenAI",
                resolutionTag: "4K UHD",
                type: .builtInWeb,
                pathOrUrl: "Live/Aurora/index.html",
                thumbnailIcon: "sparkles",
                hasAudio: false,
                author: "GenAI Engine",
                description: "Hardware-accelerated glowing northern lights shader canvas."
            ),
            WallpaperItem(
                id: "matrix",
                title: "Matrix Code Rain",
                category: "GenAI",
                resolutionTag: "4K UHD",
                type: .builtInWeb,
                pathOrUrl: "Live/Matrix/index.html",
                thumbnailIcon: "terminal.fill",
                hasAudio: false,
                author: "GenAI Engine",
                description: "Classic digital code rain with glowing characters."
            ),
            WallpaperItem(
                id: "cyberpunk",
                title: "Cyberpunk Synthwave",
                category: "GenAI",
                resolutionTag: "4K UHD",
                type: .builtInWeb,
                pathOrUrl: "Live/Cyberpunk/index.html",
                thumbnailIcon: "sun.max.fill",
                hasAudio: false,
                author: "GenAI Engine",
                description: "Retro 80s synthwave neon perspective grid & sun."
            ),
            WallpaperItem(
                id: "particlewave",
                title: "3D Particle Waves",
                category: "GenAI",
                resolutionTag: "4K UHD",
                type: .builtInWeb,
                pathOrUrl: "Live/ParticleWave/index.html",
                thumbnailIcon: "waveform.path",
                hasAudio: false,
                author: "GenAI Engine",
                description: "Flowing 3D particle sine wave grid."
            ),
            WallpaperItem(
                id: "turbulent_ocean",
                title: "Turbulent Ocean Water",
                category: "Nature",
                resolutionTag: "5K Retina",
                type: .image,
                pathOrUrl: "Static/TurbulentOcean/wallpaper.jpg",
                thumbnailIcon: "water.waves",
                hasAudio: false,
                author: "Kristaps Ungurs (Unsplash)",
                description: "Turbulent ocean water swirls and crashes in pristine 5K uncompressed resolution (5272x3948). Photo by Kristaps Ungurs."
            ),
            WallpaperItem(
                id: "mountain_ridges",
                title: "Abstract Mountain Ridges",
                category: "Abstract",
                resolutionTag: "6K UHD",
                type: .image,
                pathOrUrl: "Static/MountainRidges/wallpaper.jpg",
                thumbnailIcon: "waveform",
                hasAudio: false,
                author: "Oxana Golubets (Unsplash)",
                description: "Abstract waves resembling mountain ridges in ultra-crisp 6K resolution (6000x4000). Photo by Oxana Golubets."
            ),
            WallpaperItem(
                id: "blue_curves",
                title: "Abstract Blue Curves",
                category: "Abstract",
                resolutionTag: "5K Retina",
                type: .image,
                pathOrUrl: "Static/BlueCurves/wallpaper.jpg",
                thumbnailIcon: "sparkles",
                hasAudio: false,
                author: "Jacob Buchhave (Unsplash)",
                description: "Elegant layered abstract curves in ultra-sharp 5.5K resolution (5464x3640). Photo by Jacob Buchhave."
            ),
            WallpaperItem(
                id: "deep_space_nebula",
                title: "Deep Space Cosmic Nebula",
                category: "Abstract",
                resolutionTag: "4K UHD",
                type: .image,
                pathOrUrl: "Static/DeepSpaceNebula/wallpaper.jpg",
                thumbnailIcon: "sparkles",
                hasAudio: false,
                author: "MacAuraLive Core",
                description: "Pristine 4K UHD abstract deep space cosmic nebula and star clusters (3840x2160)."
            ),
            WallpaperItem(
                id: "alpine_glacier",
                title: "Majestic Alpine Glacier",
                category: "Nature",
                resolutionTag: "9K Master",
                type: .image,
                pathOrUrl: "Static/AlpineGlacier/wallpaper.jpg",
                thumbnailIcon: "mountain.2.fill",
                hasAudio: false,
                author: "Hassaan Here (Unsplash)",
                description: "Breathtaking snowy mountain peaks in massive 9K master resolution (9000x6000). Photo by Hassaan Here."
            ),
            WallpaperItem(
                id: "shivaay_waves",
                title: "Abstract Blue Waves Motion",
                category: "MP4 Video",
                resolutionTag: "4K UHD",
                type: .video,
                pathOrUrl: "Video/ShivaayWaves/wallpaper.mp4",
                thumbnailIcon: "play.rectangle.fill",
                hasAudio: true,
                author: "Shivaay Singh (Pixabay)",
                description: "Close-up abstract motion video of blue and black waves with audio. Video by Shivaay Singh on Pixabay."
            )
        ]
    }
    
    public func setActiveWallpaper(_ wallpaper: WallpaperItem) {
        self.activeWallpaperId = wallpaper.id
        UserDefaults.standard.set(wallpaper.id, forKey: "activeWallpaperId")
        
        // Always sync lockscreen wallpaper with desktop wallpaper unless user disabled lockscreen sync
        if AppSettings.shared.enableLockScreenWallpaper {
            AppSettings.shared.lockScreenWallpaperId = wallpaper.id
        }
        
        objectWillChange.send()
        
        WallpaperEngine.shared.isPaused = false
        WallpaperEngine.shared.reloadEngine()
    }
    
    public func getActiveWallpaper() -> WallpaperItem? {
        return wallpapers.first(where: { $0.id == activeWallpaperId }) ?? wallpapers.first
    }
    
    public func updateWallpaperSetting(id: String, key: String, value: String) {
        guard let index = wallpapers.firstIndex(where: { $0.id == id }) else { return }
        var item = wallpapers[index]
        var custom = item.customSettings ?? [:]
        custom[key] = value
        item.customSettings = custom
        wallpapers[index] = item
        
        saveCustomWallpapers()
        
        if activeWallpaperId == id {
            if let data = try? JSONSerialization.data(withJSONObject: custom),
               let jsonString = String(data: data, encoding: .utf8) {
                WallpaperEngine.shared.updateActiveWallpaperSettings(jsonString)
            }
        }
    }

    public func matchLocalIntent(prompt: String) -> WallpaperDefinition? {
        let lower = prompt.lowercased()
        let name = prompt.capitalized
        
        if lower.contains("rain") || lower.contains("storm") || lower.contains("water") {
            let isHeavy = lower.contains("heavy")
            return WallpaperDefinition(
                name: name,
                background: SceneBackgroundConfig(colors: ["#02040a", "#091224"]),
                effects: [
                    EffectConfig(type: "rain", parameters: ["density": isHeavy ? "450" : "250", "speed": isHeavy ? "1.6" : "1.0", "wind": "0.3"])
                ],
                audioMappings: [
                    AudioMappingConfig(source: "bass", target: "rain.speed", multiplier: 1.2)
                ]
            )
        } else if lower.contains("snow") || lower.contains("blizzard") || lower.contains("winter") {
            return WallpaperDefinition(
                name: name,
                background: SceneBackgroundConfig(colors: ["#050b14", "#111c30"]),
                effects: [
                    EffectConfig(type: "snow", parameters: ["density": "300", "speed": "1.2", "color": "#ffffff"])
                ],
                audioMappings: [
                    AudioMappingConfig(source: "mid", target: "snow.speed", multiplier: 0.8)
                ]
            )
        } else if lower.contains("space") || lower.contains("star") || lower.contains("cosmos") || lower.contains("galaxy") {
            return WallpaperDefinition(
                name: name,
                background: SceneBackgroundConfig(colors: ["#010206", "#060919"]),
                effects: [
                    EffectConfig(type: "stars", parameters: ["density": "400", "speed": "6.0", "color": "#c8dcff"])
                ],
                audioMappings: [
                    AudioMappingConfig(source: "energy", target: "stars.speed", multiplier: 3.0)
                ]
            )
        } else if lower.contains("aurora") || lower.contains("lights") || lower.contains("northern") {
            return WallpaperDefinition(
                name: name,
                background: SceneBackgroundConfig(colors: ["#020813", "#08182b"]),
                effects: [
                    EffectConfig(type: "aurora", parameters: ["speed": "1.0", "colorStart": "#00f2fe", "colorEnd": "#4facfe"])
                ],
                audioMappings: [
                    AudioMappingConfig(source: "bass", target: "aurora.opacity", multiplier: 0.5)
                ]
            )
        } else if lower.contains("neon") || lower.contains("cyberpunk") || lower.contains("grid") || lower.contains("synthwave") {
            return WallpaperDefinition(
                name: name,
                background: SceneBackgroundConfig(colors: ["#0d021a", "#260438"]),
                effects: [
                    EffectConfig(type: "neon", parameters: ["speed": "1.0", "color": "#ff007f", "intensity": "1.0"])
                ],
                audioMappings: [
                    AudioMappingConfig(source: "bass", target: "neon.intensity", multiplier: 0.8)
                ]
            )
        }
        return nil
    }

    public func generateGenAIWallpaper(prompt: String, style: String, resolution: String, htmlCode: String? = nil) -> WallpaperItem? {
        let cleanPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanPrompt.isEmpty else { return nil }
        
        let wallpaperID = "genai_" + UUID().uuidString
        let bundleURL = wallpapersDirectory.appendingPathComponent(wallpaperID, isDirectory: true)
        let coreDir = bundleURL.appendingPathComponent("Core", isDirectory: true)
        let effectsDir = bundleURL.appendingPathComponent("Effects", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: coreDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: effectsDir, withIntermediateDirectories: true)
        
        var definition: WallpaperDefinition? = nil
        
        // 1. Try Local Intent Matcher (Instant zero-latency load)
        definition = matchLocalIntent(prompt: cleanPrompt)
        
        // 2. If no local match, parse LLM WallpaperDefinition JSON output
        if definition == nil, let code = htmlCode, !code.isEmpty {
            if let data = code.data(using: .utf8) {
                definition = try? JSONDecoder().decode(WallpaperDefinition.self, from: data)
            }
        }
        
        // 3. Fallback to default Sine Waves scene definition
        if definition == nil {
            definition = WallpaperDefinition(
                name: cleanPrompt.capitalized,
                background: SceneBackgroundConfig(colors: ["#02050e", "#100424"]),
                effects: [
                    EffectConfig(type: "aurora", parameters: ["speed": "0.8", "colorStart": "#ff007f", "colorEnd": "#00f2fe"])
                ],
                audioMappings: [
                    AudioMappingConfig(source: "bass", target: "aurora.speed", multiplier: 1.5)
                ]
            )
        }
        
        guard let finalDef = definition else { return nil }
        
        // Write scene.json definition and scene.js fallback for WebKit file:// origin compatibility
        let sceneURL = bundleURL.appendingPathComponent("scene.json")
        let sceneJSURL = bundleURL.appendingPathComponent("scene.js")
        
        if let sceneData = try? JSONEncoder().encode(finalDef) {
            try? sceneData.write(to: sceneURL)
            if let jsonString = String(data: sceneData, encoding: .utf8) {
                let jsContent = "window.macAuraScene = \(jsonString);"
                try? jsContent.write(to: sceneJSURL, atomically: true, encoding: .utf8)
            }
        }
        
        // Write index.html entrypoint
        let indexHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                * { margin:0; padding:0; box-sizing:border-box; }
                body, html { width:100vw; height:100vh; overflow:hidden; background:#040711; }
                canvas { display:block; width:100vw; height:100vh; }
            </style>
        </head>
        <body>
            <canvas id="c"></canvas>

            <script src="scene.js"></script>
            <script src="Core/EffectRegistry.js"></script>
            <script src="Core/Runtime.js"></script>

            <script src="Effects/Rain.js"></script>
            <script src="Effects/Snow.js"></script>
            <script src="Effects/Stars.js"></script>
            <script src="Effects/Aurora.js"></script>
            <script src="Effects/Neon.js"></script>

            <script>
                document.addEventListener('DOMContentLoaded', () => {
                    const def = window.macAuraScene || {
                        name: "Rain Scene",
                        background: { colors: ["#02040a", "#091224"] },
                        effects: [{ type: "rain", enabled: true, parameters: { density: "300", speed: "1.2", color: "#78c8ff" } }]
                    };
                    const runtime = new MacAuraLiveRuntime();
                    runtime.init(def);
                });
            </script>
        </body>
        </html>
        """
        let indexURL = bundleURL.appendingPathComponent("index.html")
        try? indexHTML.write(to: indexURL, atomically: true, encoding: .utf8)
        
        // Copy runtime scripts into bundle
        copyRuntimeScriptsToBundle(coreDir: coreDir, effectsDir: effectsDir)
        
        // Create manifest.json
        var settingSchemas: [WallpaperSettingSchema] = []
        var defaultSettings: [String: String] = [:]
        
        for eff in finalDef.effects {
            for (key, val) in eff.parameters {
                let schemaKey = "\(eff.type).\(key)"
                defaultSettings[schemaKey] = val
                let minVal: Double
                let maxVal: Double
                if key == "density" {
                    minVal = 10.0
                    maxVal = 1000.0
                } else if key == "speed" {
                    minVal = 0.1
                    maxVal = 5.0
                } else if key == "wind" {
                    minVal = -2.0
                    maxVal = 2.0
                } else if key == "opacity" || key == "width" {
                    minVal = 0.1
                    maxVal = 1.0
                } else {
                    minVal = 0.1
                    maxVal = 10.0
                }
                
                settingSchemas.append(WallpaperSettingSchema(
                    key: schemaKey,
                    type: key.contains("color") ? "color" : "slider",
                    label: "\(eff.type.capitalized) \(key.capitalized)",
                    defaultValue: val,
                    min: minVal,
                    max: maxVal
                ))
            }
        }
        
        let manifestObj = WallpaperManifest(
            id: wallpaperID,
            name: finalDef.name,
            version: "1.0",
            author: "MacAuraLive AI Planner",
            type: "webgl",
            entryPoint: "index.html",
            performance: WallpaperPerformanceConfig(targetFps: 60, allowThrottle: true),
            settings: settingSchemas
        )
        
        let manifestURL = bundleURL.appendingPathComponent("manifest.json")
        if let manifestData = try? JSONEncoder().encode(manifestObj) {
            try? manifestData.write(to: manifestURL)
        }
        
        let codeHasAudio = (htmlCode?.contains("<audio") == true) || (htmlCode?.contains("AudioContext") == true) || (htmlCode?.contains("webkitAudioContext") == true)
        let containsAudio = !(finalDef.audioMappings?.isEmpty ?? true) || codeHasAudio

        let item = WallpaperItem(
            id: wallpaperID,
            title: finalDef.name.count > 28 ? String(finalDef.name.prefix(25)) + "..." : finalDef.name,
            category: "GenAI",
            resolutionTag: resolution,
            type: .gif,
            pathOrUrl: indexURL.path,
            thumbnailIcon: "sparkles",
            hasAudio: containsAudio,
            author: "MacAuraLive AI Planner",
            description: "Procedural Runtime Wallpaper for prompt: '\(cleanPrompt)'",
            manifest: manifestObj,
            customSettings: defaultSettings
        )
        
        wallpapers.append(item)
        setActiveWallpaper(item)
        saveCustomWallpapers()
        return item
    }
    
    private func copyRuntimeScriptsToBundle(coreDir: URL, effectsDir: URL) {
        let runtimeResourcePath = Bundle.main.resourcePath ?? ""
        let sourceRuntime = URL(fileURLWithPath: runtimeResourcePath).appendingPathComponent("Runtime")
        
        let fm = FileManager.default
        if fm.fileExists(atPath: sourceRuntime.path) {
            try? fm.copyItem(at: sourceRuntime.appendingPathComponent("Core/Runtime.js"), to: coreDir.appendingPathComponent("Runtime.js"))
            try? fm.copyItem(at: sourceRuntime.appendingPathComponent("Core/EffectRegistry.js"), to: coreDir.appendingPathComponent("EffectRegistry.js"))
            
            let effects = ["Rain.js", "Snow.js", "Stars.js", "Aurora.js", "Neon.js"]
            for eff in effects {
                try? fm.copyItem(at: sourceRuntime.appendingPathComponent("Effects/\(eff)"), to: effectsDir.appendingPathComponent(eff))
            }
        } else {
            writeFallbackRuntimeScripts(coreDir: coreDir, effectsDir: effectsDir)
        }
    }
    
    private func writeFallbackRuntimeScripts(coreDir: URL, effectsDir: URL) {
        let registryJS = """
        class EffectRegistry {
            static registry = {};
            static register(name, effectClass) { this.registry[name] = effectClass; }
            static create(name, parameters) {
                const EffectClass = this.registry[name];
                return EffectClass ? new EffectClass(parameters) : null;
            }
        }
        """
        try? registryJS.write(to: coreDir.appendingPathComponent("EffectRegistry.js"), atomically: true, encoding: .utf8)
        
        let runtimeJS = """
        class MacAuraLiveRuntime {
            constructor() {
                this.canvas = document.getElementById('c');
                this.ctx = this.canvas.getContext('2d');
                this.effects = [];
                this.config = null;
                this.width = window.innerWidth;
                this.height = window.innerHeight;
                this.lastTime = performance.now();
                this.isPaused = false;
                window.addEventListener('resize', () => {
                    this.width = this.canvas.width = window.innerWidth;
                    this.height = this.canvas.height = window.innerHeight;
                    this.effects.forEach(e => { if (e.resize) e.resize(this.width, this.height); });
                });
                this.canvas.width = this.width;
                this.canvas.height = this.height;
                window.pause = () => { this.isPaused = true; };
                window.resume = () => { if (this.isPaused) { this.isPaused = false; this.lastTime = performance.now(); this.animate(); } };
            }
            init(def) {
                this.config = def;
                if (def.effects) {
                    def.effects.forEach(eff => {
                        if (eff.enabled !== false) {
                            const inst = EffectRegistry.create(eff.type, eff.parameters || {});
                            if (inst) {
                                if (inst.resize) inst.resize(this.width, this.height);
                                this.effects.push(inst);
                            }
                        }
                    });
                }
                if (window.macAura) {
                    window.macAura.onInit(cfg => this.updateSettings(cfg ? cfg.settings : null));
                    window.macAura.onUpdate(st => {
                        this.updateAudio(st);
                        if (st && st.settings) this.updateSettings(st.settings);
                    });
                }
                this.animate();
            }
            updateSettings(sets) {
                if (!sets) return;
                Object.keys(sets).forEach(k => {
                    const v = sets[k];
                    const p = k.split('.');
                    if (p.length === 2) {
                        this.effects.forEach(e => {
                            if (e.type === p[0]) {
                                if (!e.baseParameters) e.baseParameters = {};
                                e.baseParameters[p[1]] = v;
                                if (!e.parameters) e.parameters = {};
                                e.parameters[p[1]] = v;
                            }
                        });
                    }
                });
            }
            updateAudio(state) {
                if (!this.config || !this.config.audio_mappings) return;
                const audio = state.audio || {};
                this.config.audio_mappings.forEach(m => {
                    let val = audio[m.source] || 0;
                    const parts = m.target.split('.');
                    if (parts.length === 2) {
                        this.effects.forEach(e => {
                            if (e.type === parts[0] && e.parameters) {
                                const base = parseFloat(e.baseParameters ? e.baseParameters[parts[1]] : 0) || 0;
                                e.parameters[parts[1]] = base + val * (m.multiplier || 1.0);
                            }
                        });
                    }
                });
            }
            animate() {
                if (this.isPaused) return;
                const now = performance.now();
                const dt = Math.min((now - this.lastTime) / 1000.0, 0.1);
                this.lastTime = now;
                const bg = (this.config && this.config.background && this.config.background.colors) ? this.config.background.colors : ['#040711', '#0b112c'];
                const grad = this.ctx.createLinearGradient(0, 0, 0, this.height);
                grad.addColorStop(0, bg[0] || '#040711');
                grad.addColorStop(1, bg[1] || '#0b112c');
                this.ctx.fillStyle = grad;
                this.ctx.fillRect(0, 0, this.width, this.height);
                this.effects.forEach(e => { e.update(dt); e.render(this.ctx, this.width, this.height); });
                requestAnimationFrame(() => this.animate());
            }
        }
        """
        try? runtimeJS.write(to: coreDir.appendingPathComponent("Runtime.js"), atomically: true, encoding: .utf8)
        
        let rainJS = """
        class RainEffect {
            constructor(p = {}) { this.type = 'rain'; this.baseParameters = {...p}; this.parameters = {...p}; this.drops = []; this.init(); }
            init() {
                const count = parseInt(this.parameters.density || 250);
                this.drops = [];
                for(let i=0; i<count; i++) this.drops.push({x: Math.random()*1920, y: Math.random()*1080, l: Math.random()*25+15, s: Math.random()*12+10, a: Math.random()*0.5+0.3});
            }
            resize(w,h) { this.w = w; this.h = h; }
            update(dt) {
                const spd = parseFloat(this.parameters.speed || 1.0);
                for(let d of this.drops) {
                    d.y += d.s * spd;
                    if(d.y > (this.h||1080)) { d.y = -d.l; d.x = Math.random()*(this.w||1920); }
                }
            }
            render(ctx, w, h) {
                ctx.lineWidth = 1.5; ctx.strokeStyle = this.parameters.color || '#78c8ff';
                for(let d of this.drops) {
                    ctx.globalAlpha = d.a;
                    ctx.beginPath(); ctx.moveTo(d.x, d.y); ctx.lineTo(d.x-2, d.y+d.l); ctx.stroke();
                }
                ctx.globalAlpha = 1.0;
            }
        }
        EffectRegistry.register('rain', RainEffect);
        """
        try? rainJS.write(to: effectsDir.appendingPathComponent("Rain.js"), atomically: true, encoding: .utf8)
        
        let snowJS = """
        class SnowEffect {
            constructor(p = {}) { this.type = 'snow'; this.baseParameters = {...p}; this.parameters = {...p}; this.flakes = []; this.init(); }
            init() {
                const count = parseInt(this.parameters.density || 200);
                this.flakes = [];
                for(let i=0; i<count; i++) this.flakes.push({x: Math.random()*1920, y: Math.random()*1080, r: Math.random()*3+1, s: Math.random()*2+1});
            }
            resize(w,h) { this.w = w; this.h = h; }
            update(dt) {
                const spd = parseFloat(this.parameters.speed || 1.0);
                for(let f of this.flakes) {
                    f.y += f.s * spd; f.x += Math.sin(f.y * 0.02) * 0.8;
                    if(f.y > (this.h||1080)) { f.y = -f.r; f.x = Math.random()*(this.w||1920); }
                }
            }
            render(ctx, w, h) {
                ctx.fillStyle = this.parameters.color || '#ffffff'; ctx.globalAlpha = 0.8;
                for(let f of this.flakes) { ctx.beginPath(); ctx.arc(f.x, f.y, f.r, 0, Math.PI*2); ctx.fill(); }
                ctx.globalAlpha = 1.0;
            }
        }
        EffectRegistry.register('snow', SnowEffect);
        """
        try? snowJS.write(to: effectsDir.appendingPathComponent("Snow.js"), atomically: true, encoding: .utf8)
        
        let starsJS = """
        class StarsEffect {
            constructor(p = {}) { this.type = 'stars'; this.baseParameters = {...p}; this.parameters = {...p}; this.stars = []; this.init(); }
            init() {
                const count = parseInt(this.parameters.density || 350);
                this.stars = [];
                for(let i=0; i<count; i++) this.stars.push({x: (Math.random()-0.5)*3840, y: (Math.random()-0.5)*2160, z: Math.random()*1920});
            }
            resize(w,h) { this.w = w; this.h = h; }
            update(dt) {
                const spd = parseFloat(this.parameters.speed || 6.0);
                for(let s of this.stars) {
                    s.z -= spd;
                    if(s.z <= 0) { s.z = this.w || 1920; s.x = (Math.random()-0.5)*(this.w||1920)*2; s.y = (Math.random()-0.5)*(this.h||1080)*2; }
                }
            }
            render(ctx, w, h) {
                const cx = w/2, cy = h/2; ctx.fillStyle = this.parameters.color || '#c8dcff';
                for(let s of this.stars) {
                    const k = 250 / s.z, px = s.x * k + cx, py = s.y * k + cy;
                    if(px >= 0 && px <= w && py >= 0 && py <= h) {
                        ctx.globalAlpha = 1 - s.z / w;
                        ctx.beginPath(); ctx.arc(px, py, Math.max(0.5, (1-s.z/w)*3), 0, Math.PI*2); ctx.fill();
                    }
                }
                ctx.globalAlpha = 1.0;
            }
        }
        EffectRegistry.register('stars', StarsEffect);
        """
        try? starsJS.write(to: effectsDir.appendingPathComponent("Stars.js"), atomically: true, encoding: .utf8)
        
        let auroraJS = """
        class AuroraEffect {
            constructor(p = {}) { this.type = 'aurora'; this.baseParameters = {...p}; this.parameters = {...p}; this.t = 0; }
            resize(w,h) { this.w = w; this.h = h; }
            update(dt) { this.t += dt * parseFloat(this.parameters.speed || 1.0) * 0.5; }
            render(ctx, w, h) {
                ctx.save(); ctx.globalCompositeOperation = 'lighter'; ctx.globalAlpha = parseFloat(this.parameters.opacity || 0.6);
                ctx.beginPath();
                for(let x=0; x<=w; x+=15) {
                    const y = h*0.4 + Math.sin(x*0.005 + this.t)*90 + Math.cos(x*0.012 - this.t)*45;
                    if(x===0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
                }
                ctx.lineTo(w,h); ctx.lineTo(0,h); ctx.closePath();
                const grad = ctx.createLinearGradient(0, h*0.2, 0, h);
                grad.addColorStop(0, this.parameters.colorStart || '#00f2fe'); grad.addColorStop(1, this.parameters.colorEnd || '#4facfe');
                ctx.fillStyle = grad; ctx.fill(); ctx.restore();
            }
        }
        EffectRegistry.register('aurora', AuroraEffect);
        """
        try? auroraJS.write(to: effectsDir.appendingPathComponent("Aurora.js"), atomically: true, encoding: .utf8)
        
        let neonJS = """
        class NeonEffect {
            constructor(p = {}) { this.type = 'neon'; this.baseParameters = {...p}; this.parameters = {...p}; this.t = 0; }
            resize(w,h) { this.w = w; this.h = h; }
            update(dt) { this.t += dt * parseFloat(this.parameters.speed || 1.0) * 2.0; }
            render(ctx, w, h) {
                ctx.strokeStyle = this.parameters.color || '#ff007f'; ctx.lineWidth = 1.5; ctx.globalAlpha = 0.7 * parseFloat(this.parameters.intensity || 1.0);
                const cy = h * 0.65, spacing = 40;
                for(let y=cy; y<h; y+=spacing) { ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(w,y); ctx.stroke(); }
                const cx = w/2;
                for(let x=-w; x<w*2; x+=60) { ctx.beginPath(); ctx.moveTo(cx + (x-cx)*0.1, cy); ctx.lineTo(x,h); ctx.stroke(); }
                ctx.globalAlpha = 1.0;
            }
        }
        EffectRegistry.register('neon', NeonEffect);
        """
        try? neonJS.write(to: effectsDir.appendingPathComponent("Neon.js"), atomically: true, encoding: .utf8)
    }
    
    public func addCustomFileWallpaper(url: URL, title: String) -> WallpaperItem? {
        let ext = url.pathExtension.lowercased()
        let filename = UUID().uuidString + "_" + url.lastPathComponent
        
        let categoryName: String
        let type: WallpaperType
        let icon: String
        let hasAudioTrack: Bool
        
        if ext == "gif" {
            categoryName = "GIF"
            type = .gif
            icon = "photo.stack.fill"
            hasAudioTrack = false
        } else if ["png", "jpg", "jpeg", "webp", "heic"].contains(ext) {
            categoryName = "GenAI"
            type = .image
            icon = "sparkles"
            hasAudioTrack = false
        } else {
            categoryName = "MP4 Video"
            type = .video
            icon = "play.rectangle.fill"
            hasAudioTrack = true // We will set this correctly after copy
        }
        
        let targetDir = targetDirectory(for: type)
        let destURL = targetDir.appendingPathComponent(filename)
        
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try? FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: url, to: destURL)
            
            let attrs = try? FileManager.default.attributesOfItem(atPath: destURL.path)
            let fileSize = (attrs?[.size] as? UInt64) ?? 0
            guard fileSize > 0 else {
                print("[WallpaperStorageManager] Error: Copied file is 0 bytes.")
                return nil
            }
            
            let finalHasAudioTrack: Bool
            if type == .video {
                finalHasAudioTrack = checkHasAudio(url: destURL)
            } else {
                finalHasAudioTrack = hasAudioTrack
            }
            
            let item = WallpaperItem(
                id: UUID().uuidString,
                title: title.isEmpty ? url.deletingPathExtension().lastPathComponent : title,
                category: categoryName,
                resolutionTag: "4K UHD",
                type: type,
                pathOrUrl: destURL.path,
                thumbnailIcon: icon,
                hasAudio: finalHasAudioTrack,
                author: "User Library",
                description: "Imported \(ext.uppercased()) wallpaper stored permanently."
            )
            
            wallpapers.append(item)
            setActiveWallpaper(item)
            saveCustomWallpapers()
            return item
        } catch {
            print("[WallpaperStorageManager] Failed to copy file: \(error)")
            return nil
        }
    }
    
    public func importFolderWallpapers(folderURL: URL) -> Int {
        let supportedExtensions = Set(["mp4", "mov", "m4v", "avi", "mkv", "webm", "gif", "png", "jpg", "jpeg", "webp", "heic"])
        
        let accessing = folderURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return 0
        }
        
        var count = 0
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            if supportedExtensions.contains(ext) {
                if let _ = addCustomFileWallpaper(url: fileURL, title: "") {
                    count += 1
                }
            }
        }
        return count
    }
    
    public func syncReferencedFolder() -> Int {
        guard let path = referencedFolderURL, !path.isEmpty else { return 0 }
        let url = URL(fileURLWithPath: path)
        return importFolderWallpapers(folderURL: url)
    }
    
    public func addCustomWebWallpaper(urlString: String, title: String) -> WallpaperItem? {
        guard let _ = URL(string: urlString) else { return nil }
        let item = WallpaperItem(
            id: UUID().uuidString,
            title: title.isEmpty ? "Web Wallpaper" : title,
            category: "GenAI",
            resolutionTag: "Dynamic",
            type: .webUrl,
            pathOrUrl: urlString,
            thumbnailIcon: "globe",
            hasAudio: false,
            author: "Web Library",
            description: "Custom web page live wallpaper."
        )
        wallpapers.append(item)
        setActiveWallpaper(item)
        saveCustomWallpapers()
        return item
    }
    
    public func deleteWallpaper(_ wallpaper: WallpaperItem) {
        guard !getBuiltInWallpapers().contains(where: { $0.id == wallpaper.id }) else { return }
        wallpapers.removeAll(where: { $0.id == wallpaper.id })
        if wallpaper.type == .video || wallpaper.type == .gif || wallpaper.type == .image {
            try? FileManager.default.removeItem(atPath: wallpaper.pathOrUrl)
        }
        if activeWallpaperId == wallpaper.id {
            if let first = wallpapers.first {
                setActiveWallpaper(first)
            }
        }
        saveCustomWallpapers()
    }
    
    public func saveCustomWallpapers() {
        let customOnly = wallpapers.filter { item in
            !getBuiltInWallpapers().contains(where: { $0.id == item.id })
        }
        if let data = try? JSONEncoder().encode(customOnly) {
            try? data.write(to: metaFileURL)
        }
    }
    
    public func adaptWallpaperForDayNight(isDarkMode: Bool) {
        let targetCategory = isDarkMode ? "Night" : "Day"
        if let matching = wallpapers.first(where: { $0.category.lowercased() == targetCategory.lowercased() }) {
            print("[WallpaperStorageManager] Auto-adapting wallpaper to \(targetCategory): \(matching.title)")
            setActiveWallpaper(matching)
            WallpaperEngine.shared.reloadEngine()
        }
    }
}
