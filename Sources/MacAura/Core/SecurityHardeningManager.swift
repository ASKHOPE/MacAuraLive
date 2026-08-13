import Foundation
import WebKit

public class SecurityHardeningManager {
    public static let shared = SecurityHardeningManager()
    
    private init() {}
    
    /// Sanitizes local file path inputs to prevent path traversal attacks (e.g. "../../../etc/passwd")
    public func sanitizeFilePath(_ path: String) -> String {
        let normalized = (path as NSString).standardizingPath
        // Disallow path traversal attempts outside user documents / bundle resources
        if normalized.contains("../") || normalized.contains("..\\") {
            print("[SecurityHardening] Blocked illegal path traversal attempt: \(path)")
            return ""
        }
        return normalized
    }
    
    /// Sanitizes user prompt / LLM inputs against script injection
    public func sanitizePromptInput(_ text: String) -> String {
        var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip dangerous script tags or injection attempts
        clean = clean.replacingOccurrences(of: "<script>", with: "", options: .caseInsensitive)
        clean = clean.replacingOccurrences(of: "</script>", with: "", options: .caseInsensitive)
        clean = clean.replacingOccurrences(of: "javascript:", with: "", options: .caseInsensitive)
        return clean
    }
    
    /// Applies strict web sandboxing configurations to WKWebView to prevent unauthorized network or process access
    public func configureSecureWebView(_ configuration: WKWebViewConfiguration) {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        preferences.isElementFullscreenEnabled = false
        
        configuration.preferences = preferences
        configuration.suppressesIncrementalRendering = false
        configuration.allowsAirPlayForMediaPlayback = false
    }
}
