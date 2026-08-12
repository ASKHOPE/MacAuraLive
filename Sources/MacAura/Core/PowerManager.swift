import AppKit
import Combine
import IOKit.ps

public class PowerManager: ObservableObject {
    public static let shared = PowerManager()
    
    @Published public var isOnBattery: Bool = false
    @Published public var isFullScreenAppActive: Bool = false
    
    private var timer: Timer?
    
    private init() {
        checkPowerSource()
        startMonitoring()
    }
    
    public func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkPowerSource()
            self?.checkFullScreenApp()
        }
    }
    
    public func checkPowerSource() {
        guard let blobRef = IOPSCopyPowerSourcesInfo() else {
            DispatchQueue.main.async { self.isOnBattery = false }
            return
        }
        let blob = blobRef.takeRetainedValue()
        guard let sourcesRef = IOPSCopyPowerSourcesList(blob) else {
            DispatchQueue.main.async { self.isOnBattery = false }
            return
        }
        let sources = sourcesRef.takeRetainedValue() as [CFTypeRef]
        
        var batteryActive = false
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any],
               let state = description[kIOPSPowerSourceStateKey] as? String {
                if state == kIOPSBatteryPowerValue {
                    batteryActive = true
                    break
                }
            }
        }
        
        DispatchQueue.main.async {
            self.isOnBattery = batteryActive
        }
    }
    
    public func checkFullScreenApp() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        
        let appName = frontApp.localizedName ?? ""
        // Ignore Finder or MacAura app itself
        if appName == "Finder" || appName == "MacAura" {
            DispatchQueue.main.async {
                self.isFullScreenAppActive = false
            }
            return
        }
        
        let mainScreenFrame = NSScreen.main?.frame ?? .zero
        let windowListInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        
        var foundFullScreen = false
        for win in windowListInfo {
            if let pid = win[kCGWindowOwnerPID as String] as? pid_t, pid == frontApp.processIdentifier,
               let boundsDict = win[kCGWindowBounds as String] as? [String: Any],
               let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) {
                if bounds.width >= mainScreenFrame.width && bounds.height >= mainScreenFrame.height {
                    foundFullScreen = true
                    break
                }
            }
        }
        
        DispatchQueue.main.async {
            self.isFullScreenAppActive = foundFullScreen
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
