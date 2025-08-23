//
//  LoginView.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import SwiftUI

struct LoginView: View {
    
    @Environment(AuthenticationManager.self) private var authManager
    @State private var viewModel: AuthViewModel
    
    /// 用於關閉當前視圖 (sheet)
    @Environment(\.dismiss) private var dismiss
    
    init() {
        // _viewModel 的初始化需要在 init 中完成，因為它依賴於 authManager
        // 但由於 authManager 是從 @Environment 來的，我們需要一個技巧
        // 這裡我們先給一個暫時的，真正的會在 .onAppear 中注入
        _viewModel = State(initialValue: AuthViewModel(authManager: AuthenticationManager()))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                Text("登入")
                    .font(.largeTitle).bold()
                
                TextField("帳號", text: $viewModel.account)
                    .textContentType(.username)
                    .keyboardType(.asciiCapable)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                SecureField("密碼", text: $viewModel.password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                if let error = viewModel.loginError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    Task {
                        let success = await viewModel.login()
                        if success {
                            dismiss() // 登入成功後關閉 sheet
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("登入")
                    }
                }
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.indigo)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(viewModel.isLoading)
                
                // **(修改)** 將文字改為 NavigationLink
                NavigationLink(destination: RegisterView()) {
                    Text("還沒有帳號？加入會員")
                        .foregroundColor(.indigo)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button("取消") { dismiss() })
            .onAppear {
                // 當 View 出現時，才從 Environment 獲取 authManager 並正確初始化 viewModel
                self.viewModel = AuthViewModel(authManager: authManager)
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthenticationManager())
}
