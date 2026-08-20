import SwiftUI
import AppKit

public struct MacaThemeTokens {
    // OS Classic Palette (Derived directly from MacAura Vintage Chassis App Icon)
    public static var isDark: Bool {
        if AppSettings.shared.appTheme == "dark" { return true }
        if AppSettings.shared.appTheme == "light" { return false }
        if AppSettings.shared.appTheme == "classic" {
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
    
    // Canvas Background (Vintage Cream vs Deep CRT Charcoal)
    public static var classicCanvas: Color {
        isDark ? Color(red: 0.086, green: 0.082, blue: 0.075) : Color(red: 0.925, green: 0.902, blue: 0.855) // #ECE6DA
    }
    
    // Sidebar Background (Vintage Chassis Almond vs Dark Bezel)
    public static var classicSidebar: Color {
        isDark ? Color(red: 0.110, green: 0.105, blue: 0.095) : Color(red: 0.885, green: 0.860, blue: 0.810) // #E2DCCF
    }
    
    // Card Background (Vintage Chassis Beige - NEVER pure white)
    public static var classicCardBg: Color {
        isDark ? Color(red: 0.145, green: 0.138, blue: 0.125) : Color(red: 0.865, green: 0.840, blue: 0.785) // #DDD6C8
    }
    
    // Subcard / Chip Background
    public static var classicSubcardBg: Color {
        isDark ? Color(red: 0.180, green: 0.170, blue: 0.155) : Color(red: 0.815, green: 0.790, blue: 0.735) // #D0C9BB
    }
    
    // Tactile Hardware Border
    public static var classicBorder: Color {
        isDark ? Color(red: 0.290, green: 0.275, blue: 0.250) : Color(red: 0.680, green: 0.650, blue: 0.590) // #ADA696
    }
    
    // Olive / Bronze Accent (from App Logo Buttons)
    public static var classicOlive: Color {
        isDark ? Color(red: 0.460, green: 0.430, blue: 0.340) : Color(red: 0.360, green: 0.335, blue: 0.260) // #5C5542
    }
    
    // Dark CRT Tag
    public static var classicDarkTag: Color {
        isDark ? Color(red: 0.065, green: 0.060, blue: 0.055) : Color(red: 0.150, green: 0.140, blue: 0.125)
    }
    
    // Primary Monospaced Text
    public static var classicTextDark: Color {
        isDark ? Color(red: 0.940, green: 0.930, blue: 0.905) : Color(red: 0.115, green: 0.110, blue: 0.100) // #1D1C19
    }
    
    // Muted Monospaced Text
    public static var classicTextMuted: Color {
        isDark ? Color(red: 0.680, green: 0.660, blue: 0.615) : Color(red: 0.400, green: 0.385, blue: 0.350) // #666259
    }
    
    // Button Raised Chassis
    public static var classicButtonBg: Color {
        isDark ? Color(red: 0.200, green: 0.190, blue: 0.175) : Color(red: 0.840, green: 0.815, blue: 0.760) // #D6D0C2
    }
}

// MARK: - Reusable Themed Card Modifiers

public extension View {
    /// Applies an adaptive card container style with crisp 2pt corner radius in classic mode
    func macaCardStyle(cornerRadius: CGFloat = 14) -> some View {
        let isClassic = AppSettings.shared.appTheme == "classic"
        let isDark = AppSettings.shared.appTheme == "dark" || (AppSettings.shared.appTheme != "light" && MacaThemeTokens.isDark)
        let radius: CGFloat = isClassic ? 2 : cornerRadius
        
        return self
            .background(
                isClassic
                    ? MacaThemeTokens.classicCardBg
                    : (isDark ? Color(red: 0.14, green: 0.14, blue: 0.16).opacity(0.85) : Color(NSColor.controlBackgroundColor))
            )
            .cornerRadius(radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        isClassic
                            ? MacaThemeTokens.classicBorder
                            : (isDark ? Color.white.opacity(0.12) : Color(NSColor.separatorColor)),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isDark ? Color.black.opacity(0.3) : (isClassic ? Color.black.opacity(0.08) : Color.black.opacity(0.04)),
                radius: isClassic ? 1 : 4,
                x: isClassic ? 1 : 0,
                y: isClassic ? 1 : 1
            )
    }
    
    /// Applies an adaptive subtle subcard / item row background with crisp 2pt corner radius in classic mode
    func macaSubcardStyle(cornerRadius: CGFloat = 8) -> some View {
        let isClassic = AppSettings.shared.appTheme == "classic"
        let isDark = AppSettings.shared.appTheme == "dark" || (AppSettings.shared.appTheme != "light" && MacaThemeTokens.isDark)
        let radius: CGFloat = isClassic ? 2 : cornerRadius
        
        return self
            .background(
                isClassic
                    ? MacaThemeTokens.classicSubcardBg
                    : (isDark ? Color.white.opacity(0.06) : Color(NSColor.quaternaryLabelColor).opacity(0.15))
            )
            .cornerRadius(radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        isClassic
                            ? MacaThemeTokens.classicBorder.opacity(0.75)
                            : (isDark ? Color.white.opacity(0.08) : Color(NSColor.separatorColor).opacity(0.6)),
                        lineWidth: 0.8
                    )
            )
    }
    
    /// Applies adaptive corner radius: 2pt in classic, customizable in modern
    func macaItemRadius(_ modern: CGFloat = 8) -> some View {
        self.cornerRadius(AppSettings.shared.appTheme == "classic" ? 2 : modern)
    }
}

// MARK: - Reusable Retro & Modern Button Styles

public enum MacaButtonStyleType {
    case primary      // Olive in classic, accent/blue in modern
    case secondary    // Beveled raised almond in classic, bordered in modern
    case destructive  // Crimson in classic & modern
    case ghost        // Clean wireframe
}

public struct MacaThemeButtonStyle: ButtonStyle {
    public let style: MacaButtonStyleType
    public let controlSize: ControlSize
    
    public init(_ style: MacaButtonStyleType = .secondary, size: ControlSize = .regular) {
        self.style = style
        self.controlSize = size
    }
    
    private func computeBackground(isClassic: Bool, isPressed: Bool) -> Color {
        if isClassic {
            switch style {
            case .primary:
                return isPressed ? MacaThemeTokens.classicOlive.opacity(0.8) : MacaThemeTokens.classicOlive
            case .secondary:
                return isPressed ? MacaThemeTokens.classicSubcardBg : MacaThemeTokens.classicButtonBg
            case .destructive:
                return isPressed ? Color.red.opacity(0.8) : Color.red
            case .ghost:
                return Color.clear
            }
        } else {
            switch style {
            case .primary:
                return Color.accentColor.opacity(isPressed ? 0.8 : 1.0)
            case .secondary:
                return Color(NSColor.controlBackgroundColor).opacity(isPressed ? 0.6 : 1.0)
            case .destructive:
                return Color.red.opacity(isPressed ? 0.8 : 1.0)
            case .ghost:
                return Color.clear
            }
        }
    }
    
    private func computeTextColor(isClassic: Bool) -> Color {
        if isClassic {
            switch style {
            case .primary, .destructive:
                return Color.white
            case .secondary, .ghost:
                return MacaThemeTokens.classicTextDark
            }
        } else {
            switch style {
            case .primary, .destructive:
                return Color.white
            case .secondary, .ghost:
                return Color.primary
            }
        }
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        let isClassic = AppSettings.shared.appTheme == "classic"
        let isPressed = configuration.isPressed
        
        let verticalPad: CGFloat = controlSize == .small ? 4 : (controlSize == .large ? 10 : 6)
        let horizontalPad: CGFloat = controlSize == .small ? 8 : (controlSize == .large ? 16 : 12)
        let fontSize: CGFloat = controlSize == .small ? 11 : (controlSize == .large ? 14 : 12.5)
        
        return configuration.label
            .font(.system(size: fontSize, weight: .bold, design: isClassic ? .monospaced : .default))
            .padding(.vertical, verticalPad)
            .padding(.horizontal, horizontalPad)
            .background(computeBackground(isClassic: isClassic, isPressed: isPressed))
            .foregroundColor(computeTextColor(isClassic: isClassic))
            .cornerRadius(isClassic ? 2 : 8)
            .overlay(
                RoundedRectangle(cornerRadius: isClassic ? 2 : 8)
                    .stroke(
                        isClassic ? (style == .primary ? MacaThemeTokens.classicOlive : MacaThemeTokens.classicBorder) : (style == .primary ? Color.clear : Color(NSColor.separatorColor)),
                        lineWidth: isClassic ? 1 : 1
                    )
            )
            .shadow(
                color: isClassic && style != .ghost ? Color.black.opacity(isPressed ? 0.02 : 0.08) : Color.clear,
                radius: isPressed ? 0.5 : 1.0,
                x: 0,
                y: isPressed ? 0.5 : 1.0
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

public extension View {
    func macaButtonStyle(_ style: MacaButtonStyleType = .secondary, size: ControlSize = .regular) -> some View {
        self.buttonStyle(MacaThemeButtonStyle(style, size: size))
    }
}

// MARK: - Reusable Retro Mechanical Toggle

public struct MacaRetroToggle: View {
    @Binding var isOn: Bool
    var label: String
    
    public init(_ label: String = "", isOn: Binding<Bool>) {
        self._isOn = isOn
        self.label = label
    }
    
    public var body: some View {
        let isClassic = AppSettings.shared.appTheme == "classic"
        
        if isClassic {
            Button(action: { isOn.toggle() }) {
                HStack(spacing: 8) {
                    if !label.isEmpty {
                        Text(label)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(MacaThemeTokens.classicTextDark)
                    }
                    
                    // Hardware Rocker Switch Pill
                    HStack(spacing: 0) {
                        Text("ON")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(isOn ? MacaThemeTokens.classicOlive : Color.clear)
                            .foregroundColor(isOn ? .white : MacaThemeTokens.classicTextMuted)
                        
                        Text("OFF")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(!isOn ? Color(red: 0.30, green: 0.28, blue: 0.26) : Color.clear)
                            .foregroundColor(!isOn ? .white : MacaThemeTokens.classicTextMuted)
                    }
                    .background(MacaThemeTokens.classicSubcardBg)
                    .cornerRadius(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(MacaThemeTokens.classicBorder, lineWidth: 1)
                    )
                }
            }
            .buttonStyle(.plain)
        } else {
            Toggle(label, isOn: $isOn)
        }
    }
}

// MARK: - MacaRetroSlider Component

public struct MacaRetroSlider: View {
    @Binding public var value: Double
    public let range: ClosedRange<Double>
    public let step: Double?
    public let accentColor: Color?
    public let showTicks: Bool
    public let tickCount: Int
    public let onEditingChanged: ((Bool) -> Void)?
    
    @State private var isDragging: Bool = false
    
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0.0...1.0,
        step: Double? = nil,
        accentColor: Color? = nil,
        showTicks: Bool = false,
        tickCount: Int = 8,
        onEditingChanged: ((Bool) -> Void)? = nil
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.accentColor = accentColor
        self.showTicks = showTicks
        self.tickCount = max(2, tickCount)
        self.onEditingChanged = onEditingChanged
    }
    
    public var body: some View {
        let isClassic = AppSettings.shared.appTheme == "classic"
        
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let thumbWidth: CGFloat = isClassic ? 14 : 16
            let thumbHeight: CGFloat = isClassic ? 18 : 16
            let trackHeight: CGFloat = isClassic ? 6 : 5
            
            // Normalize value
            let clamped = min(max(value, range.lowerBound), range.upperBound)
            let span = range.upperBound - range.lowerBound
            let fraction = span > 0 ? (clamped - range.lowerBound) / span : 0.0
            let effectiveWidth = max(0, totalWidth - thumbWidth)
            let thumbOffset = CGFloat(fraction) * effectiveWidth
            
            ZStack(alignment: .leading) {
                // Ticks if enabled in Classic Mode
                if showTicks && isClassic {
                    HStack {
                        ForEach(0..<tickCount, id: \.self) { i in
                            Rectangle()
                                .fill(Color(red: 0.58, green: 0.55, blue: 0.50))
                                .frame(width: 1.2, height: 3.5)
                            if i < tickCount - 1 {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, thumbWidth / 2)
                    .offset(y: 8)
                }
                
                // Track Slot / Groove
                ZStack(alignment: .leading) {
                    // Track Groove Inset Background
                    RoundedRectangle(cornerRadius: isClassic ? 1.5 : 3)
                        .fill(isClassic ? Color(red: 0.76, green: 0.73, blue: 0.67) : Color.gray.opacity(0.25))
                        .frame(height: trackHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: isClassic ? 1.5 : 3)
                                .stroke(isClassic ? Color(red: 0.48, green: 0.45, blue: 0.40) : Color.clear, lineWidth: isClassic ? 1 : 0)
                        )
                    
                    // Track Active Fill
                    let fillWidth = max(0, thumbOffset + thumbWidth / 2)
                    RoundedRectangle(cornerRadius: isClassic ? 1.5 : 3)
                        .fill(accentColor ?? (isClassic ? MacaThemeTokens.classicOlive : Color.accentColor))
                        .frame(width: min(fillWidth, totalWidth), height: trackHeight)
                }
                .frame(width: totalWidth, height: trackHeight)
                
                // Slider Thumb Knob
                ZStack {
                    if isClassic {
                        // 3D Beveled Chassis Knob
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color(red: 0.94, green: 0.92, blue: 0.88))
                            .frame(width: thumbWidth, height: thumbHeight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 1.5)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.9),
                                                Color(red: 0.38, green: 0.36, blue: 0.32)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.2
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0.5, y: 1)
                        
                        // Center Grip Ridges
                        VStack(spacing: 2) {
                            Rectangle().fill(Color(red: 0.45, green: 0.42, blue: 0.38)).frame(width: 6, height: 1)
                            Rectangle().fill(Color(red: 0.45, green: 0.42, blue: 0.38)).frame(width: 6, height: 1)
                            Rectangle().fill(Color(red: 0.45, green: 0.42, blue: 0.38)).frame(width: 6, height: 1)
                        }
                    } else {
                        // Modern Circular Thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: thumbWidth, height: thumbHeight)
                            .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.25), lineWidth: 0.5)
                            )
                    }
                }
                .offset(x: thumbOffset)
            }
            .frame(width: totalWidth, height: max(thumbHeight, 20))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged?(true)
                        }
                        
                        let locationX = gesture.location.x
                        let relativeX = max(0, min(locationX - thumbWidth / 2, effectiveWidth))
                        let pct = effectiveWidth > 0 ? Double(relativeX / effectiveWidth) : 0.0
                        var newValue = range.lowerBound + pct * (range.upperBound - range.lowerBound)
                        
                        if let step = step, step > 0 {
                            newValue = (newValue / step).rounded() * step
                        }
                        
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged?(false)
                    }
            )
        }
        .frame(height: 20)
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
