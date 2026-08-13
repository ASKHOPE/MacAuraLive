import SwiftUI

public enum AITab: String, CaseIterable, Identifiable {
    case openRouter = "OpenRouter"
    case gemini = "Google Gemini"
    case local = "Local AI (LMStudio/Ollama)"
    case openAI = "ChatGPT (Coming Soon)"
    case claude = "Claude (Coming Soon)"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .openRouter: return "sparkles"
        case .gemini: return "sparkle"
        case .local: return "cpu"
        case .openAI: return "bubble.left.and.bubble.right"
        case .claude: return "brain.head.profile"
        }
    }
    
    public var isAvailable: Bool {
        switch self {
        case .openRouter, .gemini, .local: return true
        case .openAI, .claude: return false
        }
    }
}

public struct AIConfigurationView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var storage = WallpaperStorageManager.shared
    @ObservedObject var engine = WallpaperEngine.shared
    
    @State private var activeSubTab: AITab = .openRouter
    @State private var testPromptInput: String = "Cyberpunk synthwave neon grid with purple horizon sun and star particles"
    @State private var isGenerating: Bool = false
    @State private var terminalLogs: [String] = []
    @State private var showTerminalConsole: Bool = true
    
    // Key validation states
    @State private var validatingProvider: String? = nil
    @State private var validationFeedback: [String: (success: Bool, message: String)] = [:]
    
    // Live OpenRouter models list fetched from internet
    @State private var liveOpenRouterModels: [OpenRouterModelItem] = []
    @State private var isFetchingModels: Bool = false
    @State private var fetchModelsStatus: String? = nil
    
    let fallbackFreeModels = [
        "google/gemma-2-9b-it:free",
        "meta-llama/llama-3.3-70b-instruct:free",
        "deepseek/deepseek-r1:free",
        "qwen/qwen-2.5-coder-32b-instruct:free",
        "mistralai/mistral-7b-instruct:free"
    ]

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("AI Workshop")
                    .font(.system(size: 28, weight: .bold))
                Text("Generate 60fps WebGL shaders using Google Gemini, OpenRouter, or Local AI (Ollama).")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Sub-Tab Navigation Bar
            HStack(spacing: 10) {
                ForEach(AITab.allCases) { tab in
                    Button(action: {
                        if tab.isAvailable {
                            activeSubTab = tab
                            settings.selectedAIProvider = tab.rawValue
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 14, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(activeSubTab == tab ? .bold : .medium)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(activeSubTab == tab ? Color.pink : (tab.isAvailable ? Color.white.opacity(0.08) : Color.white.opacity(0.03)))
                        .foregroundColor(tab.isAvailable ? .white : .secondary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(!tab.isAvailable)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .cornerRadius(16)
            
            // Tab Content Body
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch activeSubTab {
                    case .openRouter:
                        openRouterTabView
                    case .gemini:
                        geminiTabView
                    case .local:
                        localAiTabView
                    case .openAI, .claude:
                        comingSoonTabView(providerName: activeSubTab.rawValue)
                    }
                    
                    Divider()
                        .padding(.vertical, 2)
                    
                    // Unified AI Generator Tester & Live Terminal Console Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Generate Live Shader Wallpaper (\(activeSubTab == .openRouter ? "OpenRouter" : "Local AI"))")
                                .font(.headline)
                            Spacer()
                            
                            Button(action: { showTerminalConsole.toggle() }) {
                                Label(showTerminalConsole ? "Hide Terminal Output" : "Show Terminal Output", systemImage: "terminal.fill")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.black.opacity(0.4))
                                    .foregroundColor(.cyan)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        HStack(spacing: 12) {
                            TextField("Enter prompt to generate live shader (e.g. 'rain')...", text: $testPromptInput)
                                .textFieldStyle(.roundedBorder)
                            
                            if isGenerating {
                                Button(action: { stopGeneration() }) {
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
                                Button(action: { runTestGeneration() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                        Text("Generate AI Shader")
                                    }
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(LinearGradient(colors: [Color.purple, Color.pink], startPoint: .leading, endPoint: .trailing))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                .disabled(testPromptInput.isEmpty)
                            }
                        }
                        
                        // Live AI Output Terminal View
                        if showTerminalConsole {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Label("AI Terminal Output Log", systemImage: "terminal")
                                        .font(.caption2)
                                        .bold()
                                        .foregroundColor(.green)
                                    Spacer()
                                    Button("Clear Console") {
                                        terminalLogs.removeAll()
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .buttonStyle(.plain)
                                }
                                
                                ScrollViewReader { proxy in
                                    ScrollView {
                                        VStack(alignment: .leading, spacing: 4) {
                                            if terminalLogs.isEmpty {
                                                Text("$ MacAuraLive AI Engine initialized. Ready for prompt...")
                                                    .font(.system(.caption, design: .monospaced))
                                                    .foregroundColor(.gray)
                                            } else {
                                                ForEach(Array(terminalLogs.enumerated()), id: \.offset) { idx, log in
                                                    Text(log)
                                                        .font(.system(.caption, design: .monospaced))
                                                        .foregroundColor(log.contains("ERROR") || log.contains("KILLED") ? .red : (log.contains("SUCCESS") || log.contains("DONE") ? .green : .cyan))
                                                        .id(idx)
                                                }
                                            }
                                        }
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(height: 140)
                                    .background(Color.black)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                                    .onChange(of: terminalLogs.count) { _ in
                                        if let lastIdx = terminalLogs.indices.last {
                                            proxy.scrollTo(lastIdx, anchor: .bottom)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(Color.pink.opacity(0.08))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .onAppear {
            fetchLiveModels()
        }
    }
    
    @State private var geminiApiKey: String = KeychainManager.shared.getKey(forAccount: "geminiApiKey")
    
    // MARK: - Google Gemini Tab View
    @ViewBuilder
    private var geminiTabView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Google Gemini API", systemImage: "sparkle")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.blue)
                Spacer()
                Text("Gemini 2.0 Flash / 1.5 Flash")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Google Gemini API Key:")
                    .font(.caption)
                    .bold()
                
                HStack(spacing: 8) {
                    SecureField("AIzaSy...", text: $geminiApiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: {
                        let clean = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !clean.isEmpty else {
                            validationFeedback["Google Gemini"] = (false, "Cannot save empty key. Please enter your API key.")
                            return
                        }
                        KeychainManager.shared.saveKey(clean, forAccount: "geminiApiKey")
                        validationFeedback["Google Gemini"] = (true, "Key saved securely to macOS Keychain.")
                    }) {
                        Label("Save Key", systemImage: "square.and.arrow.down.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(action: {
                        let clean = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !clean.isEmpty else {
                            validationFeedback["Google Gemini"] = (false, "Please enter your API key before testing.")
                            return
                        }
                        KeychainManager.shared.saveKey(clean, forAccount: "geminiApiKey")
                        validateKey(provider: "Google Gemini")
                    }) {
                        HStack(spacing: 4) {
                            if validatingProvider == "Google Gemini" {
                                ProgressView().controlSize(.small)
                            }
                            Text(validatingProvider == "Google Gemini" ? "Testing..." : "Test Key")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .disabled(geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || validatingProvider != nil)
                    
                    Button(action: {
                        geminiApiKey = ""
                        KeychainManager.shared.saveKey("", forAccount: "geminiApiKey")
                        validationFeedback.removeValue(forKey: "Google Gemini")
                    }) {
                        Label("Clear Key", systemImage: "trash.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(geminiApiKey.isEmpty)
                }
                
                Text("API keys are hardware-encrypted at rest inside your macOS system Keychain via Security.framework.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if let feedback = validationFeedback["Google Gemini"] ?? validationFeedback["Gemini"] {
                HStack(spacing: 6) {
                    Image(systemName: feedback.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(feedback.success ? .green : .red)
                    Text(feedback.message)
                        .font(.caption)
                        .foregroundColor(feedback.success ? .green : .red)
                }
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - OpenRouter Tab View
    @ViewBuilder
    private var openRouterTabView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("OpenRouter API", systemImage: "sparkles")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.pink)
                Spacer()
                
                Button(action: { fetchLiveModels() }) {
                    HStack(spacing: 4) {
                        if isFetchingModels {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Fetch Live Models from Internet")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.pink.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isFetchingModels)
            }
            
            if let status = fetchModelsStatus {
                Text(status)
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Select OpenRouter Model:")
                    .font(.subheadline)
                    .bold()
                
                Picker("", selection: $settings.openRouterModel) {
                    if liveOpenRouterModels.isEmpty {
                        ForEach(fallbackFreeModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    } else {
                        ForEach(liveOpenRouterModels) { model in
                            Text(model.isFree ? "🎁 " + model.name : model.name).tag(model.id)
                        }
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("OpenRouter API Key (Optional for higher free quota):")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    SecureField("sk-or-v1-...", text: $settings.openRouterApiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: {
                        let clean = settings.openRouterApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !clean.isEmpty else {
                            validationFeedback["OpenRouter"] = (false, "Cannot save empty key. Please enter your API key.")
                            return
                        }
                        settings.openRouterApiKey = clean
                        validationFeedback["OpenRouter"] = (true, "Key saved to Preferences.")
                    }) {
                        Label("Save Key", systemImage: "square.and.arrow.down.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(settings.openRouterApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(action: {
                        let clean = settings.openRouterApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !clean.isEmpty else {
                            validationFeedback["OpenRouter"] = (false, "Please enter your API key before testing.")
                            return
                        }
                        validateKey(provider: "OpenRouter")
                    }) {
                        HStack(spacing: 4) {
                            if validatingProvider == "OpenRouter" {
                                ProgressView().controlSize(.small)
                            }
                            Text(validatingProvider == "OpenRouter" ? "Testing..." : "Test Key")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .disabled(settings.openRouterApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || validatingProvider != nil)
                    
                    Button(action: {
                        settings.openRouterApiKey = ""
                        validationFeedback.removeValue(forKey: "OpenRouter")
                    }) {
                        Label("Clear Key", systemImage: "trash.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(settings.openRouterApiKey.isEmpty)
                }
                
                if let fb = validationFeedback["OpenRouter"] {
                    HStack(spacing: 6) {
                        Image(systemName: fb.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(fb.success ? .green : .red)
                        Text(fb.message)
                            .font(.caption)
                            .foregroundColor(fb.success ? .green : .red)
                    }
                }
            }
        }
        .padding(18)
        .background(Color.purple.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.pink.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Local AI (LMStudio / Ollama) Tab View
    @ViewBuilder
    private var localAiTabView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Local AI / LMStudio / Ollama", systemImage: "cpu")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.green)
                Spacer()
                Text("100% Offline • LMStudio Ready")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("LMStudio / Ollama OpenAPI Local Endpoint URL:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("http://localhost:1234/v1 or http://localhost:11434/v1", text: $settings.localApiEndpoint)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: { validateKey(provider: "Local AI") }) {
                        HStack(spacing: 6) {
                            if validatingProvider == "Local AI" {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "bolt.horizontal.fill")
                            }
                            Text("Test LMStudio Endpoint")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(validatingProvider != nil)
                }
                
                if let fb = validationFeedback["Local AI"] {
                    HStack {
                        Image(systemName: fb.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        Text(fb.message)
                    }
                    .font(.caption)
                    .foregroundColor(fb.success ? .green : .red)
                }
            }
        }
        .padding(18)
        .background(Color.green.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Coming Soon Tab View
    @ViewBuilder
    private func comingSoonTabView(providerName: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text(providerName)
                .font(.headline)
                .bold()
            Text("Direct API connection for this provider is coming soon. Please use OpenRouter or Local AI (LMStudio) for live shader generation.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    private func fetchLiveModels() {
        isFetchingModels = true
        fetchModelsStatus = "Fetching live models from OpenRouter..."
        
        AIGenerationManager.shared.fetchOpenRouterModels { result in
            DispatchQueue.main.async {
                isFetchingModels = false
                switch result {
                case .success(let models):
                    liveOpenRouterModels = models
                    fetchModelsStatus = "Successfully fetched \(models.count) live model(s) from OpenRouter API."
                case .failure(let err):
                    fetchModelsStatus = "Internet model fetch notice: \(err.localizedDescription). Using built-in models."
                }
            }
        }
    }
    
    private func validateKey(provider: String) {
        validatingProvider = provider
        let key: String
        if provider.contains("Google") || provider.contains("Gemini") {
            key = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if provider.contains("OpenRouter") {
            key = settings.openRouterApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            key = ""
        }
        
        guard !key.isEmpty || provider.contains("Local") else {
            validatingProvider = nil
            validationFeedback[provider] = (false, "API key cannot be empty. Please enter your API key first.")
            return
        }
        
        AIGenerationManager.shared.validateAPIKey(
            provider: provider,
            apiKey: key,
            endpoint: settings.localApiEndpoint,
            model: settings.openRouterModel
        ) { result in
            DispatchQueue.main.async {
                self.validatingProvider = nil
                switch result {
                case .success(let msg):
                    self.validationFeedback[provider] = (true, msg)
                    self.appendLog("[VALIDATE_OK] \(msg)")
                case .failure(let err):
                    self.validationFeedback[provider] = (false, err.localizedDescription)
                    self.appendLog("[VALIDATE_ERR] \(err.localizedDescription)")
                }
            }
        }
    }
    
    private func runTestGeneration() {
        isGenerating = true
        let provider = activeSubTab.rawValue
        appendLog("[START] Launching 60fps WebGL/Canvas Shader generation using \(provider)...")
        
        AIGenerationManager.shared.generateWallpaper(
            prompt: testPromptInput,
            provider: provider,
            onStatusUpdate: { status in
                DispatchQueue.main.async {
                    self.appendLog(status)
                }
            }
        ) { result in
            DispatchQueue.main.async {
                isGenerating = false
                switch result {
                case .success(let html):
                    if let item = storage.generateGenAIWallpaper(
                        prompt: testPromptInput,
                        style: provider,
                        resolution: "4K UHD",
                        htmlCode: html
                    ) {
                        engine.reloadEngine()
                        appendLog("[SUCCESS] Applied live 60fps shader wallpaper '\(item.title)'!")
                    }
                case .failure(let err):
                    appendLog("[NOTICE] \(err.localizedDescription). Loaded procedural 60fps canvas shader.")
                    _ = storage.generateGenAIWallpaper(
                        prompt: testPromptInput,
                        style: provider,
                        resolution: "4K UHD"
                    )
                    engine.reloadEngine()
                }
            }
        }
    }
    
    private func stopGeneration() {
        AIGenerationManager.shared.stopGeneration()
        isGenerating = false
        appendLog("[KILLED] User manually stopped AI generation task.")
    }
    
    private func appendLog(_ text: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        terminalLogs.append("[\(timestamp)] \(text)")
    }
}
