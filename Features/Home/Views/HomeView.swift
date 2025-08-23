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
    @State private var isSearchPresented = false // **(新增)** 控制搜尋框的顯示狀態

    
    var body: some View {
            NavigationStack {
                VStack(spacing: 0) {
                    // **(新增)** 條件式顯示的搜尋框
                    if isSearchPresented {
                        SearchBarView(searchTerm: $viewModel.searchTerm) {
                            viewModel.performSearch()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    
                    // **(修改)** 使用 ZStack 來疊加主內容和滑出選單
                    ZStack(alignment: .leading) {
                        // 主內容區域
                        mainContent
                        
                        // 滑出選單
                        if isMenuPresented {
                            Group{
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
                                    selectedCategoryId: $viewModel.selectedCategoryId,
                                    onCategorySelected: {
                                        // 當使用者選擇一個分類後，自動關閉選單
                                        withAnimation(.easeInOut) {
                                            isMenuPresented = false
                                        }
                                    }
                                )
                                .frame(width: 140)
                                .background(Color(.systemBackground)) // 適應深淺色模式的背景
                                .transition(.move(edge: .leading)) // 從左側滑入的動畫
                                .onDisappear {
                                    // 當選單關閉時，確保 isMenuPresented 狀態正確
                                    if isMenuPresented {
                                        isMenuPresented = false
                                    }
                                }
                            }
                            // **(修正)** 為選單的容器加上 zIndex，確保它總是在最上層
                            .zIndex(1)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline) // 設定為 inline 以便自訂標題
                .toolbar {
                    // 自訂頂部工具列
                    ToolbarItem(placement: .navigationBarLeading) {
                        menuButton
                    }
                    
                    ToolbarItem(placement: .principal) {
                        titleText
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        trailingButtons
                    }
                }
            }
            // **(移除)** .searchable 修飾符，改為手動控制
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
    
    /// 中間的標題
    private var titleText: some View {
        Text("日比野線上圖書館")
            .font(.headline)
    }
    
    /// 右側的按鈕集合 (搜尋 + 登入/登出)
    private var trailingButtons: some View {
        HStack {
            Button {
                withAnimation(.easeInOut) {
                    isSearchPresented.toggle()
                }
            } label: {
                Image(systemName: "magnifyingglass")
            }
            
            if authManager.loggedInUser != nil {
                Menu {
                    Button("登出", role: .destructive) { authManager.logout() }
                } label: {
                    Image(systemName: "person.circle.fill")
                }
            } else {
                Button("登入") { isShowingLoginSheet = true }
            }
        }
    }
    
}

// MARK: - Subviews (將 UI 拆分為更小的元件，方便管理)

/// **(新增)** 獨立的搜尋框元件
struct SearchBarView: View {
    @Binding var searchTerm: String
    var onSearch: () -> Void
    
    var body: some View {
        HStack {
            TextField("尋找書籍...", text: $searchTerm)
                .textFieldStyle(.roundedBorder)
                .onSubmit(onSearch) // 當按下鍵盤 return/search 時
            
            Button("搜尋", action: onSearch)
                .buttonStyle(.borderedProminent)
        }
    }
}

// **(修改)** 重新加入並修正 CategoryListView
struct CategoryListView: View {
    let categories: [Category]
    @Binding var selectedCategoryId: Int?
    var onCategorySelected: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("書籍分類")
                .font(.title2.bold())
                .padding([.horizontal, .top])

            List {
                // "所有書籍" 按鈕
                Button(action: {
                    // 只有在當前選擇不是 "所有書籍" 時才更新狀態
                    if selectedCategoryId != nil {
                        selectedCategoryId = nil
                    }
                    onCategorySelected()
                }) {
                    HStack {
                        Text("所有書籍")
                            .foregroundColor(selectedCategoryId == nil ? .accentColor : .primary)
                    }
                }
                .buttonStyle(.plain)

                // 其他分類按鈕
                ForEach(categories) { category in
                    Button(action: {
                        if selectedCategoryId != category.id {
                            selectedCategoryId = category.id
                        }
                        onCategorySelected()
                    }) {
                        HStack {
                            Text(category.title)
                                .foregroundColor(selectedCategoryId == category.id ? .accentColor : .primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
        }
    }
}

/// 書籍網格
struct BookGridView: View {
    let books: [Book]
    // 定義網格佈局：自適應寬度，最小 160
    private let columns = [ GridItem(.adaptive(minimum: 160), spacing: 16) ]
    
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
        VStack(alignment: .leading) {
            // **(修改)** 使用我們新的 AsyncImageView
            AsyncImageView(urlString: book.imageUrl)
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
                .clipped()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.headline)
                // **(修改)** 加入 reservesSpace: true 參數
                .lineLimit(2, reservesSpace: true)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(book.publisher)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 底部資訊：分類和館藏狀態
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
            .padding(/*[.horizontal, .bottom]*/6)
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// 這個預覽區塊可以讓你在 Xcode 中即時看到 UI 效果，非常方便
#Preview {
    HomeView()
}
