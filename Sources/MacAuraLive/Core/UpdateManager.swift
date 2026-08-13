import Foundation
import AppKit
import Combine

public class UpdateManager: ObservableObject {
    public static let shared = UpdateManager()
    
    public enum UpdateStatus: Equatable {
        case idle
        case checking
        case upToDate(version: String)
        case updateAvailable(version: String, releaseNotes: String, downloadUrl: String)
        case error(message: String)
    }
    
    @Published public var status: UpdateStatus = .idle
    @Published public var lastCheckedDate: Date? = nil
    
    public let currentVersion = "1.6.0"
    public let githubReleasesURL = "https://api.github.com/repos/ASKHOPE/MacAuraLive/releases/latest"
    
    private init() {}
    
    /// Queries the official GitHub repository releases API to check for software updates
    public func checkForUpdates() {
        DispatchQueue.main.async {
            self.status = .checking
        }
        
        guard let url = URL(string: githubReleasesURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("MacAuraLive-App", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.lastCheckedDate = Date()
                
                if let error = error {
                    self?.status = .error(message: "Network notice: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self?.status = .upToDate(version: self?.currentVersion ?? "1.6.0")
                    return
                }
                
                let rawTag = json["tag_name"] as? String ?? ""
                let latestVersion = rawTag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                let body = json["body"] as? String ?? "No release notes available."
                
                // Find DMG download URL in assets
                var downloadUrl = json["html_url"] as? String ?? "https://github.com/ASKHOPE/MacAuraLive/releases"
                if let assets = json["assets"] as? [[String: Any]] {
                    if let dmgAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }),
                       let browserUrl = dmgAsset["browser_download_url"] as? String {
                        downloadUrl = browserUrl
                    }
                }
                
                if self?.isVersion(latestVersion, newerThan: self?.currentVersion ?? "1.6.0") == true {
                    self?.status = .updateAvailable(version: latestVersion, releaseNotes: body, downloadUrl: downloadUrl)
                } else {
                    self?.status = .upToDate(version: self?.currentVersion ?? "1.6.0")
                }
            }
        }.resume()
    }
    
    /// Helper to open the download URL in the user's default browser
    public func openDownloadPage(url: String) {
        if let targetURL = URL(string: url) {
            NSWorkspace.shared.open(targetURL)
        }
    }
    
    private func isVersion(_ v1: String, newerThan v2: String) -> Bool {
        return v1.compare(v2, options: .numeric) == .orderedDescending
    }
}
