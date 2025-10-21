//
//  StatsAllViewModel.swift
//  LibrarySwift
//
//  Created by 謝依晴 on 2025/10/21.
//

import Foundation

@MainActor
final class StatsAllViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var loans: [Loan] = []
    @Published var books: [Book] = []

    /// 載入「曾經借過的所有書」= 目前 + 歷史
    func load(userId: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let _current: [Loan] = APIService.shared.fetchCurrentLoans(userId: userId)
            async let _history: [Loan] = APIService.shared.fetchLoanHistory(userId: userId)
            async let _books: [Book] = APIService.shared.fetchBooks(categoryId: nil, searchTerm: nil)

            let (current, history, books) = try await (_current, _history, _books)
            self.books = books

            // 合併 & 去重（以 loanId 為 key），並依借閱日期由新到舊排序
            let merged = Dictionary(grouping: current + history, by: { $0.loanId })
                .compactMap { $0.value.first }
                .sorted { $0.loanDate > $1.loanDate }

            self.loans = merged
        } catch {
            self.errorMessage = String(describing: error)
        }
    }
}
