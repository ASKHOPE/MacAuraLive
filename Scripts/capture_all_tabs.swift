import Foundation
import AppKit
import CoreGraphics

let docDir = "/Users/hosanna/Documents/wallpapermacs/Documentation/Screenshots"
let webDir = "/Users/hosanna/Documents/wallpapermacs/docs/screenshots"

try? FileManager.default.createDirectory(atPath: docDir, withIntermediateDirectories: true)
try? FileManager.default.createDirectory(atPath: webDir, withIntermediateDirectories: true)

func findDashboardWindowID() -> CGWindowID? {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return nil }
    
    for w in windowList {
        let name = w["kCGWindowOwnerName"] as? String ?? ""
        let title = w["kCGWindowName"] as? String ?? ""
        let bounds = w["kCGWindowBounds"] as? [String: Any] ?? [:]
        let width = bounds["Width"] as? Int ?? 0
        let height = bounds["Height"] as? Int ?? 0
        
        if name == "MacAuraLive" && width > 400 && height > 300 {
            return w["kCGWindowNumber"] as? CGWindowID
        }
    }
    return nil
}

func selectRow(index: Int) {
    let appleScript = """
    tell application "System Events"
        tell process "MacAuraLive"
            set frontmost to true
            tell outline 1 of scroll area 1 of group 1 of splitter group 1 of group 1 of window 1
                try
                    set selected of row \(index) to true
                end try
            end tell
        end tell
    end tell
    """
    var error: NSDictionary?
    if let script = NSAppleScript(source: appleScript) {
        script.executeAndReturnError(&error)
    }
}

func captureWindow(wid: CGWindowID, filename: String) {
    let docPath = "\(docDir)/\(filename)"
    let webPath = "\(webDir)/\(filename)"
    
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    task.arguments = ["-l", "\(wid)", "-o", docPath]
    try? task.run()
    task.waitUntilExit()
    
    // Copy to web docs
    try? FileManager.default.removeItem(atPath: webPath)
    try? FileManager.default.copyItem(atPath: docPath, toPath: webPath)
    
    print("📸 Saved: \(filename) (Window ID: \(wid))")
}

guard let wid = findDashboardWindowID() else {
    print("❌ MacAuraLive dashboard window not found!")
    exit(1)
}

print("🎯 Found Dashboard Window ID: \(wid)")

let tabs: [(row: Int, filename: String, name: String)] = [
    (2, "01_live_wallpapers.png", "Live Wallpapers"),
    (3, "02_static_wallpapers.png", "Static Wallpapers"),
    (6, "03_slideshow_schedule.png", "Slideshow & Schedule"),
    (7, "04_displays.png", "Displays"),
    (8, "05_lock_screen.png", "Lock Screen"),
    (12, "06_user_guide.png", "User Guide"),
    (10, "07_ai_workshop.png", "AI Workshop"),
    (13, "08_settings.png", "Settings"),
    (4, "09_marketplace.png", "Marketplace & Online")
]

for tab in tabs {
    print("Selecting [Row \(tab.row)] \(tab.name)...")
    selectRow(index: tab.row)
    Thread.sleep(forTimeInterval: 1.2)
    
    if let currentWID = findDashboardWindowID() {
        captureWindow(wid: currentWID, filename: tab.filename)
    }
}

print("\n🎉 All tab screenshots captured and updated successfully in Documentation/Screenshots and docs/screenshots!")
