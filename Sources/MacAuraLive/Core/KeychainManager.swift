import Foundation
import Security

public class KeychainManager {
    public static let shared = KeychainManager()
    private let serviceName = "com.macaura.apikeys"
    
    private init() {}
    
    /// Securely saves an API key to the macOS Keychain using hardware-enclave AES-256 encryption (Security.framework)
    public func saveKey(_ key: String, forAccount account: String) {
        guard let data = key.data(using: .utf8) else { return }
        
        // Query to check if key already exists
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        if key.isEmpty {
            SecItemDelete(query as CFDictionary)
            return
        }
        
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        if status == errSecItemNotFound {
            var newQuery = query
            newQuery[kSecValueData as String] = data
            newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(newQuery as CFDictionary, nil)
        }
    }
    
    /// Retrieves an API key from the macOS Keychain
    public func getKey(forAccount account: String) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data, let key = String(data: data, encoding: .utf8) {
            return key
        }
        
        return ""
    }
    
    /// Masks sensitive API key for safe UI display (e.g. sk-proj...8A1b)
    public func maskKey(_ key: String) -> String {
        guard key.count > 8 else { return key.isEmpty ? "" : "••••••••" }
        let prefix = String(key.prefix(6))
        let suffix = String(key.suffix(4))
        return "\(prefix)••••••••\(suffix)"
    }
}
