import Foundation
import AppKit
import CoreGraphics

let outDir = "/Users/hosanna/Documents/wallpapermacs/Documentation/Screenshots"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

print("🔍 Searching for running MacAuraLive window...")

func captureWindow(filename: String) {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return }
    
    for window in windowList {
        if let owner = window[kCGWindowOwnerName as String] as? String, owner == "MacAuraLive",
           let wid = window[kCGWindowNumber as String] as? CGWindowID {
            print("Found MacAuraLive Window ID: \(wid)")
            if let image = CGWindowListCreateImage(.null, .optionIncludingWindow, wid, [.boundsIgnoreFraming, .bestResolution]) {
                let bitmap = NSBitmapImageRep(cgImage: image)
                if let pngData = bitmap.representation(using: .png, properties: [:]) {
                    let path = "\(outDir)/\(filename)"
                    try? pngData.write(to: URL(fileURLWithPath: path))
                    print("✅ Saved screenshot to \(path)")
                    return
                }
            }
        }
    }
}

captureWindow(filename: "app_preview.png")
