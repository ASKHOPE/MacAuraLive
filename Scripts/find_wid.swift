import Foundation
import CoreGraphics

let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
if let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
    for window in windowList {
        if let owner = window[kCGWindowOwnerName as String] as? String, owner == "MacAuraLive",
           let wid = window[kCGWindowNumber as String] as? CGWindowID {
            print(wid)
            exit(0)
        }
    }
}
exit(1)
