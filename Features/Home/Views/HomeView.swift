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
    @State private var isMenuPresented = false // **(新增)** 控制滑出選單的狀態

    
    var body: some View {
        NavigationStack {
            // **(修改)** 使用 ZStack 來疊加主內容和滑出選單
            ZStack(alignment: .leading) {
                // 主內容區域
                mainContent
                
                // 滑出選單
                if isMenuPresented {
                    // 半透明背景，點擊可關閉選單
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                isMenuPresented = false
                            }
                        }
                    
                    // 分類列表選單
                    CategoryListView(
                        categories: viewModel.categories,
                        selectedCategoryId: $viewModel.selectedCategoryId
                    )
                    .frame(width: 250)
                    .background(Color(.systemBackground)) // 適應深淺色模式的背景
                    .transition(.move(edge: .leading)) // 從左側滑入的動畫
                    .onDisappear {
                        // 當選單關閉時，確保 isMenuPresented 狀態正確
                        if isMenuPresented {
                            isMenuPresented = false
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline) // 設定為 inline 以便自訂標題
            .toolbar {
                // **(修改)** 自訂頂部工具列
                ToolbarItem(placement: .navigationBarLeading) {
                    menuButton
                }
                
                ToolbarItem(placement: .principal) {
                    titleAndLoginButton
                }
            }
        }
        .searchable(text: $viewModel.searchTerm, prompt: "尋找書籍")
        .onSubmit(of: .search) {
            viewModel.performSearch()
        }
        .sheet(isPresented: $isShowingLoginSheet) {
            LoginView()
                .environment(authManager)
        }
    }
    

    /// 主要內容視圖 (書籍網格)
    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.viewState {
        case .loading:
            ProgressView("載入中...")
        case .error(let errorMessage):
            Text(errorMessage)
        case .content:
            BookGridView(books: viewModel.books)
        }
    }
    
    /// 左上角的選單按鈕
    private var menuButton: some View {
        Button {
            withAnimation(.easeInOut) {
                isMenuPresented.toggle()
            }
        } label: {
            Image(systemName: "line.3.horizontal")
        }
    }
    
    /// 中間的標題和右側的登入/登出按鈕
    private var titleAndLoginButton: some View {
        HStack {
            Text("日比野線上圖書館")
                .font(.headline)
            
            Spacer()
            
            if authManager.loggedInUser != nil {
                // 已登入：顯示使用者名稱和登出按鈕
                Menu {
                    Button("登出", role: .destructive) { authManager.logout() }
                } label: {
                    HStack {
                        Text(authManager.loggedInUser?.name ?? "使用者")
                        Image(systemName: "person.circle.fill")
                    }
                }
            } else {
                // 未登入：顯示登入按鈕
                Button("登入") { isShowingLoginSheet = true }
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
            // 圖片預留區
            // **(修改)** 使用我們新的 AsyncImageView
            AsyncImageView(urlString: book.imageUrl)
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
                .clipped()
            
            // 頂部資訊：書名和作者
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(book.publisher)
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
