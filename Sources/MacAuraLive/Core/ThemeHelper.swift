import SwiftUI
import AppKit

public struct MacaThemeTokens {
    // OS Classic / Retro Studio Warm Palette
    public static let classicCanvas = Color(red: 0.957, green: 0.945, blue: 0.918)      // #F4F1EA
    public static let classicSidebar = Color(red: 0.937, green: 0.925, blue: 0.902)     // #EFECE6
    public static let classicCardBg = Color(red: 0.985, green: 0.980, blue: 0.965)      // #FAF9F6
    public static let classicBorder = Color(red: 0.820, green: 0.795, blue: 0.755)      // #D1CBBF
    public static let classicOlive = Color(red: 0.360, green: 0.340, blue: 0.270)       // #5C5744
    public static let classicDarkTag = Color(red: 0.170, green: 0.160, blue: 0.135)     // #2B2922
    public static let classicTextDark = Color(red: 0.120, green: 0.115, blue: 0.105)    // #1F1E1B
    public static let classicTextMuted = Color(red: 0.440, green: 0.425, blue: 0.390)   // #706D63
    public static let classicPillBorder = Color(red: 0.750, green: 0.725, blue: 0.680)  // #C0BAAD
}

public extension View {
    /// Applies an adaptive, high-contrast macOS native card container style with subtle elevation and border
    func macaCardStyle(cornerRadius: CGFloat = 14) -> some View {
        let isClassic = AppSettings.shared.appTheme == "classic"
        return self
            .background(isClassic ? MacaThemeTokens.classicCardBg : Color(NSColor.controlBackgroundColor))
            .cornerRadius(isClassic ? 8 : cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: isClassic ? 8 : cornerRadius)
                    .stroke(isClassic ? MacaThemeTokens.classicBorder : Color(NSColor.separatorColor), lineWidth: 1)
            )
            .shadow(color: isClassic ? Color.black.opacity(0.08) : Color.black.opacity(0.04), radius: isClassic ? 3 : 4, x: isClassic ? 2 : 0, y: isClassic ? 2 : 1)
    }
    
    /// Applies an adaptive subtle subcard / item row background
    func macaSubcardStyle(cornerRadius: CGFloat = 8) -> some View {
        let isClassic = AppSettings.shared.appTheme == "classic"
        return self
            .background(isClassic ? MacaThemeTokens.classicSidebar : Color(NSColor.quaternaryLabelColor).opacity(0.15))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isClassic ? MacaThemeTokens.classicBorder.opacity(0.6) : Color(NSColor.separatorColor).opacity(0.6), lineWidth: 0.5)
            )
    }
}

public extension Color {
    init?(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        if cString.count != 6 {
            return nil
        }
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        self.init(
            .sRGB,
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0,
            opacity: 1.0
        )
    }
    
    func toHexString() -> String? {
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int(nsColor.redComponent * 255.0)
        let g = Int(nsColor.greenComponent * 255.0)
        let b = Int(nsColor.blueComponent * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
