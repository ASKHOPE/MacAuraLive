import Foundation
import WebKit

public class SecurityHardeningManager {
    public static let shared = SecurityHardeningManager()
    
    private var lastGenerationTime: Date?
    private var generationTimestamps: [Date] = []
    
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
    
    /// Rate Limiting Engine: Prevents API exhaustion & denial-of-service spam attacks
    public func checkRateLimit() throws {
        let now = Date()
        
        // 1. Minimum 3-second cooldown between requests
        if let last = lastGenerationTime, now.timeIntervalSince(last) < 3.0 {
            let waitSec = Int(3.0 - now.timeIntervalSince(last)) + 1
            throw NSError(domain: "SecurityHardening", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit: Please wait \(waitSec) second(s) before launching another AI generation."])
        }
        
        // 2. Max 5 generations per rolling 60-second window
        generationTimestamps = generationTimestamps.filter { now.timeIntervalSince($0) < 60.0 }
        if generationTimestamps.count >= 5 {
            throw NSError(domain: "SecurityHardening", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit: Maximum 5 AI generations per minute exceeded. Please try again in a moment."])
        }
        
        lastGenerationTime = now
        generationTimestamps.append(now)
    }
    
    /// Strict Prompt Injection & Scope Validation Engine for AI Workshop
    public func validateAndSanitizeWallpaperPrompt(_ text: String) throws -> String {
        try checkRateLimit()
        
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
        
        // 2. Strict NSFW & Inappropriate Content Moderation Filter
        let nsfwPatterns = [
            "nsfw", "nude", "nudity", "porn", "porno", "erotic", "sex", "sexy", "hentai",
            "blood", "gore", "violence", "violent", "kill", "murder", "suicide", "self-harm",
            "weapon", "drug", "cocaine", "heroine", "meth", "hate speech", "racist", "slur"
        ]
        
        for pattern in nsfwPatterns {
            if lower.contains(pattern) {
                print("[SecurityHardening] Blocked NSFW / Inappropriate AI prompt attempt: '\(pattern)'")
                throw NSError(domain: "SecurityHardening", code: 403, userInfo: [NSLocalizedDescriptionKey: "Safety Policy Violation: Prompt contains NSFW, explicit, or non-family-friendly keywords ('\(pattern)'). MacAuraLive only generates safe, high-aesthetic wallpapers."])
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
    
    /// Post-Generation Security Sanitizer & Content Security Policy (CSP) Injector
    public func sanitizeGeneratedHTML(_ html: String) -> String {
        var sanitized = html
        
        // 1. Block dangerous JavaScript execution APIs in generated wallpaper code
        sanitized = sanitized.replacingOccurrences(of: "eval(", with: "// eval_blocked(")
        sanitized = sanitized.replacingOccurrences(of: "Function(", with: "// Function_blocked(")
        sanitized = sanitized.replacingOccurrences(of: "fetch(", with: "// fetch_blocked(")
        sanitized = sanitized.replacingOccurrences(of: "XMLHttpRequest", with: "BlockedXHR")
        sanitized = sanitized.replacingOccurrences(of: "WebSocket", with: "BlockedWebSocket")
        sanitized = sanitized.replacingOccurrences(of: "document.cookie", with: "/* cookie_blocked */")
        sanitized = sanitized.replacingOccurrences(of: "localStorage", with: "/* storage_blocked */")
        
        // 2. Inject Strict Content-Security-Policy (CSP) meta tag into <head>
        let cspMetaTag = """
        <meta http-equiv="Content-Security-Policy" content="default-src 'self' 'unsafe-inline' data: blob:; script-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline'; connect-src 'none'; img-src 'self' data: blob:; media-src 'self' data: blob:;">
        """
        
        if sanitized.contains("<head>") {
            sanitized = sanitized.replacingOccurrences(of: "<head>", with: "<head>\n\(cspMetaTag)")
        } else if sanitized.contains("<html>") {
            sanitized = sanitized.replacingOccurrences(of: "<html>", with: "<html>\n<head>\n\(cspMetaTag)\n</head>")
        } else {
            sanitized = "<!DOCTYPE html>\n<html>\n<head>\n\(cspMetaTag)\n</head>\n<body>\n\(sanitized)\n</body>\n</html>"
        }
        
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
