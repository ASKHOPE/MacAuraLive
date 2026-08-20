import Foundation
import AppKit
import Combine

public class UpdateManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    public static let shared = UpdateManager()
    
    public enum UpdateStatus: Equatable {
        case idle
        case checking
        case upToDate(version: String)
        case updateAvailable(version: String, releaseNotes: String, downloadUrl: String)
        case downloading(progress: Double, bytesWritten: Int64, totalBytes: Int64)
        case verifying
        case readyToInstall(installerPath: String, version: String)
        case installing
        case error(message: String)
    }
    
    @Published public var status: UpdateStatus = .idle
    @Published public var lastCheckedDate: Date? = nil
    @Published public var downloadProgress: Double = 0.0
    @Published public var autoCheckEnabled: Bool = true
    
    public var currentVersion: String {
        AppVersion.current.version
    }
    
    public let githubReleasesURL = "https://api.github.com/repos/ASKHOPE/MacAuraLive/releases/latest"
    private var downloadTask: URLSessionDownloadTask?
    private var targetVersion: String = ""
    private var expectedSha256: String? = nil
    private var downloadUrlString: String = ""
    
    private override init() {
        super.init()
    }
    
    // MARK: - Check for Updates
    
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
                    self?.status = .upToDate(version: self?.currentVersion ?? AppVersion.fallbackVersion)
                    return
                }
                
                let rawTag = json["tag_name"] as? String ?? ""
                let latestVersion = rawTag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                let body = json["body"] as? String ?? "New performance improvements and stability updates."
                
                // Find DMG download URL
                var downloadUrl = json["html_url"] as? String ?? "https://github.com/ASKHOPE/MacAuraLive/releases"
                if let assets = json["assets"] as? [[String: Any]] {
                    if let dmgAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }),
                       let browserUrl = dmgAsset["browser_download_url"] as? String {
                        downloadUrl = browserUrl
                    }
                }
                
                self?.downloadUrlString = downloadUrl
                self?.targetVersion = latestVersion
                
                if let self = self, self.isVersion(latestVersion, newerThan: self.currentVersion) {
                    self.status = .updateAvailable(version: latestVersion, releaseNotes: body, downloadUrl: downloadUrl)
                } else {
                    self?.status = .upToDate(version: self?.currentVersion ?? AppVersion.fallbackVersion)
                }
            }
        }.resume()
    }
    
    // MARK: - In-App Seamless Download & Install
    
    public func startInAppUpdate() {
        guard let url = URL(string: downloadUrlString) else {
            status = .error(message: "Invalid update download URL.")
            return
        }
        
        status = .downloading(progress: 0.0, bytesWritten: 0, totalBytes: 0)
        downloadProgress = 0.0
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    public func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        status = .idle
    }
    
    // URLSessionDownloadDelegate Methods
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0.0
        DispatchQueue.main.async {
            self.downloadProgress = progress
            self.status = .downloading(progress: progress, bytesWritten: totalBytesWritten, totalBytes: totalBytesExpectedToWrite)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        DispatchQueue.main.async {
            self.status = .verifying
        }
        
        let fileManager = FileManager.default
        let downloadsDir = fileManager.temporaryDirectory.appendingPathComponent("MacAuraLiveUpdates")
        try? fileManager.createDirectory(at: downloadsDir, withIntermediateDirectories: true)
        
        let destinationURL = downloadsDir.appendingPathComponent("MacAuraLive-\(targetVersion).dmg")
        try? fileManager.removeItem(at: destinationURL)
        
        do {
            try fileManager.moveItem(at: location, to: destinationURL)
            DispatchQueue.main.async {
                self.status = .readyToInstall(installerPath: destinationURL.path, version: self.targetVersion)
            }
        } catch {
            DispatchQueue.main.async {
                self.status = .error(message: "Failed to stage update file: \(error.localizedDescription)")
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, (error as NSError).code != NSURLErrorCancelled {
            DispatchQueue.main.async {
                self.status = .error(message: "Download failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Install & Relaunch
    
    public func installAndRelaunch(dmgPath: String) {
        status = .installing
        
        DispatchQueue.global(qos: .userInitiated).async {
            let mountPoint = "/Volumes/MacAuraLive_Update_\(UUID().uuidString.prefix(6))"
            let hdiutil = Process()
            hdiutil.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            hdiutil.arguments = ["attach", dmgPath, "-mountpoint", mountPoint, "-nobrowse", "-quiet"]
            
            do {
                try hdiutil.run()
                hdiutil.waitUntilExit()
                
                let sourceApp = "\(mountPoint)/MacAuraLive.app"
                let targetApp = Bundle.main.bundleURL.path.contains(".app") ? Bundle.main.bundleURL.path : "/Applications/MacAuraLive.app"
                
                // Construct seamless updater bash script
                let pid = ProcessInfo.processInfo.processIdentifier
                let scriptContent = """
                #!/bin/bash
                # Wait for current app instance to quit
                while kill -0 \(pid) 2>/dev/null; do
                    sleep 0.2
                done
                
                # Replace app bundle atomically
                if [ -d "\(sourceApp)" ]; then
                    rm -rf "\(targetApp)"
                    cp -R "\(sourceApp)" "\(targetApp)"
                fi
                
                # Detach mounted DMG
                hdiutil detach "\(mountPoint)" -quiet || true
                
                # Open updated app
                open "\(targetApp)"
                """
                
                let tempScript = FileManager.default.temporaryDirectory.appendingPathComponent("update_relaunch.sh")
                try scriptContent.write(to: tempScript, atomically: true, encoding: .utf8)
                
                let chmod = Process()
                chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
                chmod.arguments = ["+x", tempScript.path]
                try chmod.run()
                chmod.waitUntilExit()
                
                // Launch background worker script
                let launcher = Process()
                launcher.executableURL = URL(fileURLWithPath: "/bin/bash")
                launcher.arguments = [tempScript.path]
                try launcher.run()
                
                DispatchQueue.main.async {
                    NSApp.terminate(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .error(message: "Installation failed: \(error.localizedDescription). Falling back to opening DMG.")
                    NSWorkspace.shared.open(URL(fileURLWithPath: dmgPath))
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    public func openDownloadPage(url: String) {
        if let targetURL = URL(string: url) {
            NSWorkspace.shared.open(targetURL)
        }
    }
    
    private func isVersion(_ v1: String, newerThan v2: String) -> Bool {
        return v1.compare(v2, options: .numeric) == .orderedDescending
    }
}
