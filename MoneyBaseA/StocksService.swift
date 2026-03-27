//
//  MoneyBaseATests.swift
//  MoneyBaseATests
//
//  Created by APPLE on 3/27/26.
//

import Foundation

protocol StockServicing {
    func fetchStocks(region: String) async throws -> [Stock]
    func fetchStockDetail(symbol: String, region: String) async throws -> StockDetail
}

struct StockService: StockServicing {
    private let networkManager: NetworkManaging

    init(networkManager: NetworkManaging) {
        self.networkManager = networkManager
    }

    func fetchStocks(region: String = "US") async throws -> [Stock] {
        let endpoint = Endpoint(
            path: "market/v2/get-summary",
            queryItems: [URLQueryItem(name: "region", value: region)]
        )
        let response: MarketSummaryResponse = try await networkManager.request(endpoint)
        let result = response.marketSummaryAndSpark?.result ?? []
        return result.compactMap(Stock.from(dto:)).sorted { $0.symbol < $1.symbol }
    }

    func fetchStockDetail(symbol: String, region: String = "US") async throws -> StockDetail {
        let endpoint = Endpoint(
            path: "stock/v2/get-summary",
            queryItems: [
                URLQueryItem(name: "symbol", value: symbol),
                URLQueryItem(name: "region", value: region)
            ]
        )
        let response: StockSummaryResponse = try await networkManager.request(endpoint)
        return StockDetail.from(response: response, fallbackSymbol: symbol)
    }
}
