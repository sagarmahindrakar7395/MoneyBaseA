//
//  MoneyBaseATests.swift
//  MoneyBaseATests
//
//  Created by APPLE on 3/27/26.
//

import SwiftUI

struct StocksListView: View {
    @StateObject private var viewModel: StocksListViewModel

    init(viewModel: StocksListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.stocks.isEmpty {
                    ProgressView("Loading stocks...")
                } else if let errorMessage = viewModel.errorMessage, viewModel.stocks.isEmpty {
                    ContentUnavailableView("Unable to Load Stocks", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                } else {
                    List(viewModel.filteredStocks) { stock in
                        NavigationLink {
                            StockDetailView(stock: stock)
                        } label: {
                            StockRowView(stock: stock)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Market Summary")
            .searchable(text: $viewModel.searchText, prompt: "Search by name or symbol")
            .refreshable {
                await viewModel.loadStocks()
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

private struct StockRowView: View {
    let stock: Stock

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbol)
                    .font(.headline)
                Text(stock.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(stock.priceText)
                    .font(.headline)
                Text(stock.changePercentText)
                    .font(.subheadline)
                    .foregroundStyle(stock.changePercentValue >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}
