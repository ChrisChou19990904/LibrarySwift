//
//  AuthViewModel.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

@MainActor
@Observable
class AuthViewModel {
    
    // MARK: - Login Properties
    var account = ""
    var password = ""
    var loginError: String?
    var isLoading = false
    
    // MARK: - Dependencies
    private var authManager: AuthenticationManager
    
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
    }
    
    // MARK: - Methods
    
    func login() async -> Bool {
        isLoading = true
        loginError = nil
        
        let request = LoginRequest(account: account, password: password)
        
        do {
            //let response = try await AuthService.shared.login(request: request)
            // **(修改)** 改為呼叫 APIService
            let response = try await APIService.shared.login(request: request)
            authManager.login(response: response)
            isLoading = false
            return true // 登入成功
        } catch {
            loginError = "帳號或密碼錯誤，請重試。"
            isLoading = false
            return false // 登入失敗
        }
    }
}
