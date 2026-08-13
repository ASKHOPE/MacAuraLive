import SwiftUI

public struct MarketplaceView: View {
    @ObservedObject var marketplace = OnlineMarketplaceManager.shared
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var storage = WallpaperStorageManager.shared
    
    @State private var showApiKeyModal: Bool = false
    @State private var showTermsModal: Bool = false
    @State private var testingProvider: WallpaperSourceProvider? = nil
    @State private var testResults: [WallpaperSourceProvider: (success: Bool, message: String)] = [:]
    
    let discoveryTags = ["All", "Nature", "Ocean", "Cyberpunk", "Minimal", "Space", "Abstract", "Mountains", "Dark"]
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header Bar
            headerView
            
            // Filter Bars (Providers, Media Type, Discovery Tags)
            filterBarView
            
            // Main Content Area
            if marketplace.isLoading && marketplace.wallpapers.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.3)
                    Text("Fetching wallpapers from online providers...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = marketplace.errorMessage, marketplace.wallpapers.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("Unable to load online wallpapers")
                        .font(.title3)
                        .bold()
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                    Button("Retry Fetch") {
                        Task { await marketplace.fetchMarketplaceWallpapers() }
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                wallpapersGridView
            }
        }
        .padding(24)
        .sheet(isPresented: $showApiKeyModal) {
            apiKeyConfigurationModal
        }
        .sheet(isPresented: $showTermsModal) {
            termsAndLicensingModal
        }
        .overlay(alignment: .bottom) {
            if let toast = marketplace.statusToast {
                Text(toast)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(radius: 8)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation { marketplace.statusToast = nil }
                        }
                    }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Marketplace")
                        .font(.system(size: 28, weight: .bold))
                    Text("ONLINE PLUGINS")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                Text("Discover and download 4K wallpapers and cinematic motion loops from Unsplash, Pixabay, and Pexels.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 10) {
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search online...", text: $marketplace.searchQuery)
                        .textFieldStyle(.plain)
                        .frame(width: 160)
                        .onSubmit {
                            Task { await marketplace.fetchMarketplaceWallpapers() }
                        }
                    if !marketplace.searchQuery.isEmpty {
                        Button(action: {
                            marketplace.searchQuery = ""
                            Task { await marketplace.fetchMarketplaceWallpapers() }
                        }) {
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
                
                Button(action: { showApiKeyModal = true }) {
                    Label("Configure API Keys", systemImage: "key.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: { showTermsModal = true }) {
                    Label("Terms & License", systemImage: "doc.text.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBarView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Provider Selector Pills
                HStack(spacing: 8) {
                    ForEach(WallpaperSourceProvider.allCases) { prov in
                        Button(action: {
                            marketplace.selectedProvider = prov
                            Task { await marketplace.fetchMarketplaceWallpapers() }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: prov.iconName)
                                    .font(.caption)
                                Text(prov.rawValue)
                                    .font(.caption)
                                    .fontWeight(marketplace.selectedProvider == prov ? .bold : .medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(marketplace.selectedProvider == prov ? Color.blue : Color.white.opacity(0.08))
                            .foregroundColor(marketplace.selectedProvider == prov ? .white : .secondary)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Divider()
                    .frame(height: 18)
                
                // Media Type Selector Pills
                HStack(spacing: 6) {
                    Button(action: {
                        marketplace.selectedMediaTypeFilter = nil
                        Task { await marketplace.fetchMarketplaceWallpapers() }
                    }) {
                        Text("All Types")
                            .font(.caption)
                            .fontWeight(marketplace.selectedMediaTypeFilter == nil ? .bold : .medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(marketplace.selectedMediaTypeFilter == nil ? Color.purple : Color.white.opacity(0.08))
                            .foregroundColor(marketplace.selectedMediaTypeFilter == nil ? .white : .secondary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        marketplace.selectedMediaTypeFilter = .image
                        Task { await marketplace.fetchMarketplaceWallpapers() }
                    }) {
                        Label("4K Photos", systemImage: "photo.fill")
                            .font(.caption)
                            .fontWeight(marketplace.selectedMediaTypeFilter == .image ? .bold : .medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(marketplace.selectedMediaTypeFilter == .image ? Color.purple : Color.white.opacity(0.08))
                            .foregroundColor(marketplace.selectedMediaTypeFilter == .image ? .white : .secondary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        marketplace.selectedMediaTypeFilter = .video
                        Task { await marketplace.fetchMarketplaceWallpapers() }
                    }) {
                        Label("Video Loops", systemImage: "play.rectangle.fill")
                            .font(.caption)
                            .fontWeight(marketplace.selectedMediaTypeFilter == .video ? .bold : .medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(marketplace.selectedMediaTypeFilter == .video ? Color.purple : Color.white.opacity(0.08))
                            .foregroundColor(marketplace.selectedMediaTypeFilter == .video ? .white : .secondary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Quick Discovery Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(discoveryTags, id: \.self) { tag in
                        Button(action: {
                            marketplace.activeTag = tag
                            marketplace.searchQuery = tag == "All" ? "" : tag
                            Task { await marketplace.fetchMarketplaceWallpapers() }
                        }) {
                            Text(tag == "All" ? "✨ All Discoveries" : "# \(tag)")
                                .font(.caption2)
                                .fontWeight(marketplace.activeTag == tag ? .bold : .medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(marketplace.activeTag == tag ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                                .foregroundColor(marketplace.activeTag == tag ? .white : .secondary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
    }
    
    // MARK: - Wallpapers Grid
    
    private var wallpapersGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 340), spacing: 20)], spacing: 20) {
                ForEach(marketplace.wallpapers) { item in
                    MarketplaceCardView(item: item)
                }
            }
            .padding(.vertical, 6)
        }
    }
    
    // MARK: - API Key Configuration Modal
    
    private var apiKeyConfigurationModal: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configure Marketplace Plugin API Keys")
                        .font(.title2)
                        .bold()
                    Text("Enter your own free API keys to unlock higher rate limits and full search access.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Done") { showApiKeyModal = false }
                    .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Unsplash
                    providerKeyCard(
                        provider: .unsplash,
                        title: "Unsplash API Access Key",
                        desc: "Get free access to over 3 million high-resolution curated 4K photography assets.",
                        portalUrl: "https://unsplash.com/developers",
                        keyBinding: $settings.unsplashApiKey
                    )
                    
                    // Pixabay
                    providerKeyCard(
                        provider: .pixabay,
                        title: "Pixabay API Key",
                        desc: "Free access to high-definition video loops with audio and 4K creative images.",
                        portalUrl: "https://pixabay.com/api/docs/",
                        keyBinding: $settings.pixabayApiKey
                    )
                    
                    // Pexels
                    providerKeyCard(
                        provider: .pexels,
                        title: "Pexels API Key",
                        desc: "Discover curated trending landscape photography and motion video loops.",
                        portalUrl: "https://www.pexels.com/api/",
                        keyBinding: $settings.pexelsApiKey
                    )
                    
                    // Security Note
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hardware Enclave Security (macOS Keychain)")
                                .font(.caption)
                                .bold()
                            Text("Your API keys are encrypted locally using macOS Security.framework. They are never sent to any MacAuraLive server and communicate directly with provider APIs.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(10)
                }
            }
        }
        .padding(24)
        .frame(width: 580, height: 600)
    }
    
    private func providerKeyCard(
        provider: WallpaperSourceProvider,
        title: String,
        desc: String,
        portalUrl: String,
        keyBinding: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: provider.iconName)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
                Link("Get Free Key ↗", destination: URL(string: portalUrl)!)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Text(desc)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                SecureField("Paste API Key here...", text: keyBinding)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {
                    Task {
                        testingProvider = provider
                        var plugin: OnlineWallpaperPlugin
                        switch provider {
                        case .unsplash: plugin = marketplace.unsplashPlugin
                        case .pixabay: plugin = marketplace.pixabayPlugin
                        case .pexels: plugin = marketplace.pexelsPlugin
                        case .all: return
                        }
                        plugin.apiKey = keyBinding.wrappedValue
                        let res = await plugin.testConnection()
                        testResults[provider] = res
                        testingProvider = nil
                    }
                }) {
                    if testingProvider == provider {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 60)
                    } else {
                        Text("Test")
                            .font(.caption)
                            .frame(width: 60)
                    }
                }
                .buttonStyle(.bordered)
            }
            
            if let result = testResults[provider] {
                HStack(spacing: 6) {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.success ? .green : .red)
                    Text(result.message)
                        .font(.caption2)
                        .foregroundColor(result.success ? .green : .red)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
    
    // MARK: - Terms & Licensing Modal
    
    private var termsAndLicensingModal: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Marketplace Terms, Licenses & Disclosures")
                        .font(.title2)
                        .bold()
                    Text("Transparent information regarding third-party content rights, internet access, and local file storage.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Close") { showTermsModal = false }
                    .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Unsplash
                    disclosureSection(
                        title: "1. Unsplash Content & API Guidelines",
                        termsUrl: "https://unsplash.com/terms",
                        licenseUrl: "https://unsplash.com/license",
                        content: "Photos downloaded via the Unsplash plugin are licensed under the Unsplash License. They are free to download and use for personal or commercial projects without permission. Proper photographer attribution and direct links are preserved according to Unsplash API guidelines."
                    )
                    
                    // Pixabay
                    disclosureSection(
                        title: "2. Pixabay Content License",
                        termsUrl: "https://pixabay.com/service/terms/",
                        licenseUrl: "https://pixabay.com/service/license-summary/",
                        content: "All videos and images downloaded from Pixabay are free for commercial and non-commercial use across digital media. Attribution to Shivaay Singh and other Pixabay creators is provided in the wallpaper metadata."
                    )
                    
                    // Pexels
                    disclosureSection(
                        title: "3. Pexels License",
                        termsUrl: "https://www.pexels.com/terms/",
                        licenseUrl: "https://www.pexels.com/license/",
                        content: "Photos and videos from Pexels are free to use. Attribution is not required but recommended. Modifying and setting them as live or static wallpapers is fully permissible."
                    )
                    
                    // Network & Tracking Disclosure
                    VStack(alignment: .leading, spacing: 6) {
                        Text("4. Network Connectivity & Direct API Calls")
                            .font(.headline)
                        Text("When you browse or download from the Marketplace, MacAuraLive connects directly from your Mac to the respective third-party API servers (Unsplash, Pixabay, Pexels) over HTTPS. MacAuraLive runs no proxy or tracking server. Third-party providers may process your IP address and standard HTTP request headers according to their respective privacy policies.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
                    
                    // Local Storage & File Permissions
                    VStack(alignment: .leading, spacing: 6) {
                        Text("5. Local Machine Storage & Offline Persistence")
                            .font(.headline)
                        Text("All downloaded wallpapers are permanently saved directly on your local device under '~/Library/Application Support/MacAuraLive/Wallpapers/Downloads/'. Once downloaded, wallpapers function 100% offline without recurring network requests.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
                }
            }
        }
        .padding(24)
        .frame(width: 600, height: 600)
    }
    
    private func disclosureSection(title: String, termsUrl: String, licenseUrl: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                HStack(spacing: 8) {
                    Link("Terms ↗", destination: URL(string: termsUrl)!)
                        .font(.caption2)
                    Link("License ↗", destination: URL(string: licenseUrl)!)
                        .font(.caption2)
                }
            }
            Text(content)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}

// MARK: - Marketplace Card View

private struct MarketplaceCardView: View {
    let item: OnlineWallpaperItem
    @ObservedObject var marketplace = OnlineMarketplaceManager.shared
    @State private var isHovering: Bool = false
    
    var isDownloaded: Bool {
        marketplace.downloadedItemIds.contains(item.id)
    }
    
    var isDownloading: Bool {
        marketplace.downloadingItemIds.contains(item.id)
    }
    
    var progress: Double {
        marketplace.downloadProgress[item.id] ?? 0.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail Preview Container
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: item.previewUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/10, contentMode: .fill)
                    case .failure:
                        ZStack {
                            Color.black.opacity(0.4)
                            Image(systemName: "photo.badge.exclamationmark")
                                .foregroundColor(.secondary)
                        }
                        .aspectRatio(16/10, contentMode: .fill)
                    case .empty:
                        ZStack {
                            Color.black.opacity(0.3)
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        .aspectRatio(16/10, contentMode: .fill)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 160)
                .clipped()
                
                // Badges Overlay
                HStack(spacing: 6) {
                    // Provider Badge
                    Text(item.provider.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.75))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    
                    // Media Type / Audio Badge
                    if item.mediaType == .video {
                        HStack(spacing: 3) {
                            Image(systemName: "play.fill")
                            if item.hasAudio {
                                Image(systemName: "speaker.wave.2.fill")
                            }
                        }
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    
                    // Resolution Badge
                    Text(item.resolutionTag)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .padding(8)
            }
            
            // Info & Action Strip
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text("by")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        if let authorUrl = item.authorUrl, let url = URL(string: authorUrl) {
                            Link(item.authorName, destination: url)
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                        } else {
                            Text(item.authorName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 2)
                
                // Actions & Progress
                if isDownloading {
                    VStack(spacing: 4) {
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(.linear)
                        Text("Downloading 4K asset... \(Int(progress * 100))%")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                } else if isDownloaded {
                    HStack {
                        Label("Installed", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Spacer()
                        Button("Apply") {
                            if let local = WallpaperStorageManager.shared.wallpapers.first(where: { $0.id == item.id }) {
                                WallpaperStorageManager.shared.setActiveWallpaper(local)
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                } else {
                    HStack {
                        Button(action: {
                            Task {
                                _ = await marketplace.downloadAndInstallWallpaper(item, applyImmediately: true)
                            }
                        }) {
                            Label("Download & Set", systemImage: "arrow.down.circle.fill")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                _ = await marketplace.downloadAndInstallWallpaper(item, applyImmediately: false)
                            }
                        }) {
                            Image(systemName: "arrow.down.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Save to library without applying immediately")
                    }
                }
            }
            .padding(12)
        }
        .background(Color.white.opacity(isHovering ? 0.1 : 0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(isHovering ? 0.25 : 0.08), lineWidth: 1)
        )
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hover
            }
        }
    }
}
