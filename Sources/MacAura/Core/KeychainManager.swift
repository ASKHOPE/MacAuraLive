import Foundation

public class KeychainManager {
    public static let shared = KeychainManager()
    private let userDefaultsKeyPrefix = "MacAura_SecureKey_"
    
    private init() {}
    
    public func saveKey(_ key: String, forAccount account: String) {
        let storageKey = userDefaultsKeyPrefix + account
        if key.isEmpty {
            UserDefaults.standard.removeObject(forKey: storageKey)
        } else {
            UserDefaults.standard.set(key, forKey: storageKey)
        }
    }
    
    public func getKey(forAccount account: String) -> String {
        let storageKey = userDefaultsKeyPrefix + account
        return UserDefaults.standard.string(forKey: storageKey) ?? ""
    }
    
    public func maskKey(_ key: String) -> String {
        guard key.count > 8 else { return key.isEmpty ? "" : "••••••••" }
        let prefix = String(key.prefix(6))
        let suffix = String(key.suffix(4))
        return "\(prefix)••••••••\(suffix)"
    }
}
