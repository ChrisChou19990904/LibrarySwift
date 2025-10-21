//
//  MyPageViewModel.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import Foundation

@MainActor
@Observable
class MyPageViewModel {
    
    /// 定義個人頁面中的功能分頁
    enum Function: String, CaseIterable, Identifiable {
        case profile = "個人檔案"
        case current = "我的書櫃"
        case history = "借閱紀錄"
        case overdue = "逾期未歸還"
        case statsAll = "統計"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - State Properties
    
    var selectedFunction: Function = .current {
        // **(核心修正)** 使用 didSet 屬性觀察器。
        // 這可以確保無論是從哪裡（例如 MainView 的選單）改變了 selectedFunction，
        // 都會自動觸發一次新的資料獲取。這是最穩健的 MVVM 模式。
        didSet {
            // 避免在值沒有實際改變時重複獲取
            if oldValue != selectedFunction {
                Task {
                    await fetchDataForSelectedFunction()
                }
            }
        }
    }
    
    var loans: [Loan] = []
    var viewState: ViewState = .idle // 預設為閒置狀態

    enum ViewState {
        case idle, loading, content, error(String)
    }
    
    private let authManager: AuthenticationManager
    
    // 新增：用於顯示提示框
    var showingAlert = false
    var alertTitle = ""
    var alertMessage = ""
    
    // ✅ **【新增】** 用於管理歸還確認對話框的狀態
    var showingReturnConfirmation = false
    private var loanToReturnId: Int?
    
    /// **(新增)** 計算屬性，用於在對話框中顯示書名
    var loanToReturnTitle: String {
        guard let loanId = loanToReturnId else { return "這本書" }
        // 從目前的書單中找到對應的書籍標題
        return loans.first { $0.loanId == loanId }?.title ?? "這本書"
    }
    
    // MARK: - Initializer
    
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
        // **(核心修改)** 不在 init 中自動獲取資料，交由 View 控制首次載入時機

    }
    
    // MARK: - Data Fetching
    
    /// 根據當前選擇的功能分頁來獲取對應的資料
    func fetchDataForSelectedFunction() async {
        guard let userId = authManager.loggedInUser?.id else {
            viewState = .error("無法獲取使用者資訊，請重新登入。")
            return
        }
        
        viewState = .loading
        
        do {
            switch selectedFunction {
            case .statsAll:
                loans = []
                viewState = .content
            case .profile:
                // 個人檔案資料直接從 authManager 讀取，loans 設為空
                loans = []
                viewState = .content
            case .current:
                loans = try await APIService.shared.fetchCurrentLoans(userId: userId)
                viewState = .content
            case .history:
                loans = try await APIService.shared.fetchLoanHistory(userId: userId)
                viewState = .content
            case .overdue:
                loans = try await APIService.shared.fetchOverdueLoans(userId: userId)
                viewState = .content
            }
        } catch {
            viewState = .error("載入資料失敗，請稍後再試。")
            print("Error fetching loans for \(selectedFunction.rawValue): \(error)")
        }
    }
    
    /// **(新增)** 步驟 1: View 呼叫此方法來請求歸還，觸發確認對話框
    func requestReturn(loanId: Int) {
        self.loanToReturnId = loanId
        self.showingReturnConfirmation = true
    }
    
    /// **(新增)** 執行歸還書籍的動作
    func confirmReturn() async {
        guard let loanId = loanToReturnId else {
            // 如果沒有 loanId，則不執行任何操作
            return
        }
        
        // 清除暫存的 ID
        self.loanToReturnId = nil


        guard let userId = authManager.loggedInUser?.id else {
            showAlert(title: "錯誤", message: "無法獲取使用者資訊。")
            return
        }
        
        let request = ReturnRequest(loanId: loanId, userId: userId)
        
        do {
            let response = try await APIService.shared.returnBook(request: request)
            if response.success {
                // 成功後，重新整理列表
                await fetchDataForSelectedFunction()
                showAlert(title: "歸還成功", message: "書籍已成功歸還！")
            } else {
                showAlert(title: "歸還失敗", message: response.message ?? "發生未知錯誤。")
            }
        } catch {
            showAlert(title: "歸還失敗", message: "網路請求失敗，請稍後再試。")
        }
    }
    
    private func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
}
