//
//  User.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

/// 代表使用者個人檔案的資料模型。
///
/// 這個結構對應於 `/api/users/{userId}/profile` 回傳的 JSON 物件結構。
///
/// - Conforms to `Codable`: 讓 Swift 能夠自動在 JSON 和此結構之間轉換。
/// - Conforms to `Identifiable`: 讓使用者物件可以被唯一識別。
struct User: Codable, Identifiable {
    
    // MARK: - Properties
    
    /// 使用者的唯一識別碼。
    let id: Int
    
    /// 使用者姓名。
    let name: String
    
    /// 借書證 ID。
    let cardId: String
    
    /// 登入帳號。
    let account: String
    
    /// 電子郵件。
    let email: String
    
    /// 聯絡電話 (可選)。
    /// 設為可選(Optional) `String?` 是為了增加程式的健壯性，
    /// 即使後端 JSON 中缺少這個欄位，解析也不會失敗。
    let phone: String?
    
    /// 聯絡地址 (可選)。
    let address: String?
}
