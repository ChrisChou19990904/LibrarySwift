//
//  MyPageView.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import SwiftUI

struct MyPageView: View {
    
    @Environment(AuthenticationManager.self) private var authManager
    
    // **(核心修改)** ViewModel 現在是一個普通的 @State 變數，從外部傳入
    // 它不再負責自己的創建邏輯
    @State var viewModel: MyPageViewModel
    
    @Binding var isMenuPresented: Bool
    
    var body: some View {
        NavigationStack {
            contentView
            // ✅ **【核心修正】** 使用 .task 修飾符取代 .onAppear
            // 這不僅解決了編譯錯誤，也是處理非同步任務的現代最佳實踐
                .task {
                    await viewModel.fetchDataForSelectedFunction()
                }
                .navigationTitle("個人頁面")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation(.easeInOut) {
                                isMenuPresented.toggle()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                    }
                }
                // 一般提示框
                .alert(viewModel.alertTitle, isPresented: $viewModel.showingAlert) {
                    Button("好") { }
                } message: {
                    Text(viewModel.alertMessage)
                }
                // ✅ **【新增】** 歸還書籍的確認對話框
                .alert("確認歸還", isPresented: $viewModel.showingReturnConfirmation) {
                    // "確定" 按鈕，建議使用 .destructive 角色，使其呈現紅色以示警告
                    Button("確定", role: .destructive) {
                        Task {
                            await viewModel.confirmReturn()
                        }
                    }
                    // "取消" 按鈕
                    Button("取消", role: .cancel) { }
                } message: {
                    Text("您確定要歸還《\(viewModel.loanToReturnTitle)》嗎？")
                }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.viewState {
        case .idle, .loading: // 將 idle 和 loading 狀態都顯示為進度條
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            Text(message).foregroundColor(.red).frame(maxWidth: .infinity, maxHeight: .infinity)
        case .content:
            switch viewModel.selectedFunction {
            case .profile:
                UserProfileView(user: authManager.loggedInUser)
            case .current, .history, .overdue:
                LoanListView(
                    loans: viewModel.loans,
                    listType: viewModel.selectedFunction,
                    // ✅ **【修改】** onReturn 現在呼叫 requestReturn 來觸發確認流程
                    onReturn: { loanId in
                        viewModel.requestReturn(loanId: loanId)
                    }
                )
            }
        }
    }
}
    



// MARK: - Subviews

/// **(新增)** 將功能列表提取為獨立的子視圖
struct FunctionListView: View {
    @Binding var selectedFunction: MyPageViewModel.Function
    var onFunctionSelected: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("功能選擇")
                .font(.title2.bold())
                .padding([.horizontal, .top])
            
            List {
                ForEach(MyPageViewModel.Function.allCases) { function in
                    Button(action: {
                        if selectedFunction != function {
                            selectedFunction = function
                        }
                        onFunctionSelected()
                    }) {
                        HStack {
                            Text(function.rawValue)
                                .foregroundColor(selectedFunction == function ? .accentColor : .primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
        }
    }
}

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
            AsyncImageView(urlString: loan.imageUrl)
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
                .clipped()
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

// ... (其他 Subviews 保持不變)

#Preview {
    // **(修改)** 更新預覽以匹配新的 init 方法
    MyPageView(
        viewModel: MyPageViewModel(authManager: AuthenticationManager()),
        isMenuPresented: .constant(false)
    )
    .environment(AuthenticationManager())
}
