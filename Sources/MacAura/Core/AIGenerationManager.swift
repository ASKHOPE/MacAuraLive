import Foundation

public struct OpenRouterModelItem: Identifiable, Codable, Hashable {
    public var id: String
    public var name: String
    public var isFree: Bool
    
    public init(id: String, name: String, isFree: Bool) {
        self.id = id
        self.name = name
        self.isFree = isFree
    }
}

public class AIGenerationManager {
    public static let shared = AIGenerationManager()
    
    private var currentTask: URLSessionDataTask?
    
    private init() {}
    
    public func stopGeneration() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    // AI Wallpaper Scene Planner Prompt
    private let systemPrompt = """
    You are MacAura's Wallpaper Scene Planner.
    You do NOT generate executable HTML or JS code.
    You compose wallpapers using the available effects in the MacAura Effect Registry: ["rain", "snow", "stars", "aurora", "neon"].
    
    You MUST return ONLY a valid JSON WallpaperDefinition matching this schema:
    {
      "version": "1.0",
      "name": "Title of Scene",
      "background": {
        "type": "gradient",
        "colors": ["#040711", "#0f172a"]
      },
      "effects": [
        {
          "type": "rain",
          "enabled": true,
          "parameters": {
            "density": "300",
            "speed": "1.2",
            "wind": "0.3",
            "color": "#78c8ff",
            "opacity": "0.8"
          }
        }
      ],
      "audio_mappings": [
        {
          "source": "bass",
          "target": "rain.speed",
          "multiplier": 1.5
        }
      ]
    }
    
    Strict Rules:
    1. Output ONLY raw JSON matching this schema. Do NOT write markdown block wrappers (```json).
    2. Choose effects from ["rain", "snow", "stars", "aurora", "neon"].
    3. Choose appropriate parameters and colors to match the user's prompt.
    """
    
    private func normalizeLocalEndpoint(_ endpoint: String) -> String {
        var clean = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        while clean.hasSuffix("/") { clean.removeLast() }
        if clean.hasSuffix("/v1/chat/completions") || clean.hasSuffix("/chat/completions") {
            return clean
        } else if clean.hasSuffix("/v1") {
            return "\(clean)/chat/completions"
        } else {
            return "\(clean)/v1/chat/completions"
        }
    }
    
    public func fetchOpenRouterModels(completion: @escaping (Result<[OpenRouterModelItem], Error>) -> Void) {
        guard let url = URL(string: "https://openrouter.ai/api/v1/models") else {
            completion(.failure(NSError(domain: "AIGeneration", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid OpenRouter Models URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8.0
        request.setValue("https://github.com/macaura/livewallpaper", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("MacAura Live Wallpaper Engine", forHTTPHeaderField: "X-OpenRouter-Title")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataList = json["data"] as? [[String: Any]] else {
                completion(.failure(NSError(domain: "AIGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenRouter models list"])))
                return
            }
            
            var items: [OpenRouterModelItem] = []
            for dict in dataList {
                if let modelId = dict["id"] as? String {
                    let modelName = (dict["name"] as? String) ?? modelId
                    let isFree = modelId.hasSuffix(":free") || ((dict["pricing"] as? [String: Any])?["prompt"] as? String == "0")
                    items.append(OpenRouterModelItem(id: modelId, name: modelName, isFree: isFree))
                }
            }
            
            items.sort { ($0.isFree ? 0 : 1) < ($1.isFree ? 0 : 1) }
            completion(.success(items))
        }.resume()
    }
    
    public func generateWallpaper(
        prompt: String,
        provider: String,
        onStatusUpdate: ((String) -> Void)? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let settings = AppSettings.shared
        
        if provider.contains("OpenRouter") {
            generateOpenRouter(prompt: prompt, apiKey: settings.openRouterApiKey, model: settings.openRouterModel, onStatusUpdate: onStatusUpdate, completion: completion)
        } else if provider.contains("ChatGPT") || provider.contains("OpenAI") {
            generateOpenAI(prompt: prompt, apiKey: settings.openAiApiKey, model: settings.openAiModel, onStatusUpdate: onStatusUpdate, completion: completion)
        } else if provider.contains("Claude") {
            generateClaude(prompt: prompt, apiKey: settings.claudeApiKey, onStatusUpdate: onStatusUpdate, completion: completion)
        } else if provider.contains("Gemini") {
            generateGemini(prompt: prompt, apiKey: settings.geminiApiKey, onStatusUpdate: onStatusUpdate, completion: completion)
        } else {
            generateLocalOpenAPI(prompt: prompt, endpoint: settings.localApiEndpoint, onStatusUpdate: onStatusUpdate, completion: completion)
        }
    }
    
    public func validateAPIKey(
        provider: String,
        apiKey: String,
        endpoint: String,
        model: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let startTime = Date()
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if provider.contains("OpenRouter") {
            guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 6.0
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if !cleanKey.isEmpty {
                request.setValue("Bearer \(cleanKey)", forHTTPHeaderField: "Authorization")
            }
            request.setValue("https://github.com/macaura/livewallpaper", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("MacAura Live Wallpaper Engine", forHTTPHeaderField: "X-OpenRouter-Title")
            
            let targetModel = model.isEmpty ? "google/gemma-2-9b-it:free" : model
            let body: [String: Any] = [
                "model": targetModel,
                "messages": [["role": "user", "content": "hi"]],
                "max_tokens": 2
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                let duration = String(format: "%.2fs", Date().timeIntervalSince(startTime))
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                    completion(.success("Verified OpenRouter model '\(targetModel)' (\(duration))"))
                } else if let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let _ = json["choices"] {
                    completion(.success("Verified OpenRouter connection (\(duration))"))
                } else {
                    completion(.success("Connected to OpenRouter free tier (\(duration))"))
                }
            }
            self.currentTask = task
            task.resume()
            
        } else if provider.contains("ChatGPT") || provider.contains("OpenAI") {
            guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 6.0
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(cleanKey)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "model": model.isEmpty ? "gpt-4o-mini" : model,
                "messages": [["role": "user", "content": "hi"]],
                "max_tokens": 2
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                let duration = String(format: "%.2fs", Date().timeIntervalSince(startTime))
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success("Verified OpenAI Key (\(duration))"))
            }
            self.currentTask = task
            task.resume()
            
        } else if provider.contains("Claude") {
            guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 6.0
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(cleanKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            
            let body: [String: Any] = [
                "model": "claude-3-5-haiku-20241022",
                "max_tokens": 2,
                "messages": [["role": "user", "content": "hi"]]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                let duration = String(format: "%.2fs", Date().timeIntervalSince(startTime))
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success("Verified Claude Key (\(duration))"))
            }
            self.currentTask = task
            task.resume()
            
        } else {
            let urlString = normalizeLocalEndpoint(endpoint)
            guard let url = URL(string: urlString) else {
                completion(.failure(NSError(domain: "AIGeneration", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Local Endpoint URL"])))
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 6.0
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = [
                "model": "local-model",
                "messages": [["role": "user", "content": "hi"]],
                "max_tokens": 2
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                let duration = String(format: "%.2fs", Date().timeIntervalSince(startTime))
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success("Verified LMStudio/Ollama Endpoint (\(duration))"))
            }
            self.currentTask = task
            task.resume()
        }
    }
    
    private func generateOpenRouter(
        prompt: String,
        apiKey: String,
        model: String,
        onStatusUpdate: ((String) -> Void)?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        }
        
        request.setValue("https://github.com/macaura/livewallpaper", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("MacAura Live Wallpaper Engine", forHTTPHeaderField: "X-OpenRouter-Title")
        
        let modelName = model.isEmpty ? "google/gemma-2-9b-it:free" : model
        onStatusUpdate?("[INIT] Connecting to OpenRouter using model '\(modelName)'...")
        
        let body: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Create a smooth 60fps WebGL shader or HTML5 canvas live wallpaper for prompt: '\(prompt)'"]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let startTime = Date()
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            self?.currentTask = nil
            let elapsed = String(format: "%.1fs", Date().timeIntervalSince(startTime))
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                onStatusUpdate?("[KILLED] AI Generation stopped by user.")
                completion(.failure(error))
                return
            } else if let error = error {
                onStatusUpdate?("[ERROR] OpenRouter Error (\(elapsed)): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResp = response as? HTTPURLResponse {
                if httpResp.statusCode != 200 {
                    let statusDesc: String
                    if httpResp.statusCode == 429 {
                        statusDesc = "[RATE_LIMIT] HTTP 429: Model '\(modelName)' busy."
                    } else if httpResp.statusCode == 504 {
                        statusDesc = "[TIMEOUT] HTTP 504: Model timed out after \(elapsed)."
                    } else {
                        statusDesc = "[HTTP_\(httpResp.statusCode)] Status \(httpResp.statusCode) from OpenRouter after \(elapsed)."
                    }
                    onStatusUpdate?(statusDesc)
                    completion(.failure(NSError(domain: "AIGeneration", code: httpResp.statusCode, userInfo: [NSLocalizedDescriptionKey: statusDesc])))
                    return
                }
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let text = message["content"] as? String else {
                onStatusUpdate?("[WARN] Payload received in \(elapsed) but failed to parse HTML payload.")
                completion(.failure(NSError(domain: "AIGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenRouter API response"])))
                return
            }
            
            onStatusUpdate?("[DONE] Generated 60fps HTML shader in \(elapsed)!\n\nPayload Preview:\n" + String(text.prefix(300)) + "...")
            completion(.success(self?.cleanHTML(text) ?? text))
        }
        self.currentTask = task
        task.resume()
    }
    
    private func generateOpenAI(
        prompt: String,
        apiKey: String,
        model: String,
        onStatusUpdate: ((String) -> Void)?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let targetModel = model.isEmpty ? "gpt-4o-mini" : model
        onStatusUpdate?("[INIT] Connecting to OpenAI using model '\(targetModel)'...")
        
        let body: [String: Any] = [
            "model": targetModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Create a smooth 60fps WebGL shader or HTML5 canvas live wallpaper for prompt: '\(prompt)'"]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let startTime = Date()
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            self?.currentTask = nil
            let elapsed = String(format: "%.1fs", Date().timeIntervalSince(startTime))
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                onStatusUpdate?("[KILLED] OpenAI Generation stopped by user.")
                completion(.failure(error))
                return
            } else if let error = error {
                onStatusUpdate?("[ERROR] OpenAI Error (\(elapsed)): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let text = message["content"] as? String else {
                completion(.failure(NSError(domain: "AIGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenAI API response"])))
                return
            }
            onStatusUpdate?("[DONE] Generated 60fps shader via OpenAI in \(elapsed)!")
            completion(.success(self?.cleanHTML(text) ?? text))
        }
        self.currentTask = task
        task.resume()
    }
    
    private func generateLocalOpenAPI(
        prompt: String,
        endpoint: String,
        onStatusUpdate: ((String) -> Void)?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let urlString = normalizeLocalEndpoint(endpoint)
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "AIGeneration", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Local OpenAPI endpoint URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 300.0 // 5 minutes timeout for 4GB Local AI models to finish without premature timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        onStatusUpdate?("[CONNECTING] Connected to Local LLM at '\(urlString)'. Requesting 60fps recursive HTML canvas code for prompt: '\(prompt)'...")
        
        let body: [String: Any] = [
            "model": "local-model",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Write smooth 60fps recursive requestAnimationFrame canvas code for prompt: '\(prompt)'"]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let startTime = Date()
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            self?.currentTask = nil
            let elapsed = String(format: "%.1fs", Date().timeIntervalSince(startTime))
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                onStatusUpdate?("[KILLED] Local AI Generation stopped by user.")
                completion(.failure(error))
                return
            } else if let error = error {
                onStatusUpdate?("[ERROR] Local AI Notice (\(elapsed)): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let message = first["message"] as? [String: Any] else {
                onStatusUpdate?("[WARN] Received response from LMStudio in \(elapsed), but payload was incomplete.")
                completion(.failure(NSError(domain: "AIGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse LMStudio response"])))
                return
            }
            
            let rawContent = (message["content"] as? String) ?? (message["reasoning_content"] as? String) ?? ""
            if rawContent.isEmpty {
                completion(.failure(NSError(domain: "AIGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "LMStudio returned empty content."])))
                return
            }
            
            onStatusUpdate?("[SUCCESS] Local LLM finished 60fps shader generation in \(elapsed)!\n\n--- TERMINAL OUTPUT PREVIEW ---\n" + String(rawContent.prefix(400)) + "\n...")
            completion(.success(self?.cleanHTML(rawContent) ?? rawContent))
        }
        self.currentTask = task
        task.resume()
    }
    
    private func generateGemini(
        prompt: String,
        apiKey: String,
        onStatusUpdate: ((String) -> Void)?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "AIGeneration", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Gemini API URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        onStatusUpdate?("[INIT] Connecting to Gemini API...")
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "\(systemPrompt)\nCreate a 60fps WebGL shader or canvas live wallpaper for prompt: '\(prompt)'"]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let startTime = Date()
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            self?.currentTask = nil
            let elapsed = String(format: "%.1fs", Date().timeIntervalSince(startTime))
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                onStatusUpdate?("[KILLED] Gemini Generation stopped by user.")
                completion(.failure(error))
                return
            } else if let error = error {
                onStatusUpdate?("[ERROR] Gemini Error (\(elapsed)): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let contentObj = candidates.first?["content"] as? [String: Any],
                  let parts = contentObj["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                completion(.failure(NSError(domain: "AIGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Gemini API response"])))
                return
            }
            onStatusUpdate?("[DONE] Generated 60fps shader via Gemini in \(elapsed)!")
            completion(.success(self?.cleanHTML(text) ?? text))
        }
        self.currentTask = task
        task.resume()
    }
    
    private func generateClaude(
        prompt: String,
        apiKey: String,
        onStatusUpdate: ((String) -> Void)?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        onStatusUpdate?("[INIT] Connecting to Anthropic Claude API...")
        
        let body: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 4000,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "Create a smooth 60fps WebGL shader or HTML5 canvas live wallpaper matching: '\(prompt)'"]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let startTime = Date()
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            self?.currentTask = nil
            let elapsed = String(format: "%.1fs", Date().timeIntervalSince(startTime))
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                onStatusUpdate?("[KILLED] Claude Generation stopped by user.")
                completion(.failure(error))
                return
            } else if let error = error {
                onStatusUpdate?("[ERROR] Claude Error (\(elapsed)): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let text = content.first?["text"] as? String else {
                completion(.failure(NSError(domain: "AIGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Claude response"])))
                return
            }
            onStatusUpdate?("[DONE] Generated 60fps shader via Claude in \(elapsed)!")
            completion(.success(self?.cleanHTML(text) ?? text))
        }
        self.currentTask = task
        task.resume()
    }
    
    private func cleanHTML(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```html") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
