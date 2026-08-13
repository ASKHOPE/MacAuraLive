import Foundation

public class PixabayPlugin: OnlineWallpaperPlugin {
    public let provider: WallpaperSourceProvider = .pixabay
    
    public var apiKey: String {
        get { AppSettings.shared.pixabayApiKey }
        set { AppSettings.shared.pixabayApiKey = newValue }
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
            
            // If mediaType is nil or .image, fetch images
            if mediaType == nil || mediaType == .image {
                let photos = try await fetchPhotosFromPixabay(key: trimmedKey, query: query, page: page, perPage: perPage)
                results.append(contentsOf: photos)
            }
            
            // If mediaType is nil or .video, fetch videos
            if mediaType == nil || mediaType == .video {
                let videos = try await fetchVideosFromPixabay(key: trimmedKey, query: query, page: page, perPage: perPage)
                results.append(contentsOf: videos)
            }
            
            return results
        } else {
            return getCuratedFallback(query: query, mediaType: mediaType)
        }
    }
    
    private func fetchPhotosFromPixabay(
        key: String,
        query: String,
        page: Int,
        perPage: Int
    ) async throws -> [OnlineWallpaperItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var components = URLComponents(string: "https://pixabay.com/api/")!
        var queryItems = [
            URLQueryItem(name: "key", value: key),
            URLQueryItem(name: "image_type", value: "photo"),
            URLQueryItem(name: "orientation", value: "horizontal"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "safesearch", value: "true"),
            URLQueryItem(name: "min_width", value: "1920")
        ]
        if !cleanQuery.isEmpty && cleanQuery.lowercased() != "all" {
            queryItems.append(URLQueryItem(name: "q", value: cleanQuery))
        } else {
            queryItems.append(URLQueryItem(name: "editors_choice", value: "true"))
        }
        components.queryItems = queryItems
        
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hits = json["hits"] as? [[String: Any]] else {
            return []
        }
        
        var items: [OnlineWallpaperItem] = []
        for hit in hits {
            guard let id = hit["id"] as? Int,
                  let webformatURL = hit["webformatURL"] as? String,
                  let largeImageURL = hit["largeImageURL"] as? String else {
                continue
            }
            
            let tags = (hit["tags"] as? String) ?? "Pixabay Wallpaper \(id)"
            let user = (hit["user"] as? String) ?? "Pixabay Creator"
            let userImageURL = hit["userImageURL"] as? String
            let pageURL = hit["pageURL"] as? String
            let imageWidth = hit["imageWidth"] as? Int
            let imageHeight = hit["imageHeight"] as? Int
            let resTag = (imageWidth ?? 0) >= 3840 ? "4K UHD" : "1080p HD"
            
            items.append(OnlineWallpaperItem(
                id: "pixabay_img_\(id)",
                provider: .pixabay,
                title: tags.capitalized,
                authorName: user,
                authorUrl: "https://pixabay.com/users/\(user)-\(hit["user_id"] ?? "")/",
                authorAvatarUrl: userImageURL,
                previewUrl: webformatURL,
                downloadUrl: largeImageURL,
                mediaType: .image,
                resolutionTag: resTag,
                width: imageWidth,
                height: imageHeight,
                durationSeconds: nil,
                hasAudio: false,
                licenseNotice: "Pixabay Content License (Free to use)",
                sourcePageUrl: pageURL
            ))
        }
        return items
    }
    
    private func fetchVideosFromPixabay(
        key: String,
        query: String,
        page: Int,
        perPage: Int
    ) async throws -> [OnlineWallpaperItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var components = URLComponents(string: "https://pixabay.com/api/videos/")!
        var queryItems = [
            URLQueryItem(name: "key", value: key),
            URLQueryItem(name: "video_type", value: "all"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "safesearch", value: "true")
        ]
        if !cleanQuery.isEmpty && cleanQuery.lowercased() != "all" {
            queryItems.append(URLQueryItem(name: "q", value: cleanQuery))
        } else {
            queryItems.append(URLQueryItem(name: "editors_choice", value: "true"))
        }
        components.queryItems = queryItems
        
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hits = json["hits"] as? [[String: Any]] else {
            return []
        }
        
        var items: [OnlineWallpaperItem] = []
        for hit in hits {
            guard let id = hit["id"] as? Int,
                  let videos = hit["videos"] as? [String: Any] else {
                continue
            }
            
            // Pick largest available video stream: large -> medium -> small
            let videoData = (videos["large"] as? [String: Any]) ?? (videos["medium"] as? [String: Any]) ?? (videos["small"] as? [String: Any])
            guard let downloadURL = videoData?["url"] as? String else { continue }
            
            let previewVideo = (videos["tiny"] as? [String: Any]) ?? (videos["small"] as? [String: Any])
            let previewThumb = (previewVideo?["thumbnail"] as? String) ?? (videoData?["thumbnail"] as? String) ?? "https://i.vimeocdn.com/video/\(hit["picture_id"] ?? "")_640x360.jpg"
            
            let tags = (hit["tags"] as? String) ?? "Pixabay Video \(id)"
            let user = (hit["user"] as? String) ?? "Pixabay Creator"
            let userImageURL = hit["userImageURL"] as? String
            let pageURL = hit["pageURL"] as? String
            let width = videoData?["width"] as? Int
            let height = videoData?["height"] as? Int
            let duration = hit["duration"] as? Double
            let resTag = (width ?? 0) >= 3840 ? "4K UHD" : ((width ?? 0) >= 1920 ? "1080p HD" : "720p")
            
            items.append(OnlineWallpaperItem(
                id: "pixabay_vid_\(id)",
                provider: .pixabay,
                title: tags.capitalized,
                authorName: user,
                authorUrl: "https://pixabay.com/users/\(user)-\(hit["user_id"] ?? "")/",
                authorAvatarUrl: userImageURL,
                previewUrl: previewThumb,
                downloadUrl: downloadURL,
                mediaType: .video,
                resolutionTag: resTag,
                width: width,
                height: height,
                durationSeconds: duration,
                hasAudio: true,
                licenseNotice: "Pixabay Content License (Free for commercial use)",
                sourcePageUrl: pageURL
            ))
        }
        return items
    }
    
    public func testConnection() async -> (success: Bool, message: String) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            return (false, "Please enter a Pixabay API Key.")
        }
        
        guard let url = URL(string: "https://pixabay.com/api/?key=\(trimmedKey)&per_page=3") else {
            return (false, "Invalid endpoint URL")
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 200 {
                    return (true, "Connected to Pixabay API successfully! (Status: 200 OK)")
                } else if http.statusCode == 400 || http.statusCode == 401 || http.statusCode == 403 {
                    return (false, "Authentication Failed (\(http.statusCode)): Invalid Pixabay Key.")
                } else {
                    return (false, "Pixabay HTTP error: \(http.statusCode)")
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
                id: "pixabay_vid_270983",
                provider: .pixabay,
                title: "Abstract Blue Motion Waves Loop",
                authorName: "Shivaay Singh",
                authorUrl: "https://pixabay.com/users/mrbones03-33188032/",
                previewUrl: "https://cdn.pixabay.com/video/2023/10/24/186357-877840130_tiny.jpg",
                downloadUrl: "https://cdn.pixabay.com/video/2023/10/24/186357-877840130_large.mp4",
                mediaType: .video,
                resolutionTag: "4K UHD",
                durationSeconds: 15.0,
                hasAudio: true,
                licenseNotice: "Pixabay Content License",
                sourcePageUrl: "https://pixabay.com/videos/id-270983/"
            ),
            OnlineWallpaperItem(
                id: "pixabay_vid_waterfall",
                provider: .pixabay,
                title: "Cinematic Waterfall & Mist River",
                authorName: "NatureCinematics",
                authorUrl: "https://pixabay.com/service/terms/",
                previewUrl: "https://cdn.pixabay.com/video/2020/07/28/45763-444453000_tiny.jpg",
                downloadUrl: "https://cdn.pixabay.com/video/2020/07/28/45763-444453000_large.mp4",
                mediaType: .video,
                resolutionTag: "4K UHD",
                durationSeconds: 20.0,
                hasAudio: false,
                licenseNotice: "Pixabay Content License",
                sourcePageUrl: "https://pixabay.com/videos/waterfall-nature-45763/"
            ),
            OnlineWallpaperItem(
                id: "pixabay_img_aurora_night",
                provider: .pixabay,
                title: "Northern Lights Over Arctic Mountains",
                authorName: "ArcticVision",
                authorUrl: "https://pixabay.com/service/terms/",
                previewUrl: "https://cdn.pixabay.com/photo/2016/11/29/05/45/astronomy-1867616_640.jpg",
                downloadUrl: "https://cdn.pixabay.com/photo/2016/11/29/05/45/astronomy-1867616_1280.jpg",
                mediaType: .image,
                resolutionTag: "4K UHD",
                licenseNotice: "Pixabay Content License",
                sourcePageUrl: "https://pixabay.com/photos/astronomy-aurora-borealis-1867616/"
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
