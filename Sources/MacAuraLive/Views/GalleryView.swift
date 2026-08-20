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
    @ObservedObject var settings = AppSettings.shared
    
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    @State private var selectedDayNightFilter: String = "All"
    @State private var selectedResolutionFilter: String = "All"
    @State private var showGenAIModal: Bool = false
    @State private var showWebImporter: Bool = false
    @State private var previewWallpaper: WallpaperItem? = nil
    
    // Multi-Select & Batch Clear States
    @State private var isSelectionMode: Bool = false
    @State private var selectedWallpaperIds: Set<String> = []
    @State private var showMultiDeleteAlert: Bool = false
    
    @State private var aiPromptInput: String = "Cyberpunk neon city with glowing rain reflections and particle vortex"
    @State private var aiStyleInput: String = "Neon Cyberpunk"
    @State private var aiResolutionInput: String = "4K UHD"
    @State private var isGeneratingAI: Bool = false
    @State private var modalTerminalLogs: [String] = []
    
    @State private var webUrlInput: String = ""
    @State private var webTitleInput: String = ""
    @State private var importMessage: String? = nil
    
    let liveCategories = ["All", "MP4 Video", "GIF", "GenAI", "With Audio"]
    let staticCategories = ["All", "Nature", "Abstract", "Vector", "Architecture", "Minimal"]
    let resolutionPills = ["1080P", "2K", "4K UHD", "8K"]
    
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
    
    private func placementLabel(_ mode: String) -> String {
        switch mode {
        case "original", "center": return "Original (Native)"
        case "fit": return "Fit"
        case "fill": return "Crop to Fill"
        case "stretch": return "Stretch"
        case "zoom": return "Zoom"
        default: return "Original (Native)"
        }
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
                catMatch = item.category.localizedCaseInsensitiveContains(selectedCategory) ||
                           item.title.localizedCaseInsensitiveContains(selectedCategory)
            } else if selectedCategory == "With Audio" {
                catMatch = item.hasAudio
            } else {
                catMatch = item.category == selectedCategory
            }
            
            let dayNightMatch: Bool
            if selectedDayNightFilter == "All" {
                dayNightMatch = true
            } else if selectedDayNightFilter == "Day" {
                dayNightMatch = item.title.localizedCaseInsensitiveContains("Day") ||
                                item.description.localizedCaseInsensitiveContains("Day") ||
                                item.category.localizedCaseInsensitiveContains("Day") ||
                                !item.title.localizedCaseInsensitiveContains("Night")
            } else { // Night
                dayNightMatch = item.title.localizedCaseInsensitiveContains("Night") ||
                                item.description.localizedCaseInsensitiveContains("Night") ||
                                item.category.localizedCaseInsensitiveContains("Night") ||
                                item.title.localizedCaseInsensitiveContains("Dark")
            }
            
            let resMatch: Bool
            if selectedResolutionFilter == "All" {
                resMatch = true
            } else {
                resMatch = item.resolutionTag.localizedCaseInsensitiveContains(selectedResolutionFilter) ||
                           item.title.localizedCaseInsensitiveContains(selectedResolutionFilter) ||
                           item.description.localizedCaseInsensitiveContains(selectedResolutionFilter)
            }
            
            let searchMatch = searchText.isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)
            
            return sidebarMatch && catMatch && dayNightMatch && resMatch && searchMatch
        }
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 20) {
                // Clean macOS Header Bar
                // Clean Responsive Header Bar
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(filterType == .staticOnly ? "Static Wallpapers" : (filterType == .liveOnly ? "Live Wallpapers" : "Wallpaper Library"))
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextDark : .primary)
                        
                        Text(filterType == .staticOnly ? "Browse high-definition static photos and generative art." : "Browse high-definition video loops, static photos, and live shaders.")
                            .font(.system(size: 13, weight: .regular, design: settings.appTheme == "classic" ? .monospaced : .default))
                            .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextMuted : .secondary)
                    }
                    
                    Spacer()
                    
                    // Search Bar & Day/Night Pill Group
                    HStack(spacing: 8) {
                        // Search Field
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(settings.appTheme == "classic" ? Color(red: 0.65, green: 0.63, blue: 0.58) : .secondary)
                                .font(.caption)
                            TextField("Search files...", text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12.5, design: settings.appTheme == "classic" ? .monospaced : .default))
                                .foregroundColor(settings.appTheme == "classic" ? Color(red: 0.85, green: 0.83, blue: 0.78) : .primary)
                                .frame(width: 150)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(settings.appTheme == "classic" ? Color(red: 0.12, green: 0.115, blue: 0.10) : Color(NSColor.quaternaryLabelColor).opacity(0.15))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(settings.appTheme == "classic" ? Color(red: 0.25, green: 0.24, blue: 0.22) : Color.clear, lineWidth: 1)
                        )
                        
                        // Day / Night Quick Pills
                        HStack(spacing: 4) {
                            ForEach(["All", "Day", "Night"], id: \.self) { dn in
                                let isSelected = selectedDayNightFilter == dn
                                Button(action: { selectedDayNightFilter = dn }) {
                                    HStack(spacing: 4) {
                                        if dn == "Day" { Image(systemName: "sun.max.fill").font(.system(size: 10)) }
                                        if dn == "Night" { Image(systemName: "moon.stars.fill").font(.system(size: 10)) }
                                        Text(dn)
                                            .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: settings.appTheme == "classic" ? .monospaced : .default))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(isSelected ? (settings.appTheme == "classic" ? MacaThemeTokens.classicOlive : Color.accentColor) : (settings.appTheme == "classic" ? MacaThemeTokens.classicButtonBg : Color(NSColor.controlBackgroundColor)))
                                    .foregroundColor(isSelected ? .white : (settings.appTheme == "classic" ? MacaThemeTokens.classicTextDark : .primary))
                                    .cornerRadius(settings.appTheme == "classic" ? 2 : 6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: settings.appTheme == "classic" ? 2 : 6)
                                            .stroke(settings.appTheme == "classic" ? MacaThemeTokens.classicBorder : Color(NSColor.separatorColor), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Secondary Filter Row: Resolution & Categories + Action Buttons
                HStack(spacing: 10) {
                    // Resolution Pills
                    HStack(spacing: 4) {
                        ForEach(["1080P", "2K", "4K UHD", "8K"], id: \.self) { res in
                            let isSelected = selectedResolutionFilter == res
                            Button(action: {
                                selectedResolutionFilter = (selectedResolutionFilter == res ? "All" : res)
                            }) {
                                Text(res)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .monospaced))
                                    .fixedSize()
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(isSelected ? (settings.appTheme == "classic" ? MacaThemeTokens.classicOlive : Color.accentColor) : (settings.appTheme == "classic" ? MacaThemeTokens.classicButtonBg : Color(NSColor.controlBackgroundColor)))
                                    .foregroundColor(isSelected ? .white : (settings.appTheme == "classic" ? MacaThemeTokens.classicTextDark : .primary))
                                    .cornerRadius(settings.appTheme == "classic" ? 2 : 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: settings.appTheme == "classic" ? 2 : 4)
                                            .stroke(settings.appTheme == "classic" ? MacaThemeTokens.classicBorder : Color(NSColor.separatorColor), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Category Pills Scrollable Container
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(spacing: 4) {
                            ForEach(currentCategoryPills, id: \.self) { cat in
                                let isSelected = selectedCategory == cat
                                Button(action: { selectedCategory = cat }) {
                                    HStack(spacing: 4) {
                                        if cat == "With Audio" {
                                            Image(systemName: "speaker.wave.2.fill")
                                                .font(.system(size: 10))
                                        }
                                        Text(cat)
                                            .font(.system(size: 11.5, weight: isSelected ? .bold : .medium, design: settings.appTheme == "classic" ? .monospaced : .default))
                                            .fixedSize()
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(isSelected ? (settings.appTheme == "classic" ? MacaThemeTokens.classicOlive : Color.accentColor) : (settings.appTheme == "classic" ? MacaThemeTokens.classicButtonBg : Color(NSColor.controlBackgroundColor)))
                                    .foregroundColor(isSelected ? .white : (settings.appTheme == "classic" ? MacaThemeTokens.classicTextDark : .primary))
                                    .cornerRadius(settings.appTheme == "classic" ? 2 : 6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: settings.appTheme == "classic" ? 2 : 6)
                                            .stroke(settings.appTheme == "classic" ? MacaThemeTokens.classicBorder : Color(NSColor.separatorColor), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Spacer(minLength: 4)
                    
                    // Sizing & Action Buttons
                    HStack(spacing: 8) {
                        Button { openFolderPicker() } label: {
                            Label("Import Folder", systemImage: "folder.badge.plus")
                        }
                        .macaButtonStyle(.secondary, size: .small)
                        .fixedSize()
                        
                        Button { openFilePicker() } label: {
                            Label("Import File", systemImage: "plus.circle.fill")
                        }
                        .macaButtonStyle(.primary, size: .small)
                        .fixedSize()
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSelectionMode.toggle()
                                if !isSelectionMode {
                                    selectedWallpaperIds.removeAll()
                                }
                            }
                        } label: {
                            Label(isSelectionMode ? "Cancel" : "Select", systemImage: isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                        }
                        .macaButtonStyle(.secondary, size: .small)
                        .fixedSize()
                        
                        Menu {
                            Picker("Global Sizing", selection: $settings.wallpaperPlacement) {
                                Label("Original (macOS Default)", systemImage: "viewfinder").tag("original")
                                Label("Fit to Screen (Aspect Ratio)", systemImage: "aspectratio").tag("fit")
                                Label("Crop to Fill Screen (Aspect Fill)", systemImage: "crop").tag("fill")
                                Label("Stretch to Fill Screen", systemImage: "arrow.up.left.and.arrow.down.right").tag("stretch")
                                Label("Custom Zoom & Scale", systemImage: "plus.magnifyingglass").tag("zoom")
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "aspectratio")
                                Text(placementLabel(settings.wallpaperPlacement))
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                        }
                        .macaButtonStyle(.secondary, size: .small)
                        .fixedSize()
                    }
                    .fixedSize(horizontal: true, vertical: false)
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
                                isSelectionMode: isSelectionMode,
                                isSelected: selectedWallpaperIds.contains(wallpaper.id),
                                onSelect: {
                                    if isSelectionMode {
                                        if wallpaper.type != .builtInWeb {
                                            if selectedWallpaperIds.contains(wallpaper.id) {
                                                selectedWallpaperIds.remove(wallpaper.id)
                                            } else {
                                                selectedWallpaperIds.insert(wallpaper.id)
                                            }
                                        }
                                    } else {
                                        WallpaperStorageManager.shared.setActiveWallpaper(wallpaper)
                                        engine.reloadEngine()
                                    }
                                },
                                onToggleSelect: {
                                    if selectedWallpaperIds.contains(wallpaper.id) {
                                        selectedWallpaperIds.remove(wallpaper.id)
                                    } else {
                                        selectedWallpaperIds.insert(wallpaper.id)
                                    }
                                },
                                onPreview: {
                                    previewWallpaper = wallpaper
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
        .sheet(item: $previewWallpaper) { item in
            FullWallpaperPreviewModal(wallpaper: item)
        }
        .alert("Delete \(selectedWallpaperIds.count) Wallpapers?", isPresented: $showMultiDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                storage.deleteWallpapers(ids: selectedWallpaperIds)
                selectedWallpaperIds.removeAll()
                isSelectionMode = false
                engine.reloadEngine()
            }
        } message: {
            Text("This will permanently remove the selected \(selectedWallpaperIds.count) wallpapers and their local files from your Mac library.")
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
                    MacaRetroSlider(value: Binding(
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
                .macaTextFieldStyle()
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
                    .macaTextFieldStyle()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Title (Optional):")
                    .font(.caption)
                TextField("My Web Wallpaper", text: $webTitleInput)
                    .macaTextFieldStyle()
            }
            
            HStack {
                Spacer()
                Button("Cancel") { showWebImporter = false }
                    .macaButtonStyle(.secondary)
                Button("Add Web Wallpaper") {
                    if let item = WallpaperStorageManager.shared.addCustomWebWallpaper(urlString: webUrlInput, title: webTitleInput) {
                        WallpaperStorageManager.shared.setActiveWallpaper(item)
                        engine.reloadEngine()
                    }
                    showWebImporter = false
                }
                .macaButtonStyle(.primary)
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
    
    static func dismantleNSView(_ nsView: WKWebView, coordinator: ()) {
        nsView.stopLoading()
        nsView.navigationDelegate = nil
        nsView.removeFromSuperview()
    }
}

// Live Wallpaper Card Component with Crisp Still Poster Image & Play-On-Hover
struct WallpaperCardView: View {
    let wallpaper: WallpaperItem
    let isActive: Bool
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    let onSelect: () -> Void
    var onToggleSelect: (() -> Void)? = nil
    let onPreview: () -> Void
    let onDelete: () -> Void
    
    @ObservedObject var settings = AppSettings.shared
    @State private var isHovering = false
    @State private var videoThumbnail: NSImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Card Visual Preview Layer (Full Aspect Fit with Sleek Backdrop)
                ZStack {
                    Color.black.opacity(0.4)
                    
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
                        Text(wallpaper.category.uppercased())
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(settings.appTheme == "classic" ? Color(red: 0.14, green: 0.13, blue: 0.11) : Color.black.opacity(0.65))
                            .foregroundColor(settings.appTheme == "classic" ? Color(red: 0.90, green: 0.85, blue: 0.70) : .white)
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(settings.appTheme == "classic" ? Color(red: 0.28, green: 0.26, blue: 0.22) : Color.clear, lineWidth: 0.8)
                            )
                        
                        // Audio Status Indicator with Animated VU Meter
                        if wallpaper.hasAudio {
                            HStack(spacing: 4) {
                                VUMeterView(isAnimating: isHovering || isActive)
                                Text("AUDIO")
                            }
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3.5)
                            .background(settings.appTheme == "classic" ? MacaThemeTokens.classicOlive : Color.blue.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
                
                // Multi-Selection Checkbox or Active / Hover Badges
                if isSelectionMode {
                    Button(action: { onToggleSelect?() }) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isSelected ? .blue : .white)
                            .background(Circle().fill(isSelected ? Color.white : Color.black.opacity(0.6)))
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                } else {
                    // Active Status Badge Overlay
                    if isActive {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("ACTIVE")
                        }
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(settings.appTheme == "classic" ? MacaThemeTokens.classicOlive : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .padding(8)
                    }
                    
                    // Hover Action Buttons: Full Preview & Delete
                    if isHovering {
                        HStack(spacing: 6) {
                            Button(action: onPreview) {
                                Image(systemName: "eye.fill")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(7)
                                    .background(settings.appTheme == "classic" ? Color(red: 0.20, green: 0.19, blue: 0.17) : Color.blue.opacity(0.85))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .help("Quick Look / Full Preview")
                            
                            Button(action: onDelete) {
                                Image(systemName: "trash.fill")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(7)
                                    .background(Color.red.opacity(0.85))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .help("Delete Wallpaper")
                        }
                        .padding(8)
                    }
                }
            }
            
            // Card Body & Footer
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(wallpaper.title)
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextDark : .primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(wallpaper.resolutionTag.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextMuted : .secondary)
                }
                
                Text(wallpaper.description)
                    .font(.system(size: 11.5, weight: .regular, design: settings.appTheme == "classic" ? .monospaced : .default))
                    .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextMuted : .secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Bottom Metadata Line: Size & Apply Action Icon
                HStack {
                    if !wallpaper.formattedFileSize.isEmpty {
                        Text(wallpaper.formattedFileSize)
                            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                            .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextMuted : .secondary)
                    } else {
                        Text("BUILT-IN")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextMuted : .secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isActive ? "checkmark" : (wallpaper.type == .image ? "arrow.down.to.line" : "play.fill"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(settings.appTheme == "classic" ? MacaThemeTokens.classicTextDark : (isActive ? .green : .accentColor))
                }
                .padding(.top, 4)
            }
            .padding(12)
            .background(settings.appTheme == "classic" ? MacaThemeTokens.classicCardBg : Color(NSColor.controlBackgroundColor))
        }
        .cornerRadius(settings.appTheme == "classic" ? 2 : 14)
        .overlay(
            RoundedRectangle(cornerRadius: settings.appTheme == "classic" ? 2 : 14)
                .stroke(
                    isSelected ? Color.blue : (isActive ? (settings.appTheme == "classic" ? MacaThemeTokens.classicOlive : Color.blue) : (settings.appTheme == "classic" ? MacaThemeTokens.classicBorder : Color(NSColor.separatorColor))),
                    lineWidth: isSelected ? 2.5 : (isActive ? 2 : 1)
                )
        )
        .shadow(
            color: settings.appTheme == "classic" ? Color.black.opacity(0.08) : Color.black.opacity(0.06),
            radius: settings.appTheme == "classic" ? 3 : 4,
            x: settings.appTheme == "classic" ? 2 : 0,
            y: settings.appTheme == "classic" ? 2 : 2
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hover in isHovering = hover }
        .onTapGesture {
            if isSelectionMode {
                onToggleSelect?()
            } else {
                onSelect()
            }
        }
    }
    
    @ViewBuilder
    private var cardVisualPreview: some View {
        if wallpaper.type == .video {
            if let img = videoThumbnail {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let img = WallpaperStorageManager.shared.resolveImage(for: wallpaper) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: wallpaper.thumbnailIcon)
                        .font(.system(size: 38))
                        .foregroundColor(isActive ? .cyan : .white.opacity(0.8))
                    Text(wallpaper.title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .onAppear {
            if wallpaper.type == .video && videoThumbnail == nil {
                generateVideoFrame()
            }
        }
    }
    
    private func generateVideoFrame() {
        guard let url = WallpaperStorageManager.shared.resolveURL(for: wallpaper) else { return }
        let asset = AVAsset(url: url)
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

// MARK: - Full Wallpaper Preview Modal
struct FullWallpaperPreviewModal: View {
    let wallpaper: WallpaperItem
    @Environment(\.dismiss) var dismiss
    @ObservedObject var storage = WallpaperStorageManager.shared
    @ObservedObject var engine = WallpaperEngine.shared
    @ObservedObject var settings = AppSettings.shared
    @State private var videoThumbnail: NSImage? = nil
    
    private func placementLabel(_ mode: String) -> String {
        switch mode {
        case "fit": return "Fit"
        case "center": return "Original (1:1)"
        case "fill": return "Crop to Fill"
        case "stretch": return "Stretch"
        case "zoom": return "Zoom"
        default: return "Fit"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(wallpaper.title)
                        .font(.title2)
                        .bold()
                    Text("\(wallpaper.category) • \(wallpaper.resolutionTag)\(wallpaper.formattedFileSize.isEmpty ? "" : " • " + wallpaper.formattedFileSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .macaButtonStyle(.primary)
            }
            
            // Large Full Preview Stage
            ZStack {
                Color.black.opacity(0.9)
                
                if (wallpaper.type == .builtInWeb || wallpaper.type == .webUrl || wallpaper.pathOrUrl.hasSuffix(".html")),
                   let url = WallpaperStorageManager.shared.resolveURL(for: wallpaper) {
                    MiniWebPreviewView(url: url)
                } else if wallpaper.type == .video {
                    if let img = videoThumbnail {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if let img = WallpaperStorageManager.shared.resolveImage(for: wallpaper) {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ProgressView()
                    }
                } else if let img = WallpaperStorageManager.shared.resolveImage(for: wallpaper) {
                    // Static image preview respecting current placement mode
                    if settings.wallpaperPlacement == "fill" {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if settings.wallpaperPlacement == "stretch" {
                        Image(nsImage: img)
                            .resizable()
                    } else if settings.wallpaperPlacement == "center" {
                        Image(nsImage: img)
                            .frame(width: min(img.size.width, 700), height: min(img.size.height, 400))
                    } else if settings.wallpaperPlacement == "zoom" {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(CGFloat(settings.wallpaperZoom))
                    } else {
                        // Fit to screen (Preserve original proportions)
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .onAppear {
                generateVideoFrame()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if !wallpaper.author.isEmpty {
                        Text("Author / Source: \(wallpaper.author)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(wallpaper.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Wallpaper Sizing & Crop Selector
                Menu {
                    Picker("Placement Mode", selection: $settings.wallpaperPlacement) {
                        Label("Original (macOS Default)", systemImage: "viewfinder").tag("original")
                        Label("Fit to Screen (Preserve Aspect Ratio)", systemImage: "aspectratio").tag("fit")
                        Label("Crop to Fill Screen (Aspect Fill)", systemImage: "crop").tag("fill")
                        Label("Stretch to Fill Screen", systemImage: "arrow.up.left.and.arrow.down.right").tag("stretch")
                        Label("Custom Zoom & Scale", systemImage: "plus.magnifyingglass").tag("zoom")
                    }
                    
                    if settings.wallpaperPlacement == "zoom" || settings.wallpaperPlacement == "center" || settings.wallpaperPlacement == "original" {
                        Divider()
                        Button("Reset Zoom (100%)") { settings.wallpaperZoom = 1.0 }
                        Button("Zoom In (125%)") { settings.wallpaperZoom = 1.25 }
                        Button("Zoom In (150%)") { settings.wallpaperZoom = 1.5 }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "crop")
                        Text("Sizing & Crop: \(placementLabel(settings.wallpaperPlacement))")
                    }
                }
                .menuStyle(.borderedButton)
                .help("Configure how this wallpaper is sized, cropped, or scaled on your display")
                
                Button(action: {
                    storage.setActiveWallpaper(wallpaper)
                    engine.reloadEngine()
                    engine.updatePlacementSettings(placement: settings.wallpaperPlacement, zoom: settings.wallpaperZoom)
                    dismiss()
                }) {
                    Label("Apply as Desktop Wallpaper", systemImage: "checkmark.circle.fill")
                }
                .macaButtonStyle(.primary)
            }
        }
        .padding(20)
        .frame(minWidth: 740, minHeight: 540)
        .onChange(of: settings.wallpaperPlacement) { newPlacement in
            engine.updatePlacementSettings(placement: newPlacement, zoom: settings.wallpaperZoom)
        }
        .onChange(of: settings.wallpaperZoom) { newZoom in
            engine.updatePlacementSettings(placement: settings.wallpaperPlacement, zoom: newZoom)
        }
    }
    
    private func generateVideoFrame() {
        guard let url = WallpaperStorageManager.shared.resolveURL(for: wallpaper) else { return }
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1.0, preferredTimescale: 60)
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
            if let image = image {
                let nsImg = NSImage(cgImage: image, size: NSSize(width: 640, height: 360))
                DispatchQueue.main.async {
                    self.videoThumbnail = nsImg
                }
            }
        }
    }
}
