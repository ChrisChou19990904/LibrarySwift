//
//  APIService.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//
// 核心的 APIService.swift。這個檔案是 App 的網路引擎，負責發送請求、接收 JSON 並將其轉換為我們之前定義好的 Swift Models。
//
// AuthService 的功能合併到 APIService 中，讓 APIService 成為 App 唯一的網路請求中心，同時新增借閱與歸還的功能。

import Foundation

/// 定義 API 服務可能發生的錯誤類型。
enum APIServiceError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    // **(修正)** 在 serverError case 中加入 message 參數，使其與呼叫時的格式一致。
    case serverError(statusCode: Int, message: String?)
    case authenticationError // 用於表示需要 token 但 token 不存在的情況
    case unknownError
}

/// 負責處理所有網路請求的單例服務。
///
/// 這個服務使用 Swift Concurrency (`async/await`) 來執行異步網路操作。
class APIService {
    
    /// 提供一個共享的單例實例，確保整個 App 共用同一個網路服務。
    static let shared = APIService()
        
    // **(修正)** 使用閉包直接初始化 let 常數，確保只被賦值一次。
    // 這種寫法既符合 let 的規則，又能包含多行設定邏輯。
    /// JSON 解碼器，用於將 API 回應的資料轉換為 Swift 物件。
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        //decoder.dateDecodingStrategy = .iso8601
        // 舊的 .iso8601 策略過於嚴格，我們改用自訂的 DateFormatter 來確保能正確解析 API 回傳的日期格式。
        let formatter = DateFormatter()
        // 設定與後端 API 回應的日期格式匹配
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        // 使用 POSIX 地區設定，避免使用者手機的地區設定影響日期解析
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // 根據需求設定時區（見下方說明）
        formatter.timeZone = TimeZone(identifier: "Asia/Taipei") // 假設你的應用使用台灣時區
        
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()
    
    private let encoder = JSONEncoder()
    
    // 初始化方法現在變為空
    private init() {}
    
    // MARK: - Auth APIs (從 AuthService 合併過來)
    // 修正: - Public APIs (不需要 Token)
    func login(request: LoginRequest) async throws -> LoginResponse {
        return try await performRequest(url: APIEndpoints.login, method: "POST", body: request, requiresAuth: false)
    }
    
    func register(request: RegistrationRequest) async throws -> RegistrationResponse {
        return try await performRequest(url: APIEndpoints.register, method: "POST", body: request, requiresAuth: false)
    }
        
    // MARK: - Public API Methods
    // 修正: - Public APIs (不需要 Token)
    /// 從後端獲取書籍列表。
    ///
    /// - Parameters:
    ///   - categoryId: 可選的分類 ID。
    ///   - searchTerm: 可選的搜尋關鍵字。
    /// - Returns: 一個 `Book` 物件的陣列。
    /// - Throws: `APIServiceError` 如果請求失敗或資料解析錯誤。
    func fetchBooks(categoryId: Int? = nil, searchTerm: String? = nil) async throws -> [Book] {
        let url = APIEndpoints.books(categoryId: categoryId, searchTerm:searchTerm)
        return try await performRequest(url: url, requiresAuth: false)
    }
    
    /// 從後端獲取所有書籍分類。
    ///
    /// - Returns: 一個 `Category` 物件的陣列。
    /// - Throws: `APIServiceError` 如果請求失敗或資料解析錯誤。
    func fetchCategories() async throws -> [Category] {
        return try await performRequest(url: APIEndpoints.allCategories, requiresAuth: false)
    }
    
    /// **(新增)** 從後端獲取指定書籍的詳細資訊。
    func fetchBookDetails(bookId: Int) async throws -> BookDetail {
        let url = APIEndpoints.bookDetails(bookId: bookId)
        return try await performRequest(url: url, requiresAuth: false)
    }
    
    /// 從後端獲取指定使用者的個人檔案。
    ///
    /// - Parameter userId: 要獲取資料的使用者 ID。
    /// - Returns: 一個 `User` 物件。
    /// - Throws: `APIServiceError` 如果請求失敗或資料解析錯誤。
    func fetchUserProfile(userId: Int) async throws -> User {
        let url = APIEndpoints.userProfile(userId: userId)
        return try await performRequest(url: url, requiresAuth: true)
    }
    
    // MARK: - Loan APIs (新增)
    
    func fetchCurrentLoans(userId: Int) async throws -> [Loan] {
        let url = APIEndpoints.currentLoans(userId: userId)
        return try await performRequest(url: url, requiresAuth: true)
    }
    
    func fetchLoanHistory(userId: Int) async throws -> [Loan] {
        let url = APIEndpoints.loanHistory(userId: userId)
        return try await performRequest(url: url, requiresAuth: true)
    }
    
    func fetchOverdueLoans(userId: Int) async throws -> [Loan] {
        let url = APIEndpoints.overdueLoans(userId: userId)
        return try await performRequest(url: url, requiresAuth: true)
    }
    
    // MARK: - Loan Action APIs (新增)
    
    func borrowBook(request: BorrowRequest) async throws -> BorrowResponse {
        return try await performRequest(url: APIEndpoints.borrowBook, method: "POST", body: request, requiresAuth: true)
    }
    
    func returnBook(request: ReturnRequest) async throws -> ReturnResponse {
        return try await performRequest(url: APIEndpoints.returnBook, method: "POST", body: request, requiresAuth: true)
    }
    
    
    
    /// 統一的網路請求處理器。
    /// - Parameter requiresAuth: 決定是否需要在請求 Header 中附加 Bearer Token。
    private func performRequest<T: Codable>(
        url: URL,
        method: String = "GET",
        body: (any Encodable)? = nil,
        requiresAuth: Bool
    ) async throws -> T {
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // **(核心修改)** 只有在 `requiresAuth` 為 true 時才附加 Token
        if requiresAuth {
            guard let token = TokenManager.shared.getToken() else {
                // 如果需要 token 但 token 不存在，直接拋出驗證錯誤
                throw APIServiceError.authenticationError
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIServiceError.unknownError
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8)
                throw APIServiceError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            throw APIServiceError.decodingError(error)
        } catch {
            // 重新拋出已知的 APIServiceError 或其他網路錯誤
            throw error
        }
    }


    
//    // MARK: - Generic Fetch Logic
//    
//    /// 一個通用的異步函數，用於從指定的 URL 獲取並解碼資料。
//    ///
//    /// - Parameter url: 要從中獲取資料的 URL。
//    /// - Returns: 一個符合 `Codable` 協議的解碼後物件。
//    /// - Throws: `APIServiceError`。
//    private func fetchData<T: Codable>(from url: URL) async throws -> T {
//        do {
//            // 1. 使用 async/await 執行網路請求
//            let (data, response) = try await URLSession.shared.data(from: url)
//            
//            // 2. 檢查 HTTP 回應狀態碼
//            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
//                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
//                let errorMessage = String(data: data, encoding: .utf8)
//                throw APIServiceError.serverError(statusCode: statusCode, message: errorMessage)
//            }
//            
//            // 3. 嘗試將回傳的 data 解碼為指定的泛型 T
//            return try decoder.decode(T.self, from: data)
//            
//        } catch let error as DecodingError {
//            // 處理 JSON 解析錯誤
//            throw APIServiceError.decodingError(error)
//        } catch {
//            // 處理其他網路錯誤
//            throw APIServiceError.networkError(error)
//        }
//    }
//    
//    /// 通用的 POST 請求方法
//    private func postData<T: Codable, U: Codable>(url: URL, body: T) async throws -> U {
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        // 自動附加 JWT
//        if let token = TokenManager.shared.getToken() {
//            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        }
//        request.httpBody = try encoder.encode(body)
//        
//        do {
//            let (data, response) = try await URLSession.shared.data(for: request)
//            
//            guard let httpResponse = response as? HTTPURLResponse else {
//                throw APIServiceError.unknownError
//            }
//            
//            guard (200...299).contains(httpResponse.statusCode) else {
//                // 嘗試解析後端回傳的錯誤訊息
//                let errorMessage = String(data: data, encoding: .utf8)
//                throw APIServiceError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
//            }
//            
//            return try decoder.decode(U.self, from: data)
//            
//        } catch let error as DecodingError {
//            throw APIServiceError.decodingError(error)
//        } catch {
//            throw error // 重新拋出已知的 APIServiceError 或其他網路錯誤
//        }
//    }
        
}
