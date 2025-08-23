//
//  APIAuthModels.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

// MARK: - Login Models

/// 發送登入請求時的資料結構。
struct LoginRequest: Codable {
    let account: String
    let password: String
}

/// 登入成功後從 API 收到的回應。
struct LoginResponse: Codable {
    let jwt: String
    let userId: Int
    let role: String
}

// MARK: - Registration Models

/// 發送註冊請求時的資料結構。
struct RegistrationRequest: Codable {
    let account: String
    let password: String
    let name: String
    let email: String
    let phone: String?
    let address: String?
}

/// 註冊成功後的回應。
struct RegistrationResponse: Codable {
    let success: Bool
    let message: String
}
