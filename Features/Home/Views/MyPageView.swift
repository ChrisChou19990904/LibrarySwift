//
//  MyPageView.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import SwiftUI

struct MyPageView: View {
    
    @Environment(AuthenticationManager.self) private var authManager
    @State private var viewModel: MyPageViewModel
    
    init() {
        // 使用一個暫時的 ViewModel 初始化，真實的會在 .onAppear 中注入
        _viewModel = State(initialValue: MyPageViewModel(authManager: AuthenticationManager()))
    }
    
    var body: some View {
        NavigationStack {
            // 使用與 HomeView 類似的左右分欄佈局
            HStack(alignment: .top, spacing: 0) {
                // 左側：功能選擇列表
                // **(修正)** 移除 iOS 不支援的 selection 綁定，
                // 改用 ForEach + Button 的方式手動處理點擊事件。
                List {
                    ForEach(MyPageViewModel.Function.allCases) { function in
                        Button(action: {
                            viewModel.selectedFunction = function
                        }) {
                            HStack {
                                Text(function.rawValue)
                                    .foregroundColor(viewModel.selectedFunction == function ? .accentColor : .primary)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .frame(width: 180)
                
                Divider()
                
                // 右側：內容顯示區
                contentView
            }
            .navigationTitle("個人頁面")
            // **(新增)** 加上 .alert 修飾符
            .alert(viewModel.alertTitle, isPresented: $viewModel.showingAlert) {
                Button("好") { }
            } message: {
                Text(viewModel.alertMessage)
            }            .onAppear {
                // 確保 ViewModel 使用的是從環境中傳入的正確 authManager
                self.viewModel = MyPageViewModel(authManager: authManager)
            }
            .onChange(of: viewModel.selectedFunction) {
                // 當選擇改變時，觸發資料重新獲取
                Task {
                    await viewModel.fetchDataForSelectedFunction()
                }
            }
        }
    }
    
    /// 右側的主要內容視圖
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.viewState {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            Text(message).foregroundColor(.red).frame(maxWidth: .infinity, maxHeight: .infinity)
        case .content:
            switch viewModel.selectedFunction {
            case .profile:
                UserProfileView(user: authManager.loggedInUser)
            case .current, .history, .overdue:
                // **(修改)** 傳入歸還的動作
                LoanListView(
                    loans: viewModel.loans,
                    listType: viewModel.selectedFunction,
                    onReturn: { loanId in
                        Task {
                            await viewModel.returnBook(loanId: loanId)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Subviews

/// 個人檔案視圖
struct UserProfileView: View {
    let user: User?
    
    var body: some View {
        if let user = user {
            Form {
                Section(header: Text("會員資訊")) {
                    InfoRow(label: "姓名", value: user.name)
                    InfoRow(label: "借書證ID", value: user.cardId)
                    InfoRow(label: "帳號", value: user.account)
                    InfoRow(label: "電子郵件", value: user.email)
                    InfoRow(label: "電話", value: user.phone ?? "N/A")
                    InfoRow(label: "地址", value: user.address ?? "N/A")
                }
                
                Section {
                    Button("編輯檔案") { /* TODO */ }
                    Button("修改密碼", role: .destructive) { /* TODO */ }
                }
            }
        } else {
            Text("無法載入使用者資料。")
        }
    }
}

/// 可重用的資訊行
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

/// 借閱列表視圖
struct LoanListView: View {
    let loans: [Loan]
    let listType: MyPageViewModel.Function
    let onReturn: (Int) -> Void // **(修改)** 新增閉包
    
    var body: some View {
        if loans.isEmpty {
            Text("目前沒有\(listType.rawValue)的書籍。")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(loans) { loan in
                LoanCardView(
                    loan: loan,
                    listType: listType,
                    onReturn: { onReturn(loan.loanId) } // **(修改)** 傳遞動作
                )
            }
        }
    }
}

/// 單一借閱紀錄卡片
struct LoanCardView: View {
    let loan: Loan
    //let isOverdue: Bool
    // **(修正)** 新增這兩個屬性，讓 View 知道當前的列表類型，並接收歸還動作
    let listType: MyPageViewModel.Function
    let onReturn: () -> Void // **(修改)** 新增閉包
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loan.title)
                .font(.headline)
            
            Text("書籍碼: \(loan.uniqueCode)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            InfoRow(label: "借閱日期", value: loan.loanDate.formatted(date: .long, time: .omitted))
            
            if let returnDate = loan.returnDate {
                InfoRow(label: "歸還日期", value: returnDate.formatted(date: .long, time: .omitted))
            } else {
                Text("狀態: 借閱中")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            
            // **(修正)** 現在 listType 存在，這個判斷可以正常運作
            if listType == .overdue {
                Text("⚠️ 已逾期！")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
            
            // **(新增)** 只有在 "我的書櫃" 才顯示歸還按鈕
            if listType == .current {
                Button("歸還書籍", action: onReturn)
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    MyPageView()
        .environment(AuthenticationManager())
}
