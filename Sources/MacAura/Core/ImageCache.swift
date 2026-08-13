import AppKit

public class ImageCache {
    public static let shared = ImageCache()
    private let cache = NSCache<NSString, NSImage>()

    private init() {
        // Limit cache capacity to avoid memory bloat
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    public func image(forPath path: String) -> NSImage? {
        guard !path.isEmpty else { return nil }
        let key = path as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        if FileManager.default.fileExists(atPath: path),
           let img = NSImage(contentsOfFile: path) {
            // Rough cost estimation based on pixel dimensions
            let cost = Int(img.size.width * img.size.height * 4)
            cache.setObject(img, forKey: key, cost: cost)
            return img
        }

        return nil
    }

    public func clear() {
        cache.removeAllObjects()
    }
}
