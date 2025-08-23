//
//  AuthService.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

/// 專門處理使用者登入、註冊、登出等驗證相關的網路請求。
class AuthService {
    
    static let shared = AuthService()
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private init() {}
    
    /// 執行登入。
    func login(request: LoginRequest) async throws -> LoginResponse {
        return try await postRequest(url: APIEndpoints.login, body: request)
    }
    
    /// 執行註冊。
    func register(request: RegistrationRequest) async throws -> RegistrationResponse {
        return try await postRequest(url: APIEndpoints.register, body: request)
    }
    
    /// 通用的 POST 請求方法。
    private func postRequest<T: Codable, U: Codable>(url: URL, body: T) async throws -> U {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                // TODO: 可以從 data 中解析後端回傳的錯誤訊息
                throw APIServiceError.serverError(statusCode: statusCode)
            }
            
            return try decoder.decode(U.self, from: data)
            
        } catch let error as DecodingError {
            throw APIServiceError.decodingError(error)
        } catch {
            throw APIServiceError.networkError(error)
        }
    }
}
