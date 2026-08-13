import Foundation
import AppKit

public enum PerformanceTier: String, Codable {
    case full = "Full (60 FPS)"
    case lowPower = "Low Power (30 FPS)"
    case critical = "Critical (15 FPS / Low Res)"
    case paused = "Paused"
}

public class PerformanceManager: ObservableObject {
    public static let shared = PerformanceManager()
    
    @Published public var currentTier: PerformanceTier = .full
    @Published public var batteryLevel: Double = 1.0 // 0.0 to 1.0
    @Published public var isPluggedIn: Bool = true
    
    private var timer: Timer?
    
    private init() {
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        // Monitor thermal state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateChanged),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
        
        // Timer to periodically poll battery status
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
                self?.pollBatteryState()
            }
        }
        
        // Asynchronously poll initial battery status off the main thread to prevent dispatch_once deadlocks
        pollBatteryState()
    }
    
    @objc private func thermalStateChanged() {
        DispatchQueue.main.async {
            self.updatePerformanceState()
        }
    }
    
    private func pollBatteryState() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let isBattery = self.checkIsRunningOnBattery()
            let level = self.getBatteryPercentage()
            
            DispatchQueue.main.async {
                self.isPluggedIn = !isBattery
                self.batteryLevel = level
                self.updatePerformanceState()
            }
        }
    }
    
    private func checkIsRunningOnBattery() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g", "batt"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains("Battery Power")
            }
        } catch {
            print("[PerformanceManager] Error checking battery power: \(error)")
        }
        return false
    }
    
    private func getBatteryPercentage() -> Double {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g", "batt"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let pattern = "\\d+%"
                if let range = output.range(of: pattern, options: .regularExpression) {
                    let pctStr = output[range].replacingOccurrences(of: "%", with: "")
                    if let val = Double(pctStr) {
                        return val / 100.0
                    }
                }
            }
        } catch {
            print("[PerformanceManager] Error getting battery percentage: \(error)")
        }
        return 1.0
    }
    
    public func updatePerformanceState() {
        let thermal = ProcessInfo.processInfo.thermalState
        
        var tier: PerformanceTier = .full
        
        if thermal == .critical {
            tier = .paused
        } else if thermal == .serious {
            tier = .critical
        } else if !isPluggedIn {
            if batteryLevel < 0.20 {
                tier = .critical
            } else if batteryLevel < 0.50 {
                tier = .lowPower
            }
        }
        
        if self.currentTier != tier {
            self.currentTier = tier
            NotificationCenter.default.post(name: Notification.Name("PerformanceTierChanged"), object: tier)
        }
    }
    
    public var targetFps: Int {
        switch currentTier {
        case .full: return 60
        case .lowPower: return 30
        case .critical: return 15
        case .paused: return 0
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
