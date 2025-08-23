//
//  LibrarySwiftApp.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//
// 我們希望整個 App 共享唯一一個 AuthenticationManager 實例，作為登入狀態的「單一事實來源 (Single Source of Truth)」。
// 這個實例被創建和注入的地方在 OnlineLibraryApp.swift，也就是 App 的最頂層入口：

import SwiftUI
import SwiftData

@main
struct LibrarySwiftApp: App {
    
    /// 創建一個 且唯一的 AuthenticationManager 的實例，作為整個 App 的全局狀態。
    /// 使用 @State 確保它的生命週期由 SwiftUI 管理
    @State private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                // 透過 .environment() 修飾符 將 authManager 注入到整個 App 的視圖層級中 aka 環境 (Environment)
                // 這樣一來，MainView 以及它所有的子視圖都能存取到同一個 authManager
                // 任何需要知道登入狀態的子視圖（例如您在 LoginView 中看到的），都可以使用 @Environment(AuthenticationManager.self) 來輕鬆地讀取這同一個共享的實例。
                // 這個方法是 Apple 官方推薦的最佳實踐，它確保了狀態的一致性，並避免了需要手動將 authManager 一層一層地傳遞給每個子視圖的麻煩。
                .environment(authManager)
        }
    }
}

