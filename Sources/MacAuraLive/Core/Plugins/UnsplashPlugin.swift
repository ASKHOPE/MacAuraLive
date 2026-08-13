import Foundation

public class UnsplashPlugin: OnlineWallpaperPlugin {
    public let provider: WallpaperSourceProvider = .unsplash
    
    public var apiKey: String {
        get { AppSettings.shared.unsplashApiKey }
        set { AppSettings.shared.unsplashApiKey = newValue }
    }
    
    public var isConfigured: Bool {
        return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public init() {}
    
    public func fetchWallpapers(
        query: String,
        page: Int = 1,
        perPage: Int = 20,
        mediaType: WallpaperType? = nil
    ) async throws -> [OnlineWallpaperItem] {
        // Unsplash only serves static photography (.image)
        if let mediaType = mediaType, mediaType != .image {
            return []
        }
        
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty {
            return try await fetchFromUnsplashAPI(key: trimmedKey, query: query, page: page, perPage: perPage)
        } else {
            return getCuratedFallback(query: query)
        }
    }
    
    private func fetchFromUnsplashAPI(
        key: String,
        query: String,
        page: Int,
        perPage: Int
    ) async throws -> [OnlineWallpaperItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpointString: String
        if cleanQuery.isEmpty || cleanQuery.lowercased() == "all" {
            endpointString = "https://api.unsplash.com/photos?page=\(page)&per_page=\(perPage)&order_by=popular"
        } else {
            guard let encoded = cleanQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return []
            }
            endpointString = "https://api.unsplash.com/search/photos?query=\(encoded)&page=\(page)&per_page=\(perPage)&orientation=landscape"
        }
        
        guard let url = URL(string: endpointString) else { return [] }
        
        var request = URLRequest(url: url)
        request.setValue("Client-ID \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        request.timeoutInterval = 15.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResp = response as? HTTPURLResponse else { return [] }
        
        guard httpResp.statusCode == 200 else {
            if httpResp.statusCode == 401 || httpResp.statusCode == 403 {
                throw NSError(domain: "UnsplashPlugin", code: httpResp.statusCode, userInfo: [NSLocalizedDescriptionKey: "Invalid or rate-limited Unsplash API Access Key."])
            }
            throw NSError(domain: "UnsplashPlugin", code: httpResp.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unsplash API returned HTTP \(httpResp.statusCode)"])
        }
        
        var items: [OnlineWallpaperItem] = []
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        let rawPhotos: [[String: Any]]
        if let dict = json as? [String: Any], let results = dict["results"] as? [[String: Any]] {
            rawPhotos = results
        } else if let array = json as? [[String: Any]] {
            rawPhotos = array
        } else {
            rawPhotos = []
        }
        
        for item in rawPhotos {
            guard let id = item["id"] as? String,
                  let urls = item["urls"] as? [String: Any],
                  let regularUrl = urls["regular"] as? String ?? urls["full"] as? String,
                  let rawUrl = urls["raw"] as? String ?? urls["full"] as? String else {
                continue
            }
            
            let description = (item["description"] as? String) ?? (item["alt_description"] as? String) ?? "Unsplash Wallpaper \(id)"
            let user = item["user"] as? [String: Any] ?? [:]
            let userName = (user["name"] as? String) ?? "Unknown Photographer"
            let userUsername = (user["username"] as? String) ?? ""
            let authorProfileUrl = "https://unsplash.com/@\(userUsername)?utm_source=MacAuraLive&utm_medium=referral"
            let userProfileImage = (user["profile_image"] as? [String: Any])?["medium"] as? String
            let links = item["links"] as? [String: Any] ?? [:]
            let htmlLink = (links["html"] as? String) ?? "https://unsplash.com/photos/\(id)?utm_source=MacAuraLive&utm_medium=referral"
            
            let width = item["width"] as? Int
            let height = item["height"] as? Int
            let resTag = (width ?? 0) >= 3840 ? "4K UHD" : ((width ?? 0) >= 2560 ? "2K QHD" : "1080p")
            
            // Download URL requesting 4K resolution
            let download4kUrl = "\(rawUrl)&w=3840&q=85&fit=crop"
            
            items.append(OnlineWallpaperItem(
                id: "unsplash_\(id)",
                provider: .unsplash,
                title: description.capitalized,
                authorName: userName,
                authorUrl: authorProfileUrl,
                authorAvatarUrl: userProfileImage,
                previewUrl: regularUrl,
                downloadUrl: download4kUrl,
                mediaType: .image,
                resolutionTag: resTag,
                width: width,
                height: height,
                durationSeconds: nil,
                hasAudio: false,
                licenseNotice: "Unsplash License (Free to use)",
                sourcePageUrl: htmlLink
            ))
        }
        
        return items
    }
    
    public func testConnection() async -> (success: Bool, message: String) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            return (false, "Please enter an Unsplash Access Key.")
        }
        
        guard let url = URL(string: "https://api.unsplash.com/photos?per_page=1") else {
            return (false, "Invalid endpoint URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue("Client-ID \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 200 {
                    return (true, "Connected to Unsplash API successfully! (Status: 200 OK)")
                } else if http.statusCode == 401 || http.statusCode == 403 {
                    return (false, "Authentication Failed (401/403): Check your Access Key in Unsplash Developer Dashboard.")
                } else {
                    return (false, "Unsplash HTTP error: \(http.statusCode)")
                }
            }
            return (false, "No HTTP response")
        } catch {
            return (false, "Connection error: \(error.localizedDescription)")
        }
    }
    
    private func getCuratedFallback(query: String) -> [OnlineWallpaperItem] {
        let curated: [OnlineWallpaperItem] = [
            OnlineWallpaperItem(
                id: "unsplash_XD5oKCerKCQ",
                provider: .unsplash,
                title: "Turbulent Ocean Water Swirls",
                authorName: "Kristaps Ungurs",
                authorUrl: "https://unsplash.com/@kristapsungurs?utm_source=MacAuraLive&utm_medium=referral",
                previewUrl: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80",
                downloadUrl: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=3840&q=90",
                mediaType: .image,
                resolutionTag: "4K UHD",
                licenseNotice: "Unsplash License",
                sourcePageUrl: "https://unsplash.com/photos/XD5oKCerKCQ?utm_source=MacAuraLive&utm_medium=referral"
            ),
            OnlineWallpaperItem(
                id: "unsplash_lXHx-zumrJs",
                provider: .unsplash,
                title: "Abstract Blue Mountain Ridges",
                authorName: "Oxana Golubets",
                authorUrl: "https://unsplash.com/@ok_milka?utm_source=MacAuraLive&utm_medium=referral",
                previewUrl: "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800&q=80",
                downloadUrl: "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=3840&q=90",
                mediaType: .image,
                resolutionTag: "4K UHD",
                licenseNotice: "Unsplash License",
                sourcePageUrl: "https://unsplash.com/photos/lXHx-zumrJs?utm_source=MacAuraLive&utm_medium=referral"
            ),
            OnlineWallpaperItem(
                id: "unsplash_Ype8P9pAjXQ",
                provider: .unsplash,
                title: "Abstract Blue Layered Curves",
                authorName: "Hassaan Here",
                authorUrl: "https://unsplash.com/@hassaanhre?utm_source=MacAuraLive&utm_medium=referral",
                previewUrl: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&q=80",
                downloadUrl: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=3840&q=90",
                mediaType: .image,
                resolutionTag: "4K UHD",
                licenseNotice: "Unsplash License",
                sourcePageUrl: "https://unsplash.com/photos/Ype8P9pAjXQ?utm_source=MacAuraLive&utm_medium=referral"
            ),
            OnlineWallpaperItem(
                id: "unsplash_cosmic_space",
                provider: .unsplash,
                title: "Deep Cosmos Nebula & Starfield",
                authorName: "NASA Archive",
                authorUrl: "https://unsplash.com/@nasa?utm_source=MacAuraLive&utm_medium=referral",
                previewUrl: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&q=80",
                downloadUrl: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=3840&q=90",
                mediaType: .image,
                resolutionTag: "4K UHD",
                licenseNotice: "Unsplash License (Public Domain / NASA)",
                sourcePageUrl: "https://unsplash.com/photos/451187580459?utm_source=MacAuraLive&utm_medium=referral"
            )
        ]
        
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty || q == "all" {
            return curated
        }
        return curated.filter {
            $0.title.lowercased().contains(q) || $0.authorName.lowercased().contains(q)
        }
    }
}
