//
//  BookCopy.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

/// 代表單一書籍副本的資料模型。
struct BookCopy: Codable, Identifiable, Hashable {
    
    /// 副本的唯一識別碼 (注意：這裡假設 API 回應中有 `id` 欄位，如果沒有，則需要調整)。
    /// 為了讓 ForEach 能運作，我們需要一個唯一的 id。如果 API 沒有提供，
    /// 可以讓 `uniqueCode` 作為 id，或是在 ViewModel 中手動產生。
    /// 這裡我們假設 API 回應的 JSON 中有 `id`。
    let id: Int
    
    /// 書籍副本的唯一館藏碼。
    let uniqueCode: String
    
    /// 副本的當前狀態描述 (例如："可借閱", "已借出")。
    let statusDescription: String
    
    let imageUrl: String? // **(新增)** 書籍封面的圖片 URL (可選)

}
