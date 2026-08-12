import Foundation
import AppKit

public struct DisplayInfo: Identifiable, Hashable {
    public let id: CGDirectDisplayID
    public let name: String
    public let bounds: CGRect
    public let scaleFactor: CGFloat
    public let isMain: Bool
    
    public var resolutionString: String {
        let width = Int(bounds.width * scaleFactor)
        let height = Int(bounds.height * scaleFactor)
        return "\(width) x \(height) (\(Int(bounds.width))x\(Int(bounds.height)) @ \(Int(scaleFactor))x)"
    }
    
    public var resolutionCategory: String {
        let maxDim = max(bounds.width * scaleFactor, bounds.height * scaleFactor)
        if maxDim >= 3800 {
            return "4K UHD"
        } else if maxDim >= 2500 {
            return "2K / QHD"
        } else {
            return "1080p FHD"
        }
    }
}
