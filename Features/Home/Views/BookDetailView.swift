//
//  BookDetailView.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import SwiftUI

struct BookDetailView: View {
    
    @Environment(AuthenticationManager.self) private var authManager
    @State private var viewModel: BookDetailViewModel
    
    // MARK: - Initializer
    
    init(bookId: Int) {
        // _viewModel 是對 @State 屬性本身的引用，用於初始化
        // 暫時初始化，onAppear 時會更新
        _viewModel = State(initialValue: BookDetailViewModel(bookId: bookId, authManager: AuthenticationManager()))
    }
    
    var body: some View {
        // 根據 ViewModel 的狀態顯示 UI
        // **(修改)** 現在 body 直接呼叫 content 計算屬性，
        // 並將所有修飾符附加在 content 上。
        content

        // **(新增)** 在最外層加上 .alert 修飾符
        .alert(viewModel.alertTitle, isPresented: $viewModel.showingAlert) {
            Button("好") { }
        } message: {
            Text(viewModel.alertMessage)
        }
        // **(新增)** 借閱確認對話框
        .alert("確認借閱", isPresented: $viewModel.showingBorrowConfirmation) {
            Button("確定", role: .none) {
                Task {
                    await viewModel.confirmBorrow()
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("您確定要借閱《\(viewModel.bookDetail?.title ?? "這本書")》嗎？")
        }
        .task {
            // 注入真實的 authManager
            self.viewModel = BookDetailViewModel(bookId: viewModel.bookId, authManager: authManager)
        }
    }
    
    /// **(新增)** 使用 @ViewBuilder 將 switch 邏輯提取到一個獨立的計算屬性中。
    /// 原本是在 body 裡面， switch 包在 Group 中，為修飾符提供一個穩定的作用對象
    /// 但 SwiftUI 的編譯器在處理 switch 語句時，因為每個 case 回傳的 View 類型都不同，所以無法推斷出 Group 應該包裹的內容究竟是什麼具體類型。
    /// 故獨立出來，將整個 switch 邏輯提取到一個獨立的計算屬性 (computed property) 中，
    /// 並用 @ViewBuilder來標註它。這等於是明確地告訴編譯器：「這個屬性會根據邏輯來建構不同類型的 View，請你處理好。」
    /// 這是處理複雜條件視圖的最佳實踐。
    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            ProgressView("載入書籍詳情...")
                .navigationTitle("載入中")
        case .error(let message):
            Text(message)
                .foregroundColor(.red)
                .navigationTitle("錯誤")
        case .content:
            // 確保 bookDetail 不是 nil
            if let detail = viewModel.bookDetail {
                // 使用 ScrollView 讓內容可以滾動
                // 包裹新的 VStack 佈局
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. 頂部的大圖片
                        AsyncImageView(urlString: detail.imageUrl)
                            .frame(height: 350)
                            .aspectRatio(2/3, contentMode: .fit) // 給予一個常見的書籍長寬比
                            .containerRelativeFrame(.horizontal) { width, axis in
                                width * 0.7 // 圖片寬度為螢幕寬度的 70%
                            }
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                            .shadow(radius: 8)
                        
                        // 2. 下方的所有資訊區塊
                        VStack(alignment: .leading, spacing: 24) {
                            BookInfoView(detail: detail)
                            BookDescriptionView(detail: detail)
                            BookCopiesView(detail: detail) {
                                viewModel.requestBorrow() // 觸發確認對話框
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .navigationTitle(detail.title)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("找不到書籍資料。")
                    .navigationTitle("錯誤")
            }
        }
    }
    
    
    
}

// MARK: - Subviews for BookDetailView

/// 頂部書籍主要資訊區塊
struct BookInfoView: View {
    let detail: BookDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.title)
                .font(.largeTitle).bold()
                .multilineTextAlignment(.leading)
            
            Text("作者: \(detail.author)")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Divider().padding(.vertical, 8)
            
            InfoRow(label: "出版商", value: detail.publisher)
            InfoRow(label: "出版年份", value: String(detail.publishYear))
            InfoRow(label: "ISBN", value: detail.isbn ?? "N/A")
        }
    }
}

/// 書籍簡介區塊
struct BookDescriptionView: View {
    let detail: BookDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("書籍簡介")
                .font(.title3).bold()
            Text(detail.description ?? "暫無詳細描述。")
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(5)
        }
    }
}

///// 書籍副本與借閱按鈕區塊
//struct BookCopiesView: View {
//    let detail: BookDetail
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("借閱狀況")
//                .font(.title3).bold()
//            
//            // 副本列表
//            VStack(alignment: .leading) {
//                ForEach(detail.bookCopies) { copy in
//                    HStack {
//                        Circle()
//                            .fill(copy.statusDescription == "可借閱" ? .green : .red)
//                            .frame(width: 8, height: 8)
//                        Text("書籍編號: \(copy.uniqueCode) - 狀態: \(copy.statusDescription)")
//                    }
//                    .font(.footnote)
//                }
//            }
//            
//            // 借閱按鈕
//            Button(action: {
//                // TODO: 實現借閱邏輯
//                print("Borrow button tapped for \(detail.title)")
//            }) {
//                Text(detail.availableCopies > 0 ? "借閱此書 (剩餘: \(detail.availableCopies))" : "暫無可借閱副本")
//                    .fontWeight(.bold)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(detail.availableCopies > 0 ? Color.indigo : Color.gray)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
//            .disabled(detail.availableCopies <= 0)
//        }
//    }
//}

struct BookCopiesView: View {
    let detail: BookDetail
    let onBorrow: () -> Void // **(修改)** 新增一個閉包來處理按鈕點擊
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("借閱狀況")
                .font(.title2).bold()
            
            VStack(alignment: .leading) {
                ForEach(detail.bookCopies) { copy in
                    HStack {
                        Circle()
                            .fill(copy.statusDescription == "可借閱" ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text("書籍編號: \(copy.uniqueCode) - 狀態: \(copy.statusDescription)")
                    }
                    .font(.footnote)
                }
            }
            Button(action: onBorrow) { // **(修改)** 呼叫傳入的閉包
                Text(detail.availableCopies > 0 ? "借閱此書 (剩餘: \(detail.availableCopies))" : "暫無可借閱副本")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(detail.availableCopies > 0 ? Color.indigo : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(detail.availableCopies <= 0)
        }
    }
}


// MARK: - Preview

#Preview {
    // 將 NavigationStack 包在外面，才能正確預覽標題
    NavigationStack {
        // 預覽時需要提供一個 bookId
        BookDetailView(bookId: 1)
    }
    .environment(AuthenticationManager())
}
