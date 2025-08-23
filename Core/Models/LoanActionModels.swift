//
//  LoanActionModels.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

// MARK: - Borrow Action

/// 借閱書籍時，發送給 API 的請求本文 (Request Body)。
struct BorrowRequest: Codable {
    let bookId: Int
    let userId: Int
}

/// 借閱書籍成功後，從 API 收到的回應。
struct BorrowResponse: Codable {
    let success: Bool
    let message: String?
    let borrowedBookUniqueCode: String?
    let loanId: Int?
}

// MARK: - Return Action

/// 歸還書籍時，發送給 API 的請求本文。
struct ReturnRequest: Codable {
    let loanId: Int
    let userId: Int
}

/// 歸還書籍成功後，從 API 收到的回應。
struct ReturnResponse: Codable {
    let success: Bool
    let message: String?
    let returnedBookUniqueCode: String?
}
