import Foundation

public class PexelsPlugin: OnlineWallpaperPlugin {
    public let provider: WallpaperSourceProvider = .pexels
    
    public var apiKey: String {
        get { AppSettings.shared.pexelsApiKey }
        set { AppSettings.shared.pexelsApiKey = newValue }
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
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty {
            var results: [OnlineWallpaperItem] = []
            
            // If mediaType is nil or .image, fetch photos from Pexels
            if mediaType == nil || mediaType == .image {
                let photos = try await fetchPhotosFromPexels(key: trimmedKey, query: query, page: page, perPage: perPage)
                results.append(contentsOf: photos)
            }
            
            // If mediaType is nil or .video, fetch videos from Pexels
            if mediaType == nil || mediaType == .video {
                let videos = try await fetchVideosFromPexels(key: trimmedKey, query: query, page: page, perPage: perPage)
                results.append(contentsOf: videos)
            }
            
            return results
        } else {
            return getCuratedFallback(query: query, mediaType: mediaType)
        }
    }
    
    private func fetchPhotosFromPexels(
        key: String,
        query: String,
        page: Int,
        perPage: Int
    ) async throws -> [OnlineWallpaperItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpointString: String
        if cleanQuery.isEmpty || cleanQuery.lowercased() == "all" {
            endpointString = "https://api.pexels.com/v1/curated?page=\(page)&per_page=\(perPage)"
        } else {
            guard let encoded = cleanQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return []
            }
            endpointString = "https://api.pexels.com/v1/search?query=\(encoded)&page=\(page)&per_page=\(perPage)&orientation=landscape"
        }
        
        guard let url = URL(string: endpointString) else { return [] }
        var request = URLRequest(url: url)
        request.setValue(key, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let photos = json["photos"] as? [[String: Any]] else {
            return []
        }
        
        var items: [OnlineWallpaperItem] = []
        for photo in photos {
            guard let id = photo["id"] as? Int,
                  let src = photo["src"] as? [String: Any],
                  let mediumUrl = src["large2x"] as? String ?? src["large"] as? String,
                  let originalUrl = src["original"] as? String ?? src["large2x"] as? String else {
                continue
            }
            
            let alt = (photo["alt"] as? String) ?? "Pexels Wallpaper \(id)"
            let photographer = (photo["photographer"] as? String) ?? "Pexels Photographer"
            let photographerUrl = photo["photographer_url"] as? String
            let pageUrl = photo["url"] as? String
            let width = photo["width"] as? Int
            let height = photo["height"] as? Int
            let resTag = (width ?? 0) >= 3840 ? "4K UHD" : "1080p HD"
            
            items.append(OnlineWallpaperItem(
                id: "pexels_photo_\(id)",
                provider: .pexels,
                title: alt.capitalized,
                authorName: photographer,
                authorUrl: photographerUrl,
                authorAvatarUrl: nil,
                previewUrl: mediumUrl,
                downloadUrl: originalUrl,
                mediaType: .image,
                resolutionTag: resTag,
                width: width,
                height: height,
                durationSeconds: nil,
                hasAudio: false,
                licenseNotice: "Pexels License (Free to use)",
                sourcePageUrl: pageUrl
            ))
        }
        return items
    }
    
    private func fetchVideosFromPexels(
        key: String,
        query: String,
        page: Int,
        perPage: Int
    ) async throws -> [OnlineWallpaperItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpointString: String
        if cleanQuery.isEmpty || cleanQuery.lowercased() == "all" {
            endpointString = "https://api.pexels.com/videos/popular?page=\(page)&per_page=\(perPage)"
        } else {
            guard let encoded = cleanQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return []
            }
            endpointString = "https://api.pexels.com/videos/search?query=\(encoded)&page=\(page)&per_page=\(perPage)&orientation=landscape"
        }
        
        guard let url = URL(string: endpointString) else { return [] }
        var request = URLRequest(url: url)
        request.setValue(key, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let videos = json["videos"] as? [[String: Any]] else {
            return []
        }
        
        var items: [OnlineWallpaperItem] = []
        for vid in videos {
            guard let id = vid["id"] as? Int,
                  let videoFiles = vid["video_files"] as? [[String: Any]],
                  let previewImg = vid["image"] as? String else {
                continue
            }
            
            // Find highest resolution HD/4K file (e.g. 3840x2160 or 1920x1080)
            let sortedFiles = videoFiles.sorted { (a, b) -> Bool in
                let wA = a["width"] as? Int ?? 0
                let wB = b["width"] as? Int ?? 0
                return wA > wB
            }
            
            guard let topFile = sortedFiles.first, let link = topFile["link"] as? String else { continue }
            
            let user = vid["user"] as? [String: Any] ?? [:]
            let userName = (user["name"] as? String) ?? "Pexels Creator"
            let userUrl = user["url"] as? String
            let pageUrl = vid["url"] as? String
            let width = topFile["width"] as? Int
            let height = topFile["height"] as? Int
            let duration = vid["duration"] as? Double
            let resTag = (width ?? 0) >= 3840 ? "4K UHD" : ((width ?? 0) >= 1920 ? "1080p HD" : "720p")
            
            items.append(OnlineWallpaperItem(
                id: "pexels_vid_\(id)",
                provider: .pexels,
                title: "Cinematic Motion Loop \(id)",
                authorName: userName,
                authorUrl: userUrl,
                authorAvatarUrl: nil,
                previewUrl: previewImg,
                downloadUrl: link,
                mediaType: .video,
                resolutionTag: resTag,
                width: width,
                height: height,
                durationSeconds: duration,
                hasAudio: false,
                licenseNotice: "Pexels License (Free to use)",
                sourcePageUrl: pageUrl
            ))
        }
        return items
    }
    
    public func testConnection() async -> (success: Bool, message: String) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            return (false, "Please enter a Pexels API Key.")
        }
        
        guard let url = URL(string: "https://api.pexels.com/v1/curated?per_page=1") else {
            return (false, "Invalid endpoint URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue(trimmedKey, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 200 {
                    return (true, "Connected to Pexels API successfully! (Status: 200 OK)")
                } else if http.statusCode == 401 || http.statusCode == 403 {
                    return (false, "Authentication Failed (\(http.statusCode)): Invalid Pexels Key.")
                } else {
                    return (false, "Pexels HTTP error: \(http.statusCode)")
                }
            }
            return (false, "No HTTP response")
        } catch {
            return (false, "Connection error: \(error.localizedDescription)")
        }
    }
    
    private func getCuratedFallback(query: String, mediaType: WallpaperType?) -> [OnlineWallpaperItem] {
        let curated: [OnlineWallpaperItem] = [
            OnlineWallpaperItem(
                id: "pexels_photo_night_sky",
                provider: .pexels,
                title: "Silhouette of Pine Trees Under Milky Way",
                authorName: "Felix Mittermeier",
                authorUrl: "https://www.pexels.com/@felixmittermeier",
                previewUrl: "https://images.pexels.com/photos/956999/milky-way-starry-sky-night-sky-star-956999.jpeg?auto=compress&cs=tinysrgb&w=800",
                downloadUrl: "https://images.pexels.com/photos/956999/milky-way-starry-sky-night-sky-star-956999.jpeg",
                mediaType: .image,
                resolutionTag: "4K UHD",
                licenseNotice: "Pexels License",
                sourcePageUrl: "https://www.pexels.com/photo/silhouette-of-trees-under-starry-night-956999/"
            ),
            OnlineWallpaperItem(
                id: "pexels_vid_clouds_motion",
                provider: .pexels,
                title: "Epic Clouds Flowing Over Mountain Peak",
                authorName: "Kelly Lacy",
                authorUrl: "https://www.pexels.com/@kelly-lacy-1160368",
                previewUrl: "https://images.pexels.com/videos/3196276/free-video-3196276.jpg?auto=compress&cs=tinysrgb&w=800",
                downloadUrl: "https://www.pexels.com/video/3196276/download/",
                mediaType: .video,
                resolutionTag: "4K UHD",
                durationSeconds: 18.0,
                hasAudio: false,
                licenseNotice: "Pexels License",
                sourcePageUrl: "https://www.pexels.com/video/aerial-view-of-clouds-over-mountains-3196276/"
            )
        ]
        
        var filtered = curated
        if let mediaType = mediaType {
            filtered = filtered.filter { $0.mediaType == mediaType }
        }
        
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty || q == "all" {
            return filtered
        }
        return filtered.filter {
            $0.title.lowercased().contains(q) || $0.authorName.lowercased().contains(q)
        }
    }
}
