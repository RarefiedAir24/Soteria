//
//  KeychainHelper.swift
//  soteria
//
//  Secure keychain storage utility
//

import Foundation
import Security

struct KeychainHelper {
    private static let service = "io.montebay.soteria"
    
    /// Store a value in the keychain
    static func set(key: String, value: String) {
        // Delete existing item first
        delete(key: key)
        
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("⚠️ [KeychainHelper] Failed to store key '\(key)': \(status)")
        }
    }
    
    /// Retrieve a value from the keychain
    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }
        
        if status != errSecItemNotFound {
            print("⚠️ [KeychainHelper] Failed to retrieve key '\(key)': \(status)")
        }
        
        return nil
    }
    
    /// Delete a value from the keychain
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            print("⚠️ [KeychainHelper] Failed to delete key '\(key)': \(status)")
        }
    }
}

