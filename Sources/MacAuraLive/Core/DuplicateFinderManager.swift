import Foundation
import CryptoKit
import AppKit

public struct DuplicateGroup: Identifiable {
    public let id: String
    public let original: WallpaperItem
    public let duplicates: [WallpaperItem]
    public let wastedBytes: UInt64
    public let formattedWastedSize: String
    
    public init(original: WallpaperItem, duplicates: [WallpaperItem], wastedBytes: UInt64) {
        self.id = original.id
        self.original = original
        self.duplicates = duplicates
        self.wastedBytes = wastedBytes
        self.formattedWastedSize = ByteCountFormatter.string(fromByteCount: Int64(wastedBytes), countStyle: .file)
    }
}

public class DuplicateFinderManager: ObservableObject {
    public static let shared = DuplicateFinderManager()
    
    @Published public var isScanning: Bool = false
    @Published public var duplicateGroups: [DuplicateGroup] = []
    @Published public var lastScanDate: Date? = nil
    @Published public var scanMessage: String? = nil
    
    public init() {}
    
    public var totalDuplicatesCount: Int {
        duplicateGroups.reduce(0) { $0 + $1.duplicates.count }
    }
    
    public var totalWastedBytes: UInt64 {
        duplicateGroups.reduce(0) { $0 + $1.wastedBytes }
    }
    
    public var formattedTotalWastedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalWastedBytes), countStyle: .file)
    }
    
    public func scanForDuplicates() {
        isScanning = true
        scanMessage = "Scanning wallpaper library for duplicate files..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let allWallpapers = WallpaperStorageManager.shared.wallpapers
            var hashMap: [String: [WallpaperItem]] = [:]
            var sizeMap: [UInt64: [WallpaperItem]] = [:]
            
            for item in allWallpapers {
                guard let url = WallpaperStorageManager.shared.resolveURL(for: item), url.isFileURL else { continue }
                guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                      let fileSize = attrs[.size] as? UInt64, fileSize > 0 else { continue }
                
                sizeMap[fileSize, default: []].append(item)
            }
            
            // Only hash files that share identical byte sizes
            for (_, items) in sizeMap where items.count > 1 {
                for item in items {
                    guard let url = WallpaperStorageManager.shared.resolveURL(for: item),
                          let fileData = try? Data(contentsOf: url, options: .mappedIfSafe) else { continue }
                    
                    let hash = SHA256.hash(data: fileData).compactMap { String(format: "%02x", $0) }.joined()
                    hashMap[hash, default: []].append(item)
                }
            }
            
            var groups: [DuplicateGroup] = []
            for (_, matchingItems) in hashMap where matchingItems.count > 1 {
                // Keep the first item as original (prefer built-in or oldest item)
                let original = matchingItems.first!
                let duplicates = Array(matchingItems.dropFirst())
                
                var wasted: UInt64 = 0
                for dup in duplicates {
                    if let url = WallpaperStorageManager.shared.resolveURL(for: dup),
                       let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                       let size = attrs[.size] as? UInt64 {
                        wasted += size
                    }
                }
                
                groups.append(DuplicateGroup(original: original, duplicates: duplicates, wastedBytes: wasted))
            }
            
            DispatchQueue.main.async {
                self.duplicateGroups = groups
                self.isScanning = false
                self.lastScanDate = Date()
                if groups.isEmpty {
                    self.scanMessage = "No duplicate wallpapers found! Library is 100% clean."
                } else {
                    self.scanMessage = "Found \(self.totalDuplicatesCount) duplicate(s) wasting \(self.formattedTotalWastedSize)."
                }
            }
        }
    }
    
    public func cleanDuplicates(in group: DuplicateGroup) {
        let duplicateIds = Set(group.duplicates.map { $0.id })
        WallpaperStorageManager.shared.deleteWallpapers(ids: duplicateIds)
        
        duplicateGroups.removeAll(where: { $0.id == group.id })
        StorageAnalyticsManager.shared.calculateStorage()
        scanMessage = "Cleaned duplicates for '\(group.original.title)'. Freed \(group.formattedWastedSize)."
    }
    
    public func cleanAllDuplicates() {
        var allDuplicateIds = Set<String>()
        for group in duplicateGroups {
            for dup in group.duplicates {
                allDuplicateIds.insert(dup.id)
            }
        }
        
        let freedFormatted = formattedTotalWastedSize
        let count = allDuplicateIds.count
        WallpaperStorageManager.shared.deleteWallpapers(ids: allDuplicateIds)
        duplicateGroups.removeAll()
        StorageAnalyticsManager.shared.calculateStorage()
        
        scanMessage = "Successfully cleaned \(count) duplicate file(s) and reclaimed \(freedFormatted) of disk space."
    }
}
