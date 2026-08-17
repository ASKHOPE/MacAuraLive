import SwiftUI
import AppKit

public extension View {
    /// Applies an adaptive, high-contrast macOS native card container style with subtle elevation and border
    func macaCardStyle(cornerRadius: CGFloat = 14) -> some View {
        self
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
    
    /// Applies an adaptive subtle subcard / item row background
    func macaSubcardStyle(cornerRadius: CGFloat = 8) -> some View {
        self
            .background(Color(NSColor.quaternaryLabelColor).opacity(0.15))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 0.5)
            )
    }
}
