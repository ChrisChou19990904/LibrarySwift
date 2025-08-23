//
//  Category.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

/// 代表書籍分類的資料模型。
///
/// 這個結構對應於 `/api/categories` 回傳的 JSON 物件結構。
///
/// - Conforms to `Codable`: 讓 Swift 能夠自動在 JSON 和此結構之間轉換。
/// - Conforms to `Identifiable`: 讓此結構可以在 SwiftUI 的 `List` 或 `ForEach` 中使用。
/// - Conforms to `Hashable`: 讓分類物件可以被放入 `Set` 或作為 `Dictionary` 的鍵，這在處理篩選邏輯時很有用。
struct Category: Codable, Identifiable, Hashable {
    
    // MARK: - Properties
    
    /// 分類的唯一識別碼。
    let id: Int
    
    /// 分類的標題名稱。
    ///
    /// JSON 中的 `categoryTitle` 會透過 `CodingKeys` 對應到 `title` 屬性，
    /// 讓 Swift 程式碼中的命名更簡潔。
    let title: String
    
    // MARK: - Coding Keys
    
    /// 自定義 JSON 鍵與 Swift 屬性之間的對應關係。
    enum CodingKeys: String, CodingKey {
        case id
        case title = "categoryTitle" // 將 JSON 的 "categoryTitle" 映射到 Swift 的 "title"
    }
}
