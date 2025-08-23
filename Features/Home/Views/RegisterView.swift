//
//  RegisterView.swift
//  LibrarySwift
//
//  Created by 訪客使用者 on 2025/8/23.
//

import SwiftUI

struct RegisterView: View {
    
    @State private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // 表單輸入欄位
                FormInputSection(
                    account: $viewModel.account,
                    password: $viewModel.password,
                    confirmPassword: $viewModel.confirmPassword,
                    name: $viewModel.name,
                    email: $viewModel.email,
                    phone: $viewModel.phone,
                    address: $viewModel.address,
                    passwordMismatch: viewModel.passwordMismatch
                )
                
                // 顯示註冊訊息
                if let message = viewModel.registrationMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(viewModel.isSuccess ? .green : .red)
                        .multilineTextAlignment(.center)
                }
                
                // 註冊按鈕
                Button(action: {
                    Task {
                        await viewModel.register()
                        // 如果註冊成功，延遲一下再返回登入頁
                        if viewModel.isSuccess {
                            try? await Task.sleep(for: .seconds(2))
                            dismiss()
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("註冊")
                    }
                }
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isFormValid ? Color.indigo : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
                
            }
            .padding()
        }
        .navigationTitle("加入會員")
        .navigationBarTitleDisplayMode(.large)
    }
}

/// 將表單欄位拆分成子視圖，讓程式碼更清晰
private struct FormInputSection: View {
    @Binding var account: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var name: String
    @Binding var email: String
    @Binding var phone: String
    @Binding var address: String
    let passwordMismatch: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("帳號*", text: $account)
                .textContentType(.username)
                .autocapitalization(.none)
            
            SecureField("密碼* (至少6位數)", text: $password)
                .textContentType(.newPassword)
            
            SecureField("確認密碼*", text: $confirmPassword)
                .textContentType(.newPassword)
            
            if passwordMismatch {
                Text("兩次輸入的密碼不一致。")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Divider().padding(.vertical, 8)
            
            TextField("姓名*", text: $name)
                .textContentType(.name)
            
            TextField("電子郵件*", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
            
            TextField("電話", text: $phone)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
            
            TextField("地址", text: $address)
                .textContentType(.fullStreetAddress)
        }
        .textFieldStyle(.roundedBorder)
    }
}

#Preview {
    NavigationStack {
        RegisterView()
    }
}
