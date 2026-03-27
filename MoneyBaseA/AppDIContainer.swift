//
//  MoneyBaseATests.swift
//  MoneyBaseATests
//
//  Created by APPLE on 3/27/26.
//

import Foundation

@MainActor
struct AppDIContainer {
    private let networkManager: NetworkManaging
    private let stockService: StockServicing

    init() {
        let session = URLSession(configuration: .default)
        let config = APIConfiguration.default
        self.networkManager = NetworkManager(session: session, configuration: config)
        self.stockService = StockService(networkManager: networkManager)
    }

    init(networkManager: NetworkManaging, stockService: StockServicing) {
        self.networkManager = networkManager
        self.stockService = stockService
    }

    func makeStocksListViewModel() -> StocksListViewModel {
        StocksListViewModel(service: stockService)
    }
}
