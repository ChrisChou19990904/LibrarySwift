//
//  RegisterViewModel.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

@MainActor
@Observable
class RegisterViewModel {
    
    // MARK: - Form Fields
    var account = ""
    var password = ""
    var confirmPassword = ""
    var name = ""
    var email = ""
    var phone = ""
    var address = ""
    
    // MARK: - UI State
    var isLoading = false
    var registrationMessage: String?
    var isSuccess = false
    
    // MARK: - Validation
    
    /// 檢查兩次輸入的密碼是否不一致
    var passwordMismatch: Bool {
        !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword
    }
    
    /// 檢查表單是否有效，以啟用/禁用註冊按鈕
    var isFormValid: Bool {
        !account.isEmpty &&
        !password.isEmpty &&
        password.count >= 6 &&
        !confirmPassword.isEmpty &&
        !passwordMismatch &&
        !name.isEmpty &&
        !email.isEmpty // 簡化檢查，實際 App 可加入更複雜的 email 格式驗證
    }
    
    // MARK: - Action
    
    /// 執行註冊
    func register() async {
        guard isFormValid else {
            registrationMessage = "請填寫所有必填欄位並確保密碼一致。"
            isSuccess = false
            return
        }
        
        isLoading = true
        registrationMessage = nil
        
        let request = RegistrationRequest(
            account: account,
            password: password,
            name: name,
            email: email,
            phone: phone.isEmpty ? nil : phone,
            address: address.isEmpty ? nil : address
        )
        
        do {
            let response = try await APIService.shared.register(request: request)
            if response.success {
                registrationMessage = response.message
                isSuccess = true
            } else {
                registrationMessage = response.message ?? "註冊失敗，請稍後再試。"
                isSuccess = false
            }
        } catch let error as APIServiceError {
            switch error {
            case .serverError(_, let message):
                registrationMessage = "註冊失敗：\(message ?? "伺服器錯誤")"
            default:
                registrationMessage = "註冊失敗，請檢查您的網路連線。"
            }
            isSuccess = false
        } catch {
            registrationMessage = "發生未知錯誤。"
            isSuccess = false
        }
        
        isLoading = false
    }
}
