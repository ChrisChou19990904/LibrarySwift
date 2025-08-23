//
//  HomeViewModel.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//
// 核心檔案：
// HomeViewModel.swift: 這是首頁的「大腦」。它負責使用 APIService 去獲取書籍和分類資料，並管理所有 UI 狀態，例如「正在載入」、「載入成功」或「發生錯誤」。
// HomeView.swift: 這是首頁的「臉孔」，也就是您在 index.html 中看到的介面。它會根據 HomeViewModel 提供的資料來顯示分類列表和書籍網格，並提供搜尋功能。

import Foundation

@MainActor // 確保所有屬性更新都在主執行緒上，這是 UI 相關操作的最佳實踐
@Observable // 使用 Swift 5.9+ 最新的 @Observable 宏來自動管理 UI 更新
class HomeViewModel {
    
    // MARK: - State Properties
    
    /// 書籍列表，UI 會自動觀察此屬性的變化並更新
    var books: [Book] = []
    
    /// 分類列表
    var categories: [Category] = []
    
    /// 當前選擇的分類 ID (nil 代表 "所有書籍")
    var selectedCategoryId: Int? = nil {
        didSet {
            // 當分類改變時，觸發一次新的書籍資料獲取
            Task {
                await fetchBooks()
            }
        }
    }
    
    /// 搜尋關鍵字，與 UI 上的搜尋欄雙向綁定
    var searchTerm: String = ""
    
    /// 視圖的當前狀態，用於控制 UI 顯示 (例如：載入中動畫、錯誤訊息)
    var viewState: ViewState = .loading
    
    /// 定義視圖的各種可能狀態
    enum ViewState {
        case loading
        case content
        case error(String)
    }
    
    // MARK: - Initializer
    
    init() {
        // ViewModel 初始化時，立即執行首次資料載入
        Task {
            await initialLoad()
        }
    }
    
    // MARK: - Data Fetching Methods
    
    /// 首次載入頁面所需的全部資料 (分類 + 書籍)
    func initialLoad() async {
        viewState = .loading
        
        do {
            // 使用 TaskGroup 並行執行兩個網路請求，提升啟動效率
            async let categoriesTask = APIService.shared.fetchCategories()
            async let booksTask = APIService.shared.fetchBooks()
            
            // 等待兩個請求都完成後，再統一更新屬性
            let (fetchedCategories, fetchedBooks) = try await (categoriesTask, booksTask)
            
            self.categories = fetchedCategories
            self.books = fetchedBooks
            self.viewState = .content // 切換到內容顯示狀態
            
        } catch {
            // 捕獲任何錯誤並更新狀態
            viewState = .error(mapError(error))
        }
    }
    
    /// 根據當前的分類和搜尋詞獲取書籍
    func fetchBooks() async {
        // 注意：這裡我們不改變 viewState，因為只是更新部分內容，
        // 而不是整個頁面重新載入。可以選擇性地添加一個小的載入指示器。
        do {
            books = try await APIService.shared.fetchBooks(
                categoryId: selectedCategoryId,
                searchTerm: searchTerm.isEmpty ? nil : searchTerm // 如果搜尋詞為空，則傳遞 nil
            )
        } catch {
            // 實際 App 中，可以在書籍列表區域顯示一個小的錯誤提示
            print("獲取書籍失敗: \(mapError(error))")
        }
    }
    
    /// 執行搜尋 (通常由鍵盤的搜尋按鈕觸發)
    func performSearch() {
        Task {
            await fetchBooks()
        }
    }
    
    // MARK: - Private Helpers
    
    /// 將 Error 轉換為使用者友好的提示文字
    private func mapError(_ error: Error) -> String {
        if let apiError = error as? APIServiceError {
            switch apiError {
            case .networkError(let err):
                return "網路連線錯誤: \(err.localizedDescription)"
            case .decodingError:
                return "資料解析失敗，請檢查 API 回應格式。"
            case .serverError(let statusCode):
                return "伺服器錯誤，狀態碼: \(statusCode)"
            default:
                return "發生未知 API 錯誤。"
            }
        }
        return "發生未知錯誤: \(error.localizedDescription)"
    }
}
