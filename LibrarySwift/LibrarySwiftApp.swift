//
//  LibrarySwiftApp.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import SwiftUI
import SwiftData

@main
struct LibrarySwiftApp: App {
    
    /// 創建一個 AuthenticationManager 的實例，作為整個 App 的全局狀態。
    @State private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                // 使用 .environment 將 authManager 注入到整個 App 的視圖層級中
                .environment(authManager)
        }
    }
}

