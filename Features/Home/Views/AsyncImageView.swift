//
//  AsyncImageView.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import SwiftUI

/// 一個可重用的視圖，用於從 URL 非同步載入並顯示圖片。
/// 它會處理載入中、成功和失敗的狀態。
struct AsyncImageView: View {
    let urlString: String?
    
    var body: some View {
        // 使用 Swift 5.5+ 內建的 AsyncImage，這是處理網路圖片的最佳方式
        AsyncImage(url: URL(string: urlString ?? "")) { phase in
            switch phase {
            case .empty:
                // 圖片尚未開始載入時，顯示一個進度指示器
                Image(systemName: "book.closed.fill")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            case .success(let image):
                // 圖片成功載入，顯示圖片
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure:
                // 圖片載入失敗，顯示預設圖示
                placeholderIcon
            @unknown default:
                // 未來可能出現的其他狀態，同樣顯示預設圖示
                placeholderIcon
            }
        }
    }
    
    /// 預設的佔位圖示
    private var placeholderIcon: some View {
        Image(systemName: "book.closed.fill")
            .font(.largeTitle)
            .foregroundColor(.secondary)
    }
}
