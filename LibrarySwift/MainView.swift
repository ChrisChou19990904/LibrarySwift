//
//  MainView.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//
// 一個新的根視圖 MainView 來管理整個 App 的狀態。

import SwiftUI

/// App 的根視圖，負責管理主介面 (如 TabView)。
struct MainView: View {
    
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        // TabView 作為 App 的主要導航結構
        TabView {
            HomeView()
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }
            
            // 根據登入狀態決定是否顯示個人頁面
            if authManager.loggedInUser != nil {
                // TODO: 建立 MyPageView
                Text("個人頁面")
                    .tabItem {
                        Label("個人頁面", systemImage: "person.fill")
                    }
            } else {
                // 未登入時，可以顯示一個提示登入的頁面
                VStack {
                    Text("請先登入以查看個人頁面")
                    // 可以放一個登入按鈕在這裡
                }
                .tabItem {
                    Label("個人頁面", systemImage: "person.fill")
                }
            }
        }
    }
}

#Preview {
    MainView()
        .environment(AuthenticationManager())
}
