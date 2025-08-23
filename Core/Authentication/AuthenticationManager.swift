//
//  AuthenticationManager.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//
// AuthenticationManager 是一個全局物件，讓 App 的任何地方都能知道當前的登入狀態。

import Foundation
import Combine

/// 一個全局的、可觀察的物件，用於管理整個 App 的使用者登入狀態。
@MainActor
@Observable
class AuthenticationManager {
    
    /// 當前登入的使用者資訊。如果為 nil，表示使用者未登入。
    var loggedInUser: User?
    
    /// 當前儲存的 JWT。
    private(set) var jwt: String?
    
    init() {
        // App 啟動時，嘗試從 Keychain 讀取 token
        self.jwt = TokenManager.shared.getToken()
        
        // 如果有 token，可以選擇性地去後端驗證 token 有效性並獲取使用者資料
        // 這裡我們先簡化處理，假設有 token 就視為可能已登入
    }
    
    /// 處理登入成功後的邏輯。
    func login(response: LoginResponse) {
        // 1. 儲存 token
        TokenManager.shared.saveToken(token: response.jwt)
        self.jwt = response.jwt
        
        // 2. 這裡可以接著去獲取使用者完整資料並存到 loggedInUser
        //    或者，如果 LoginResponse 已經包含足夠資訊，可以直接建立 User 物件
        print("登入成功！使用者 ID: \(response.userId)，角色: \(response.role)")
        // 為了讓 UI 更新，我們需要獲取 User Profile
        Task {
            do {
                self.loggedInUser = try await APIService.shared.fetchUserProfile(userId: response.userId)
            } catch {
                print("登入後獲取使用者資料失敗: \(error)")
                // 即使獲取失敗，至少 token 已經儲存，可以稍後重試
            }
        }
    }
    
    /// 處理登出。
    func logout() {
        TokenManager.shared.deleteToken()
        self.jwt = nil
        self.loggedInUser = nil
    }
}
