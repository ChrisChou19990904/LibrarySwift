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
    
    enum ViewState {
        case loading
        case content
        case error(String)
    }
    
    private let bookId: Int
    
    // MARK: - Initializer
    
    init(bookId: Int) {
        self.bookId = bookId
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
}
