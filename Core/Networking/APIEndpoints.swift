//
//  APIEndpoints.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//
// 這個檔案像是一張 API 地圖，集中管理所有 API 的路徑，讓 baseURL 和各個端點一目了然，方便未來維護。

import Foundation

/// 統一定義 App 中所有 API 的端點。
/// 這種方式可以集中管理 URL，避免將字串分散在程式碼各處。
struct APIEndpoints {
    
    // MARK: - Base URL
    
    /// 後端 API 的基礎 URL。
    ///
    /// **注意**: 在實際發佈 App 時，請確保這裡是您的正式伺服器網址。
    /// 為了方便本地開發與測試，您也可以將其設置為 "http://localhost:8080"。
    static let baseURL = "http://localhost:8080"
    
    // MARK: - API Paths
    
    private struct Paths {
        // Auth
        static let login = "/api/auth/login"
        static let register = "/api/users/register"
        
        static let categories = "/api/categories"
        static let books = "/api/books/test/getAllBooksWithDetails"
        static let bookDetails = "/api/books/test/getBookDetailsById02" // 新增
        static let userProfile = "/api/users" // 將會拼接上 userId 和 /profile
    }
    
    // MARK: - Endpoint URLs
    
    static var login: URL { URL(string: baseURL + Paths.login)! }
    static var register: URL { URL(string: baseURL + Paths.register)! }
    /// 獲取所有書籍分類的 URL。
    static var allCategories: URL {
        URL(string: baseURL + Paths.categories)!
    }
    
    /// 獲取書籍列表的 URL。
    ///
    /// - Parameters:
    ///   - categoryId: 可選的分類 ID，用於篩選。
    ///   - searchTerm: 可選的搜尋關鍵字。
    /// - Returns: 包含查詢參數的完整 URL。
    static func books(categoryId: Int?, searchTerm: String?) -> URL {
        var components = URLComponents(string: baseURL + Paths.books)!
        var queryItems = [URLQueryItem]()
        
        if let categoryId = categoryId {
            queryItems.append(URLQueryItem(name: "categoryId", value: String(categoryId)))
        }
        
        if let searchTerm = searchTerm, !searchTerm.isEmpty {
            queryItems.append(URLQueryItem(name: "searchTerm", value: searchTerm))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        return components.url!
    }
    
    /// **(新增)** 獲取指定書籍詳細資訊的 URL。
    static func bookDetails(bookId: Int) -> URL {
        URL(string: baseURL + Paths.bookDetails + "/\(bookId)")!
    }
    
    /// 獲取指定使用者個人檔案的 URL。
    ///
    /// - Parameter userId: 使用者的 ID。
    /// - Returns: 完整的個人檔案 API URL。
    static func userProfile(userId: Int) -> URL {
        URL(string: baseURL + Paths.userProfile + "/\(userId)/profile")!
    }
}
