//
//  MoneyBaseATests.swift
//  MoneyBaseATests
//
//  Created by APPLE on 3/27/26.
//

import Foundation

@MainActor
final class StocksListViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    var filteredStocks: [Stock] {
        guard !searchText.isEmpty else { return stocks }
        let token = searchText.lowercased()
        return stocks.filter {
            $0.name.lowercased().contains(token) || $0.symbol.lowercased().contains(token)
        }
    }

    private let service: StockServicing
    private var autoRefreshTask: Task<Void, Never>?

    init(service: StockServicing) {
        self.service = service
    }

    func onAppear() {
        if stocks.isEmpty {
            Task { await loadStocks() }
        }
        startAutoRefresh()
    }

    func onDisappear() {
        stopAutoRefresh()
    }

    func loadStocks() async {
        isLoading = stocks.isEmpty
        defer { isLoading = false }

        do {
            stocks = try await service.fetchStocks(region: "US")
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startAutoRefresh() {
        guard autoRefreshTask == nil else { return }
        autoRefreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(8))
                if Task.isCancelled { return }
                await self.loadStocks()
            }
        }
    }

    private func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }
}
