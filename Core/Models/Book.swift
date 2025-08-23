//
//  Book.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

/// 代表從 API 獲取的書籍資料模型。
///
/// 這個結構對應於 `/api/books/test/getAllBooksWithDetails` 回傳的 JSON 物件結構。
///
/// - Conforms to `Codable`: 讓 Swift 能夠自動在 JSON 格式和這個 `Book` 結構之間進行轉換。
/// - Conforms to `Identifiable`: 讓這個結構可以直接在 SwiftUI 的 `List` 或 `ForEach` 中使用，
///   SwiftUI 會自動使用 `id` 屬性來識別每一個獨特的項目。
struct Book: Codable, Identifiable {
    
    // MARK: - Properties
    
    /// 書籍的唯一識別碼。
    let id: Int
    
    /// 書籍標題。
    let title: String
    
    /// 作者名稱。
    let author: String
    
    /// 書籍分類。
    let category: String
    
    /// 出版年份。
    let publishYear: Int
    
    /// 出版商。
    let publisher: String
    
    /// 目前可借閱的副本數量。
    let availableCopies: Int
    
    /// 總副本數量。
    let totalCopies: Int
    
    // 注意：
    // 因為 Swift 的屬性名稱 (例如 `publishYear`) 與 JSON 中的鍵 (key) 完全相同，
    // `Codable` 協議可以自動完成所有對應，我們不需要撰寫任何額外的解析程式碼。
    
    let imageUrl: String? // **(新增)** 書籍封面的圖片 URL (可選)

}

