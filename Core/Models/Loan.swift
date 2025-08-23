//
//  Loan.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

/// 代表一筆借閱紀錄的資料模型。
///
/// 這個結構對應於 `/api/loans/...` 相關端點回傳的 JSON 物件。
struct Loan: Codable, Identifiable {
    
    /// 借閱紀錄本身的唯一 ID。
    let loanId: Int
    
    /// 書籍的 ID。
    /// 為了與 SwiftUI 的 Identifiable 協議兼容，我們將 `loanId` 作為 `id`。
    var id: Int { loanId }
    
    /// 書籍標題。
    let title: String
    
    /// 被借閱的書籍副本的唯一館藏碼。
    let uniqueCode: String
    
    /// 借閱日期。
    let loanDate: Date
    
    /// 歸還日期。如果書籍尚未歸還，此值為 nil。
    let returnDate: Date?
    
    // 注意：
    // API 回傳的日期是 ISO8601 格式的字串 (例如 "2025-07-23T11:16:00.000+00:00")。
    // 我們需要在 APIService 的 JSONDecoder 中設定日期解碼策略，
    // 才能自動將這個字串轉換為 Swift 的 Date 物件。
}
