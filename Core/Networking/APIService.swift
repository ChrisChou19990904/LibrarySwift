//
//  APIService.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//
// 核心的 APIService.swift。這個檔案是 App 的網路引擎，負責發送請求、接收 JSON 並將其轉換為我們之前定義好的 Swift Models。

import Foundation

/// 定義 API 服務可能發生的錯誤類型。
enum APIServiceError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int)
    case unknownError
}

/// 負責處理所有網路請求的單例服務。
///
/// 這個服務使用 Swift Concurrency (`async/await`) 來執行異步網路操作。
class APIService {
    
    /// 提供一個共享的單例實例，確保整個 App 共用同一個網路服務。
    static let shared = APIService()
    
    /// JSON 解碼器，用於將 API 回應的資料轉換為 Swift 物件。
    private let decoder = JSONDecoder()
    
    /// 私有化初始化方法，確保外部無法創建此類別的新實例。
    private init() {}
    
    // MARK: - Public API Methods
    
    /// 從後端獲取書籍列表。
    ///
    /// - Parameters:
    ///   - categoryId: 可選的分類 ID。
    ///   - searchTerm: 可選的搜尋關鍵字。
    /// - Returns: 一個 `Book` 物件的陣列。
    /// - Throws: `APIServiceError` 如果請求失敗或資料解析錯誤。
    func fetchBooks(categoryId: Int? = nil, searchTerm: String? = nil) async throws -> [Book] {
        let url = APIEndpoints.books(categoryId: categoryId, searchTerm:searchTerm)
        return try await fetchData(from: url)
    }
    
    /// 從後端獲取所有書籍分類。
    ///
    /// - Returns: 一個 `Category` 物件的陣列。
    /// - Throws: `APIServiceError` 如果請求失敗或資料解析錯誤。
    func fetchCategories() async throws -> [Category] {
        return try await fetchData(from: APIEndpoints.allCategories)
    }
    
    /// **(新增)** 從後端獲取指定書籍的詳細資訊。
    func fetchBookDetails(bookId: Int) async throws -> BookDetail {
        let url = APIEndpoints.bookDetails(bookId: bookId)
        return try await fetchData(from: url)
    }
    
    /// 從後端獲取指定使用者的個人檔案。
    ///
    /// - Parameter userId: 要獲取資料的使用者 ID。
    /// - Returns: 一個 `User` 物件。
    /// - Throws: `APIServiceError` 如果請求失敗或資料解析錯誤。
    func fetchUserProfile(userId: Int) async throws -> User {
        let url = APIEndpoints.userProfile(userId: userId)
        return try await fetchData(from: url)
    }
    
    // MARK: - Generic Fetch Logic
    
    /// 一個通用的異步函數，用於從指定的 URL 獲取並解碼資料。
    ///
    /// - Parameter url: 要從中獲取資料的 URL。
    /// - Returns: 一個符合 `Codable` 協議的解碼後物件。
    /// - Throws: `APIServiceError`。
    private func fetchData<T: Codable>(from url: URL) async throws -> T {
        do {
            // 1. 使用 async/await 執行網路請求
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // 2. 檢查 HTTP 回應狀態碼
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw APIServiceError.serverError(statusCode: statusCode)
            }
            
            // 3. 嘗試將回傳的 data 解碼為指定的泛型 T
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            // 處理 JSON 解析錯誤
            throw APIServiceError.decodingError(error)
        } catch {
            // 處理其他網路錯誤
            throw APIServiceError.networkError(error)
        }
    }
}
