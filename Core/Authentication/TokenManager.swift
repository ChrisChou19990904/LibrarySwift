//
//  TokenManager.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//
// TokenManager 將會取代 localStorage，使用 iOS 更安全的 Keychain 來儲存 JWT。

import Foundation
import Security

/// 安全地在 iOS Keychain 中儲存、讀取和刪除 JWT。
/// Keychain 是加密的，比 UserDefaults 或 localStorage 更適合儲存敏感資料。
class TokenManager {
    
    static let shared = TokenManager()
    private let service = "com.YourApp.OnlineLibrary" // 建議使用您 App 的 Bundle ID
    private let account = "jwtToken"
    
    private init() {}
    
    /// 儲存 JWT 到 Keychain。
    func saveToken(token: String) {
        guard let data = token.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // 先刪除舊的 token，再新增
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// 從 Keychain 讀取 JWT。
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
    
    /// 從 Keychain 刪除 JWT。
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
