//
//  HomeView.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//
// 核心檔案：
// HomeViewModel.swift: 這是首頁的「大腦」。它負責使用 APIService 去獲取書籍和分類資料，並管理所有 UI 狀態，例如「正在載入」、「載入成功」或「發生錯誤」。
// HomeView.swift: 這是首頁的「臉孔」，也就是您在 index.html 中看到的介面。它會根據 HomeViewModel 提供的資料來顯示分類列表和書籍網格，並提供搜尋功能。
import SwiftUI

struct HomeView: View {
    
    /// 使用 @State 來持有 ViewModel 的實例。
    /// 對於使用 @Observable 宏的物件，@State 是 Apple 推薦的作法。
    @State private var viewModel = HomeViewModel()
    @Environment(AuthenticationManager.self) private var authManager

    /// 控制登入 sheet 是否顯示
    @State private var isShowingLoginSheet = false
    
    var body: some View {
        NavigationStack {
            // 根據 ViewModel 的狀態顯示不同的 UI
            switch viewModel.viewState {
            case .loading:
                ProgressView("載入中...")
                    .scaleEffect(1.5)
                    .navigationTitle("日比野線上圖書館")
                
            case .error(let errorMessage):
                VStack(spacing: 20) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text("載入失敗")
                        .font(.title)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    Button("重試") {
                        Task {
                            await viewModel.initialLoad()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("錯誤")
                
            case .content:
                mainContentView
                    .navigationTitle("日比野線上圖書館")
                    .toolbar {
                        // **(新增)** 頂部工具欄按鈕
                        ToolbarItem(placement: .navigationBarTrailing) {
                            toolbarButton
                        }
                    }
            }
        }
        // 使用 .searchable 修飾符來添加原生搜尋欄
        .searchable(text: $viewModel.searchTerm, prompt: "尋找書籍")
        .onSubmit(of: .search) {
            // 當使用者在鍵盤上按下搜尋時觸發
            viewModel.performSearch()
        }
        // **(新增)** 登入畫面的 sheet
        .sheet(isPresented: $isShowingLoginSheet) {
            LoginView()
                // 將 authManager 傳遞給 sheet 環境
                .environment(authManager)
        }
    }
    
    /// 主內容視圖，包含分類和書籍列表
    private var mainContentView: some View {
        // 使用 HStack 創建左右分欄佈局，類似網頁的 Flexbox
        HStack(alignment: .top, spacing: 0) {
            // 左側：分類列表
            CategoryListView(
                categories: viewModel.categories,
                selectedCategoryId: $viewModel.selectedCategoryId
            )
            .frame(width: 200) // 給予一個固定寬度
            
            Divider()
            
            // 右側：書籍列表
            BookGridView(books: viewModel.books)
        }
    }
    
    /// **(新增)** 根據登入狀態顯示不同的工具欄按鈕
        @ViewBuilder
        private var toolbarButton: some View {
            if authManager.loggedInUser != nil {
                // 已登入：顯示使用者名稱和登出按鈕
                Menu {
                    Button("登出", role: .destructive) {
                        authManager.logout()
                    }
                } label: {
                    HStack {
                        Text(authManager.loggedInUser?.name ?? "使用者")
                        Image(systemName: "person.circle.fill")
                    }
                }
            } else {
                // 未登入：顯示登入按鈕
                Button("登入") {
                    isShowingLoginSheet = true
                }
            }
        }
}

// MARK: - Subviews (將 UI 拆分為更小的元件，方便管理)

/// 左側的分類列表
struct CategoryListView: View {
    let categories: [Category]
    @Binding var selectedCategoryId: Int?
    
    var body: some View {
        // 使用 List 來呈現，並綁定選擇的項目
        List(selection: $selectedCategoryId) {
            // "所有書籍" 選項
            Text("所有書籍").tag(Int?.none)
            
            // 從 API 獲取的分類
            ForEach(categories) { category in
                Text(category.title).tag(Int?.some(category.id))
            }
        }
        .listStyle(.sidebar) // 使用側邊欄風格
    }
}

/// 右側的書籍網格
struct BookGridView: View {
    let books: [Book]
    
    // 定義網格佈局：自適應寬度，最小 250
    private let columns = [ GridItem(.adaptive(minimum: 250), spacing: 16) ]
    
    var body: some View {
            ScrollView {
                if books.isEmpty {
                    Text("目前沒有符合條件的書籍。")
                        .foregroundColor(.secondary)
                        .padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(books) { book in
                            // **(修改)** 使用 NavigationLink 包裝卡片
                            NavigationLink(destination: BookDetailView(bookId: book.id)) {
                                BookCardView(book: book)
                            }
                            .buttonStyle(.plain) // 讓 NavigationLink 不影響卡片內部按鈕的樣式
                        }
                    }
                    .padding()
                }
            }
        }
}

/// 單一本書的卡片視圖
struct BookCardView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 頂部資訊：書名和作者
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(height: 70, alignment: .top) // 固定高度以對齊網格中的項目
            
            Spacer()
            
            // 底部資訊：分類和館藏狀態
            VStack(alignment: .leading, spacing: 4) {
                Text(book.category)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.indigo.opacity(0.1))
                    .foregroundColor(.indigo)
                    .cornerRadius(4)
                
                Text("可借閱: \(book.availableCopies) / 總數: \(book.totalCopies)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // **(修改)** 移除按鈕，因為整個卡片現在都是導航連結
            // 我們將 "查看詳情" 的視覺提示保留，但它不再是一個實際的 Button
            Text("查看詳情")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.indigo)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6)) // 使用系統灰色，會自動適應深色/淺色模式
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// 這個預覽區塊可以讓你在 Xcode 中即時看到 UI 效果，非常方便
#Preview {
    HomeView()
}
