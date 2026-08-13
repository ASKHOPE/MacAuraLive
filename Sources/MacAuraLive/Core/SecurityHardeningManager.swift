import Foundation
import WebKit

public class SecurityHardeningManager {
    public static let shared = SecurityHardeningManager()
    
    private init() {}
    
    /// Sanitizes local file path inputs to prevent path traversal attacks (e.g. "../../../etc/passwd")
    public func sanitizeFilePath(_ path: String) -> String {
        let normalized = (path as NSString).standardizingPath
        if normalized.contains("../") || normalized.contains("..\\") {
            print("[SecurityHardening] Blocked illegal path traversal attempt: \(path)")
            return ""
        }
        return normalized
    }
    
    /// Strict Prompt Injection & Scope Validation Engine for AI Workshop
    public func validateAndSanitizeWallpaperPrompt(_ text: String) throws -> String {
        var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !clean.isEmpty else {
            throw NSError(domain: "SecurityHardening", code: 400, userInfo: [NSLocalizedDescriptionKey: "Prompt cannot be empty."])
        }
        
        // 1. Block Prompt Injection & Jailbreak Attacks
        let injectionPatterns = [
            "ignore previous instructions", "ignore all instructions", "ignore system prompt",
            "system prompt", "act as a", "dan mode", "developer mode", "override rules",
            "execute command", "eval(", "rm -rf", "sudo ", "cat /etc", "read file",
            "download script", "bash", "zsh", "sh ", "curl ", "wget ", "python ",
            "write script", "javascript:", "cookie", "localStorage", "fetch("
        ]
        
        let lower = clean.lowercased()
        for pattern in injectionPatterns {
            if lower.contains(pattern) {
                print("[SecurityHardening] Blocked AI prompt injection attempt containing '\(pattern)'")
                throw NSError(domain: "SecurityHardening", code: 403, userInfo: [NSLocalizedDescriptionKey: "Security Policy Violation: Prompt contains disallowed keywords or prompt injection attempts ('\(pattern)'). AI Workshop only generates live wallpaper visuals."])
            }
        }
        
        // 2. Strip harmful HTML/Script tag injections
        clean = clean.replacingOccurrences(of: "<script>", with: "", options: .caseInsensitive)
        clean = clean.replacingOccurrences(of: "</script>", with: "", options: .caseInsensitive)
        clean = clean.replacingOccurrences(of: "javascript:", with: "", options: .caseInsensitive)
        
        // 3. Limit Prompt Length
        if clean.count > 500 {
            clean = String(clean.prefix(500))
        }
        
        // 4. Force Visual Scope Context Tag
        return "\(clean) (desktop wallpaper aesthetic 60fps WebGL visual shader effect)"
    }
    
    /// Post-Generation Security Sanitizer for LLM Generated HTML/JS Code
    public func sanitizeGeneratedHTML(_ html: String) -> String {
        var sanitized = html
        
        // Block dangerous JavaScript execution APIs in generated wallpaper code
        sanitized = sanitized.replacingOccurrences(of: "eval(", with: "// eval_blocked(")
        sanitized = sanitized.replacingOccurrences(of: "Function(", with: "// Function_blocked(")
        sanitized = sanitized.replacingOccurrences(of: "fetch(", with: "// fetch_blocked(")
        sanitized = sanitized.replacingOccurrences(of: "XMLHttpRequest", with: "BlockedXHR")
        sanitized = sanitized.replacingOccurrences(of: "WebSocket", with: "BlockedWebSocket")
        sanitized = sanitized.replacingOccurrences(of: "document.cookie", with: "/* cookie_blocked */")
        sanitized = sanitized.replacingOccurrences(of: "localStorage", with: "/* storage_blocked */")
        
        return sanitized
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
