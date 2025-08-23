//
//  BookDetail.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

/// 代表書籍詳細資訊的資料模型。
///
/// 這個結構對應於 `/api/books/test/getBookDetailsById02/{bookId}` 回傳的 JSON 物件。
/// 它包含了比 `Book` 列表模型更豐富的資訊。
struct BookDetail: Codable, Identifiable {
    let id: Int
    let title: String
    let author: String
    let category: String
    let publishYear: Int
    let publisher: String
    let availableCopies: Int
    let totalCopies: Int
    
    // --- 詳細資訊欄位 ---
    
    /// 書籍的國際標準書號 (可選)。
    let isbn: String?
    
    /// 書籍的詳細描述 (可選)。
    let description: String?
    
    /// 這本書的所有實體副本列表。
    let bookCopies: [BookCopy]
}
