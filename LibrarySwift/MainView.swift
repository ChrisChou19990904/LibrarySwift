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
            
            // **(修改)** 根據登入狀態顯示 MyPageView 或提示登入的頁面
            if authManager.loggedInUser != nil {
                MyPageView()
                    .tabItem {
                        Label("個人頁面", systemImage: "person.fill")
                    }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("請先登入")
                        .font(.title2)
                    Text("登入後即可查看您的借閱紀錄與個人檔案。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .tabItem {
                    Label("個人頁面", systemImage: "person.fill")
                    // **(修改)** 將文字改為 NavigationLink
                    NavigationLink(destination: RegisterView()) {
                        Text("還沒有帳號？加入會員")
                            .foregroundColor(.indigo)
                    }
                }
            }
        }
    }
}

#Preview {
    MainView()
        .environment(AuthenticationManager())
}
