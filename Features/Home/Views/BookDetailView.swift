//
//  BookDetailView.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import SwiftUI

struct BookDetailView: View {
    
    @State private var viewModel: BookDetailViewModel
    
    // MARK: - Initializer
    
    init(bookId: Int) {
        // _viewModel 是對 @State 屬性本身的引用，用於初始化
        _viewModel = State(initialValue: BookDetailViewModel(bookId: bookId))
    }
    
    var body: some View {
        // 根據 ViewModel 的狀態顯示 UI
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        BookHeaderView(detail: detail)
                        BookDescriptionView(detail: detail)
                        BookCopiesView(detail: detail)
                    }
                    .padding()
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
struct BookHeaderView: View {
    let detail: BookDetail
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // 圖片預留區
            Color.gray.opacity(0.3)
                .frame(width: 120, height: 180)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "book.closed.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(detail.title)
                    .font(.title2).bold()
                Text("作者: \(detail.author)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("出版商: \(detail.publisher)")
                Text("出版年份: \(String(detail.publishYear))")
                Text("ISBN: \(detail.isbn ?? "N/A")")
            }
            .font(.subheadline)
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

/// 書籍副本與借閱按鈕區塊
struct BookCopiesView: View {
    let detail: BookDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("借閱狀況")
                .font(.title3).bold()
            
            // 副本列表
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
            
            // 借閱按鈕
            Button(action: {
                // TODO: 實現借閱邏輯
                print("Borrow button tapped for \(detail.title)")
            }) {
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
}
