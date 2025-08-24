//
//  BookDetailViewModel.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

@MainActor // 確保所有屬性更新都在主執行緒
@Observable // 使用最新的 @Observable 宏
class BookDetailViewModel {
    
    // MARK: - State Properties
    
    /// 書籍的詳細資料。設為可選，以便處理尚未載入完成的狀態。
    var bookDetail: BookDetail?
    
    /// 視圖的當前狀態
    var viewState: ViewState = .loading
    
    // 新增：用於顯示提示框 (Alert)
    var showingAlert = false
    var alertTitle = ""
    var alertMessage = ""
    
    // **(新增)** 用於顯示借閱確認對話框
    var showingBorrowConfirmation = false
    
    enum ViewState {
        case loading
        case content
        case error(String)
    }
    
    // **(修正)** 移除 private 關鍵字，讓外部的 View 可以讀取 bookId
    let bookId: Int
    private let authManager: AuthenticationManager

    
    // MARK: - Initializer
    
    init(bookId: Int, authManager: AuthenticationManager) {
        self.bookId = bookId
        self.authManager = authManager
        // ViewModel 初始化時，立即開始獲取資料
        Task {
            await fetchDetails()
        }
    }
    
    // MARK: - Data Fetching
    
    /// 獲取書籍的詳細資料
    func fetchDetails() async {
        viewState = .loading
        do {
            bookDetail = try await APIService.shared.fetchBookDetails(bookId: bookId)
            viewState = .content
        } catch {
            viewState = .error("無法載入書籍詳情，請稍後再試。")
            print("Error fetching book details: \(error)")
        }
    }
    
    /// **(修改)** 第一步：請求借閱，這只會觸發確認對話框
    func requestBorrow() {
        guard authManager.loggedInUser != nil else {
            showAlert(title: "需要登入", message: "請先登入才能借閱書籍。")
            return
        }
        showingBorrowConfirmation = true
    }
    
    /// **(新增)** 執行借閱書籍的動作
    /// **(新增)** 第二步：使用者確認後，才真正執行借閱 API 呼叫
    func confirmBorrow() async {
        guard let userId = authManager.loggedInUser?.id else {
            showAlert(title: "錯誤", message: "無法獲取使用者資訊。")
            return
        }
        
        let request = BorrowRequest(bookId: bookId, userId: userId)
        
        do {
            let response = try await APIService.shared.borrowBook(request: request)
            if response.success {
                // **(修正)** 先在背景重新整理資料
                await fetchDetails()
                // 然後再顯示成功的提示框，這樣提示框就不會被中斷
                showAlert(title: "借閱成功", message: "您已成功借閱《\(bookDetail?.title ?? "")》！\n書籍副本碼: \(response.borrowedBookUniqueCode ?? "N/A")")
            } else {                showAlert(title: "借閱失敗", message: response.message ?? "發生未知錯誤。")
            }
        } catch {
            showAlert(title: "借閱失敗", message: "網路請求失敗，請稍後再試。")
        }
    }
    
    /// **(新增)** 輔助函數，用於設定提示框內容
    private func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
}
