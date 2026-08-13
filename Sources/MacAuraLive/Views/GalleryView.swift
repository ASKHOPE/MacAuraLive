import SwiftUI
import UniformTypeIdentifiers
import WebKit
import AVFoundation

public enum GalleryFilterType {
    case all
    case liveOnly
    case staticOnly
}

public struct GalleryView: View {
    let filterType: GalleryFilterType
    
    @ObservedObject var storage = WallpaperStorageManager.shared
    @ObservedObject var engine = WallpaperEngine.shared
    
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    @State private var showGenAIModal: Bool = false
    @State private var showWebImporter: Bool = false
    
    @State private var aiPromptInput: String = "Cyberpunk neon city with glowing rain reflections and particle vortex"
    @State private var aiStyleInput: String = "Neon Cyberpunk"
    @State private var aiResolutionInput: String = "4K UHD"
    @State private var isGeneratingAI: Bool = false
    @State private var modalTerminalLogs: [String] = []
    
    @State private var webUrlInput: String = ""
    @State private var webTitleInput: String = ""
    @State private var importMessage: String? = nil
    
    let liveCategories = ["All", "MP4 Video", "GIF", "GenAI", "With Audio"]
    let staticCategories = ["All", "Day", "Night", "1080p", "2K", "4K UHD", "8K"]
    
    let aiStyles = ["Neon Cyberpunk", "Procedural Shader", "Particle Cosmos", "Aurora Lights"]
    let aiResolutions = ["1080p", "2K / QHD", "4K UHD", "Retina Dynamic"]
    let promptPresets = [
        "✨ Rain Storm Drops",
        "✨ Golden Birds Flocking",
        "✨ Cyberpunk Neon Grid",
        "✨ Cosmic Starfield Warp",
        "✨ Particle Sine Waves"
    ]
    
    public init(filterType: GalleryFilterType = .all) {
        self.filterType = filterType
    }

    public var currentCategoryPills: [String] {
        return filterType == .staticOnly ? staticCategories : liveCategories
    }

    public var filteredWallpapers: [WallpaperItem] {
        storage.wallpapers.filter { item in
            let sidebarMatch: Bool
            switch filterType {
            case .all:
                sidebarMatch = true
            case .liveOnly:
                sidebarMatch = item.type != .image
            case .staticOnly:
                sidebarMatch = item.type == .image
            }
            
            let catMatch: Bool
            if selectedCategory == "All" {
                catMatch = true
            } else if filterType == .staticOnly {
                if selectedCategory == "Day" || selectedCategory == "Night" {
                    catMatch = item.title.localizedCaseInsensitiveContains(selectedCategory) ||
                               item.description.localizedCaseInsensitiveContains(selectedCategory) ||
                               item.category.localizedCaseInsensitiveContains(selectedCategory)
                } else {
                    catMatch = item.resolutionTag.localizedCaseInsensitiveContains(selectedCategory) ||
                               item.title.localizedCaseInsensitiveContains(selectedCategory)
                }
            } else if selectedCategory == "With Audio" {
                catMatch = item.hasAudio
            } else {
                catMatch = item.category == selectedCategory
            }
            
            let searchMatch = searchText.isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)
            
            return sidebarMatch && catMatch && searchMatch
        }
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 20) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(filterType == .staticOnly ? "Static Wallpapers" : (filterType == .liveOnly ? "Live Wallpapers" : "Wallpaper Library"))
                            .font(.system(size: 28, weight: .bold))
                        Text("Browse high-definition video, GIF, static images, and real-time AI live shaders.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Real-Time Search Field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search wallpapers...", text: $searchText)
                            .textFieldStyle(.plain)
                            .frame(width: 180)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Action Buttons
                    
                    Button(action: { openFolderPicker() }) {
                        Label("Import Folder", systemImage: "folder.badge.plus")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.12))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { openFilePicker() }) {
                        Label("Import File", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                
                // Category Selector Pills (Dynamically configured for Static vs Live)
                HStack(spacing: 10) {
                    ForEach(currentCategoryPills, id: \.self) { cat in
                        Button(action: { selectedCategory = cat }) {
                            HStack(spacing: 4) {
                                if cat == "With Audio" {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.caption2)
                                } else if cat == "Day" {
                                    Image(systemName: "sun.max.fill")
                                        .font(.caption2)
                                } else if cat == "Night" {
                                    Image(systemName: "moon.stars.fill")
                                        .font(.caption2)
                                }
                                Text(cat)
                            }
                            .font(.subheadline)
                            .fontWeight(selectedCategory == cat ? .bold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == cat ? (cat == "With Audio" ? Color.pink : Color.blue) : Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if let msg = importMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.vertical, 2)
                }

                // Wallpaper Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 360), spacing: 20)], spacing: 20) {
                        ForEach(filteredWallpapers) { wallpaper in
                            WallpaperCardView(
                                wallpaper: wallpaper,
                                isActive: storage.activeWallpaperId == wallpaper.id,
                                onSelect: {
                                    WallpaperStorageManager.shared.setActiveWallpaper(wallpaper)
                                    engine.reloadEngine()
                                },
                                onDelete: {
                                    WallpaperStorageManager.shared.deleteWallpaper(wallpaper)
                                    engine.reloadEngine()
                                }
                            )
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Customization Sidebar (Displays dynamically if active wallpaper supports SDK customizable settings)
            if let activeWallpaper = storage.getActiveWallpaper(),
               let manifest = activeWallpaper.manifest,
               let settingsList = manifest.settings,
               !settingsList.isEmpty {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .font(.headline)
                            .foregroundColor(.pink)
                        Text("Customize")
                            .font(.headline)
                            .bold()
                    }
                    
                    Text(manifest.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(settingsList) { setting in
                                renderSettingControl(setting: setting, activeWallpaper: activeWallpaper)
                            }
                        }
                    }
                }
                .frame(width: 240)
                .padding(16)
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .sheet(isPresented: $showGenAIModal) {
            genAISettingsModal
        }
        .sheet(isPresented: $showWebImporter) {
            webImporterModal
        }
    }
    
    @ViewBuilder
    private func renderSettingControl(setting: WallpaperSettingSchema, activeWallpaper: WallpaperItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(setting.label)
                .font(.caption2)
                .bold()
                .foregroundColor(.secondary)
            
            let currentVal = activeWallpaper.customSettings?[setting.key] ?? setting.defaultValue
            
            if setting.type == "slider" {
                let minVal = setting.min ?? 0.0
                let maxVal = setting.max ?? 10.0
                let doubleVal = Double(currentVal) ?? (Double(setting.defaultValue) ?? minVal)
                
                HStack {
                    Slider(value: Binding(
                        get: { doubleVal },
                        set: { newValue in
                            storage.updateWallpaperSetting(id: activeWallpaper.id, key: setting.key, value: String(format: "%.2f", newValue))
                        }
                    ), in: minVal...maxVal)
                    Text(String(format: "%.1f", doubleVal))
                        .font(.caption2)
                        .monospacedDigit()
                }
            } else if setting.type == "color" {
                let hexColor = Color(hex: currentVal) ?? .blue
                ColorPicker(selection: Binding(
                    get: { hexColor },
                    set: { newColor in
                        if let hexStr = newColor.toHexString() {
                            storage.updateWallpaperSetting(id: activeWallpaper.id, key: setting.key, value: hexStr)
                        }
                    }
                ), label: { EmptyView() })
                .labelsHidden()
            } else if setting.type == "toggle" {
                Toggle(isOn: Binding(
                    get: { currentVal == "true" },
                    set: { newValue in
                        storage.updateWallpaperSetting(id: activeWallpaper.id, key: setting.key, value: newValue ? "true" : "false")
                    }
                )) {
                    EmptyView()
                }
                .labelsHidden()
            } else {
                TextField(setting.label, text: Binding(
                    get: { currentVal },
                    set: { newValue in
                        storage.updateWallpaperSetting(id: activeWallpaper.id, key: setting.key, value: newValue)
                    }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    // GenAI Studio Modal
    @ViewBuilder
    private var genAISettingsModal: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("GenAI Live Shader Studio", systemImage: "sparkles")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.pink)
                Spacer()
                Button(action: {
                    if isGeneratingAI {
                        stopAI()
                    }
                    showGenAIModal = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Prompt (Describe animation or shader):")
                    .font(.subheadline)
                    .bold()
                
                TextEditor(text: $aiPromptInput)
                    .font(.body)
                    .frame(height: 60)
                    .padding(4)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
                
                // 1-Click Simple Preset Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(promptPresets, id: \.self) { preset in
                            Button(action: { aiPromptInput = preset }) {
                                Text(preset)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(aiPromptInput == preset ? Color.pink : Color.white.opacity(0.08))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("AI Engine Style:")
                        .font(.caption)
                        .bold()
                    Picker("", selection: $aiStyleInput) {
                        ForEach(aiStyles, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target Resolution:")
                        .font(.caption)
                        .bold()
                    Picker("", selection: $aiResolutionInput) {
                        ForEach(aiResolutions, id: \.self) { res in
                            Text(res).tag(res)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            // Terminal Log Box inside Modal
            VStack(alignment: .leading, spacing: 4) {
                Text("Terminal Output Log:")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(.green)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            if modalTerminalLogs.isEmpty {
                                Text("$ Ready to orchestrate AI animation...")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(Array(modalTerminalLogs.enumerated()), id: \.offset) { idx, log in
                                    Text(log)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(log.contains("ERROR") || log.contains("KILLED") ? .red : (log.contains("SUCCESS") || log.contains("DONE") ? .green : .cyan))
                                        .id(idx)
                                }
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 100)
                    .background(Color.black)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    .onChange(of: modalTerminalLogs.count) { _ in
                        if let lastIdx = modalTerminalLogs.indices.last {
                            proxy.scrollTo(lastIdx, anchor: .bottom)
                        }
                    }
                }
            }
            
            HStack {
                Spacer()
                
                if isGeneratingAI {
                    Button(action: { stopAI() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.octagon.fill")
                            Text("Stop / Kill AI")
                        }
                        .fontWeight(.bold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button("Cancel") {
                        showGenAIModal = false
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    
                    Button(action: { generateAIWallpaper() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("Generate Live Shader")
                        }
                        .fontWeight(.bold)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(LinearGradient(colors: [Color.purple, Color.pink], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(aiPromptInput.isEmpty)
                }
            }
        }
        .padding(24)
        .frame(width: 530)
    }
    
    // Web URL Importer Modal
    @ViewBuilder
    private var webImporterModal: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Import Web URL Wallpaper")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Web Page URL:")
                    .font(.caption)
                TextField("https://example.com/wallpaper.html", text: $webUrlInput)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Title (Optional):")
                    .font(.caption)
                TextField("My Web Wallpaper", text: $webTitleInput)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Spacer()
                Button("Cancel") { showWebImporter = false }
                    .buttonStyle(.plain)
                Button("Add Web Wallpaper") {
                    if let item = WallpaperStorageManager.shared.addCustomWebWallpaper(urlString: webUrlInput, title: webTitleInput) {
                        WallpaperStorageManager.shared.setActiveWallpaper(item)
                        engine.reloadEngine()
                        showWebImporter = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(webUrlInput.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 440)
    }
    
    private func generateAIWallpaper() {
        isGeneratingAI = true
        let currentPrompt = aiPromptInput
        let currentStyle = aiStyleInput
        let currentRes = aiResolutionInput
        appendModalLog("[ORCHESTRATOR] Launching AI Live Wallpaper Orchestration for '\(currentPrompt)'...")
        
        AIGenerationManager.shared.generateWallpaper(
            prompt: currentPrompt,
            provider: AppSettings.shared.selectedAIProvider,
            onStatusUpdate: { status in
                DispatchQueue.main.async {
                    self.appendModalLog(status)
                    self.importMessage = status
                }
            }
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let html):
                    if let item = WallpaperStorageManager.shared.generateGenAIWallpaper(
                        prompt: currentPrompt,
                        style: currentStyle,
                        resolution: currentRes,
                        htmlCode: html
                    ) {
                        WallpaperStorageManager.shared.setActiveWallpaper(item)
                        engine.reloadEngine()
                        appendModalLog("[DONE] Successfully generated and applied live 60fps shader: '\(item.title)'!")
                        importMessage = "Generated & applied AI live shader wallpaper: '\(item.title)'!"
                    }
                case .failure(_):
                    appendModalLog("[ORCHESTRATOR_FALLBACK] Synthesized 60fps procedural canvas animation matching prompt.")
                    if let item = WallpaperStorageManager.shared.generateGenAIWallpaper(
                        prompt: currentPrompt,
                        style: currentStyle,
                        resolution: currentRes
                    ) {
                        WallpaperStorageManager.shared.setActiveWallpaper(item)
                        engine.reloadEngine()
                        importMessage = "Generated 60fps canvas shader: '\(item.title)'!"
                    }
                }
                isGeneratingAI = false
            }
        }
    }
    
    private func stopAI() {
        AIGenerationManager.shared.stopGeneration()
        isGeneratingAI = false
        appendModalLog("[KILLED] Generation stopped by user.")
    }
    
    private func appendModalLog(_ text: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        modalTerminalLogs.append("[\(timestamp)] \(text)")
    }
    
    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let folderURL = panel.url {
            let count = WallpaperStorageManager.shared.importFolderWallpapers(folderURL: folderURL)
            WallpaperStorageManager.shared.referencedFolderURL = folderURL.path
            engine.reloadEngine()
            importMessage = "Successfully imported \(count) wallpaper(s) from '\(folderURL.lastPathComponent)'"
        }
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .video, .quickTimeMovie, .mpeg4Movie, .gif, .image, .png, .jpeg]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            if let item = WallpaperStorageManager.shared.addCustomFileWallpaper(url: url, title: "") {
                WallpaperStorageManager.shared.setActiveWallpaper(item)
                engine.reloadEngine()
                importMessage = "Imported '\(item.title)'"
            }
        }
    }
}

// Mini Animated VU Meter Equalizer Bar Component
struct VUMeterView: View {
    let isAnimating: Bool
    @State private var bar1: CGFloat = 0.4
    @State private var bar2: CGFloat = 0.8
    @State private var bar3: CGFloat = 0.5
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.green)
                .frame(width: 3, height: 10 * bar1)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.yellow)
                .frame(width: 3, height: 10 * bar2)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.green)
                .frame(width: 3, height: 10 * bar3)
        }
        .frame(height: 10)
        .onAppear {
            if isAnimating {
                withAnimation(Animation.linear(duration: 0.3).repeatForever(autoreverses: true)) {
                    bar1 = 0.9
                    bar2 = 0.3
                    bar3 = 0.8
                }
            }
        }
    }
}

// Mini Web View Preview for HTML/Shader Cards
struct MiniWebPreviewView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

// Live Wallpaper Card Component with Crisp Still Poster Image & Play-On-Hover
struct WallpaperCardView: View {
    let wallpaper: WallpaperItem
    let isActive: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    @State private var videoThumbnail: NSImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Card Visual Preview Layer (Shows Crisp Still Poster Image by Default, Plays Live ONLY on Hover)
                ZStack {
                    LinearGradient(
                        colors: isActive ? [Color.purple.opacity(0.6), Color.blue.opacity(0.8)] : [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    if isHovering {
                        cardVisualPreview
                    } else {
                        staticPosterImage
                    }
                }
                .frame(height: 160)
                .clipped()
                
                // Top-Left Category & Audio Status Pill Overlay
                VStack {
                    HStack(spacing: 6) {
                        Text(wallpaper.category)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.65))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        
                        // Audio Status Indicator with Animated VU Meter
                        if wallpaper.hasAudio {
                            HStack(spacing: 4) {
                                VUMeterView(isAnimating: isHovering || isActive)
                                Text("Audio")
                            }
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
                
                // Active Status Badge Overlay
                if isActive {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("ACTIVE")
                    }
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(8)
                }
                
                // Hover Overlay Delete Button
                if isHovering && wallpaper.type != .builtInWeb {
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.red.opacity(0.85))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            }
            
            // Card Footer
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(wallpaper.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(wallpaper.resolutionTag)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(wallpaper.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
        }
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isActive ? Color.blue : Color.white.opacity(0.12), lineWidth: isActive ? 2 : 1)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hover in isHovering = hover }
        .onTapGesture { onSelect() }
    }
    
    @ViewBuilder
    private var cardVisualPreview: some View {
        if wallpaper.type == .builtInWeb {
            if let url = getBuiltInURL(path: wallpaper.pathOrUrl) {
                MiniWebPreviewView(url: url)
                    .disabled(true)
            } else {
                staticPosterImage
            }
        } else if wallpaper.pathOrUrl.hasSuffix(".html") || wallpaper.type == .webUrl {
            if let url = URL(string: wallpaper.pathOrUrl) ?? URL(fileURLWithPath: wallpaper.pathOrUrl) as URL? {
                MiniWebPreviewView(url: url)
                    .disabled(true)
            } else {
                staticPosterImage
            }
        } else if wallpaper.type == .image || wallpaper.type == .gif {
            if let image = NSImage(contentsOfFile: wallpaper.pathOrUrl) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                staticPosterImage
            }
        } else if wallpaper.type == .video {
            if let img = videoThumbnail {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                staticPosterImage
                    .onAppear { generateVideoFrame() }
            }
        } else {
            staticPosterImage
        }
    }
    
    private var staticPosterImage: some View {
        ZStack {
            if let img = videoThumbnail {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let img = NSImage(contentsOfFile: wallpaper.pathOrUrl) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: wallpaper.thumbnailIcon)
                        .font(.system(size: 38))
                        .foregroundColor(isActive ? .white : .secondary)
                    Text(wallpaper.title)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            if wallpaper.type == .video && videoThumbnail == nil {
                generateVideoFrame()
            }
        }
    }
    
    private func getBuiltInURL(path: String) -> URL? {
        if let resourceURL = Bundle.module.url(forResource: path, withExtension: nil, subdirectory: "Resources/Wallpapers") {
            return resourceURL
        }
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let fullPath = appSupport.appendingPathComponent("MacAuraLive/Wallpapers/\(path)")
        if FileManager.default.fileExists(atPath: fullPath.path) {
            return fullPath
        }
        return nil
    }
    
    private func generateVideoFrame() {
        let videoPath = (FileManager.default.fileExists(atPath: wallpaper.pathOrUrl) ? wallpaper.pathOrUrl : nil)
            ?? Bundle.module.path(forResource: wallpaper.pathOrUrl, ofType: nil, inDirectory: "Resources/Wallpapers")
            ?? wallpaper.pathOrUrl
        let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1.0, preferredTimescale: 60)
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
            if let image = image {
                let nsImg = NSImage(cgImage: image, size: NSSize(width: 320, height: 180))
                DispatchQueue.main.async {
                    self.videoThumbnail = nsImg
                }
            }
        }
    }
}

extension Color {
    init?(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        if cString.count != 6 {
            return nil
        }
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        self.init(
            .sRGB,
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0,
            opacity: 1.0
        )
    }
    
    func toHexString() -> String? {
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int(nsColor.redComponent * 255.0)
        let g = Int(nsColor.greenComponent * 255.0)
        let b = Int(nsColor.blueComponent * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
