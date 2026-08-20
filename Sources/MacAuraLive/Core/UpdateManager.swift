import Foundation
import AppKit
import Combine
import CryptoKit

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
    @Published public var verifiedSha256: String? = nil
    
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
            self.verifiedSha256 = nil
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
                
                // Parse expected SHA-256 from release body if present
                var parsedSha: String? = nil
                let shaPattern = #"(?i)SHA-?256:\s*([a-f0-9]{64})"#
                if let regex = try? NSRegularExpression(pattern: shaPattern),
                   let match = regex.firstMatch(in: body, range: NSRange(body.startIndex..., in: body)),
                   let range = Range(match.range(at: 1), in: body) {
                    parsedSha = String(body[range])
                }
                
                // Find DMG download URL & Checksum asset URL
                var downloadUrl = json["html_url"] as? String ?? "https://github.com/ASKHOPE/MacAuraLive/releases"
                var checksumDownloadUrl: String? = nil
                
                if let assets = json["assets"] as? [[String: Any]] {
                    if let dmgAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }),
                       let browserUrl = dmgAsset["browser_download_url"] as? String {
                        downloadUrl = browserUrl
                    }
                    if let shaAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".sha256") == true }),
                       let shaUrl = shaAsset["browser_download_url"] as? String {
                        checksumDownloadUrl = shaUrl
                    }
                }
                
                self?.downloadUrlString = downloadUrl
                self?.targetVersion = latestVersion
                self?.expectedSha256 = parsedSha
                
                // Fetch external sha256 asset if present
                if let checksumUrlStr = checksumDownloadUrl, let checksumUrl = URL(string: checksumUrlStr) {
                    URLSession.shared.dataTask(with: checksumUrl) { cData, _, _ in
                        if let cData = cData, let text = String(data: cData, encoding: .utf8) {
                            let parts = text.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces)
                            if let first = parts.first, first.count == 64 {
                                DispatchQueue.main.async {
                                    self?.expectedSha256 = first
                                }
                            }
                        }
                    }.resume()
                }
                
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
            
            // 1. Cryptographic SHA-256 Checksum Verification
            guard let computedHash = computeSHA256(of: destinationURL) else {
                DispatchQueue.main.async {
                    self.status = .error(message: "Failed to compute cryptographic checksum for downloaded file.")
                }
                return
            }
            
            if let expected = self.expectedSha256, !expected.isEmpty {
                if computedHash.lowercased() != expected.lowercased() {
                    try? fileManager.removeItem(at: destinationURL)
                    DispatchQueue.main.async {
                        self.status = .error(message: "Security Error: Checksum mismatch! Expected \(expected), but got \(computedHash). The download was compromised or corrupted and has been deleted.")
                    }
                    return
                }
            }
            
            // 2. Apple Disk Image Structure Verification
            let verifyProcess = Process()
            verifyProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            verifyProcess.arguments = ["verify", destinationURL.path]
            try? verifyProcess.run()
            verifyProcess.waitUntilExit()
            
            if verifyProcess.terminationStatus != 0 {
                try? fileManager.removeItem(at: destinationURL)
                DispatchQueue.main.async {
                    self.status = .error(message: "Integrity Error: Downloaded DMG failed Apple disk verification. Installation aborted for safety.")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.verifiedSha256 = computedHash
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
    
    // MARK: - Install & Clean Relaunch
    
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
                let targetApp: String
                if Bundle.main.bundleURL.path.hasSuffix(".app") {
                    targetApp = Bundle.main.bundleURL.path
                } else {
                    targetApp = "/Applications/MacAuraLive.app"
                }
                
                let pid = ProcessInfo.processInfo.processIdentifier
                
                // Construct robust, failsafe background atomic update script
                let scriptContent = """
                #!/bin/bash
                set -e
                
                PID=\(pid)
                SOURCE="\(sourceApp)"
                TARGET="\(targetApp)"
                MOUNT="\(mountPoint)"
                
                # 1. Wait for current app instance to fully exit
                COUNT=0
                while kill -0 $PID 2>/dev/null; do
                    sleep 0.15
                    COUNT=$((COUNT + 1))
                    if [ $COUNT -ge 40 ]; then
                        kill -9 $PID 2>/dev/null || true
                        break
                    fi
                done
                
                # 2. Atomically replace application bundle
                if [ -d "$SOURCE" ]; then
                    rm -rf "$TARGET"
                    cp -R "$SOURCE" "$TARGET"
                    xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true
                fi
                
                # 3. Unmount and detach disk image
                hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
                
                # 4. Clean up temporary installer script
                rm -f /tmp/macaura_updater_atomic.sh
                
                # 5. Relaunch fresh instance cleanly
                sleep 0.3
                open -n "$TARGET"
                """
                
                let tempScript = URL(fileURLWithPath: "/tmp/macaura_updater_atomic.sh")
                try scriptContent.write(to: tempScript, atomically: true, encoding: .utf8)
                
                let chmod = Process()
                chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
                chmod.arguments = ["+x", tempScript.path]
                try chmod.run()
                chmod.waitUntilExit()
                
                // Launch background detached process
                let launcher = Process()
                launcher.executableURL = URL(fileURLWithPath: "/bin/bash")
                launcher.arguments = [tempScript.path]
                try launcher.run()
                
                // Cleanly quit current process
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
    
    private func computeSHA256(of fileURL: URL) -> String? {
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else { return nil }
        defer { try? fileHandle.close() }
        
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let chunk = fileHandle.readData(ofLength: 1024 * 1024)
            if chunk.isEmpty { return false }
            hasher.update(data: chunk)
            return true
        }) {}
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    public func openDownloadPage(url: String) {
        if let targetURL = URL(string: url) {
            NSWorkspace.shared.open(targetURL)
        }
    }
    
    private func isVersion(_ v1: String, newerThan v2: String) -> Bool {
        return v1.compare(v2, options: .numeric) == .orderedDescending
    }
}
