//
//  MainView.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//
// 一個新的根視圖 MainView 來管理整個 App 的狀態。

import SwiftUI

/// App 的根視圖，負責管理主介面 (TabView) 和全局覆蓋層 (滑出式選單)。
struct MainView: View {
    
    @Environment(AuthenticationManager.self) private var authManager
    
    // ViewModel 現在只保留 homeViewModel，因為它總是存在
    @State private var homeViewModel = HomeViewModel()
    // **(核心修改)** myPageViewModel 設為可選，只在登入後才由 .onChange 創建
    @State private var myPageViewModel: MyPageViewModel?
    
    enum Tab {
        case home, myPage
    }
    @State private var selectedTab: Tab = .home
    @State private var isMenuPresented = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            TabView(selection: $selectedTab) {
                HomeView(viewModel: homeViewModel, isMenuPresented: $isMenuPresented)
                    .tabItem {
                        Label("首頁", systemImage: "house.fill")
                    }
                    .tag(Tab.home)
                
                // **(核心修改)** 根據登入狀態，顯示 MyPageView 或提示
                if authManager.loggedInUser != nil, let myPageViewModel = myPageViewModel {
                    // 只有在 user 和 viewModel 都存在時，才創建 MyPageView
                    MyPageView(viewModel: myPageViewModel, isMenuPresented: $isMenuPresented)
                        .tabItem {
                            Label("個人頁面", systemImage: "person.fill")
                        }
                        .tag(Tab.myPage)
                } else {
                    // 未登入時的提示畫面
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("請先登入")
                            .font(.title2)
                    }
                    .tabItem {
                        Label("個人頁面", systemImage: "person.fill")
                    }
                    .tag(Tab.myPage)
                }
            }
            
            // ✅ **【核心修正】** 將覆蓋層和選單內容分開處理
            if isMenuPresented {
                // 2. 半透明黑色覆蓋層
                //    - 它現在可以自由延伸到整個螢幕，不再受 frame 限制
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity) // 使用淡入淡出效果，體驗更好
                    .onTapGesture {
                        closeMenu() // 點擊此區域時關閉選單
                    }

                // 3. 選單內容
                //    - 將其保持在 ZStack 的最上層
                //    - 保持其固定的 250 寬度
                menuContent
                    .frame(width: 140)
                    .background(Color(.systemBackground))
                    .transition(.move(edge: .leading)) // 保持滑入效果
            }
        }
        // **(核心修改)** 使用 onChange 監聽登入狀態的變化，這是管理 ViewModel 生命週期的最佳方式
        .onChange(of: authManager.loggedInUser) {
            if authManager.loggedInUser != nil {
                // 當使用者登入時，創建 MyPageViewModel
                myPageViewModel = MyPageViewModel(authManager: authManager)
            } else {
                // 當使用者登出時，銷毀 MyPageViewModel
                myPageViewModel = nil
                // 並確保使用者被導回首頁
                selectedTab = .home
            }
        }
    }
    
    /// **(新增)** 將選單內容提取為獨立的計算屬性，讓 body 更清晰
    @ViewBuilder
    private var menuContent: some View {
        // 根據當前選擇的標籤頁，顯示對應選單
        if selectedTab == .home {
            CategoryListView(
                categories: homeViewModel.categories,
                selectedCategoryId: $homeViewModel.selectedCategoryId,
                onCategorySelected: closeMenu
            )
        } else if let myPageViewModel = myPageViewModel {
            // 直接綁定到 MainView 持有的 myPageViewModel 實例，確保狀態同步
            FunctionListView(
                selectedFunction: Binding(
                    get: { myPageViewModel.selectedFunction },
                    set: { myPageViewModel.selectedFunction = $0 }
                ),
                onFunctionSelected: closeMenu
            )
        }
    }
    
    private func closeMenu() {
        withAnimation(.easeInOut) {
            isMenuPresented = false
        }
    }
}

#Preview {
    MainView()
        .environment(AuthenticationManager())
}
