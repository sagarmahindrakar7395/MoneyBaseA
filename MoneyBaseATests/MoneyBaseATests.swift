//
//  MoneyBaseATests.swift
//  MoneyBaseATests
//
//  Created by APPLE on 3/27/26.
//

import Foundation
import XCTest
@testable import MoneyBaseA

final class MoneyBaseATests: XCTestCase {
    override func tearDown() {
        URLProtocolMock.requestHandler = nil
        super.tearDown()
    }

    func testNetworkManagerDecodesResponse() async throws {
        let payload = """
        {
          "marketSummaryAndSpark": {
            "result": [
              {
                "symbol": "AAPL",
                "shortName": "Apple Inc.",
                "fullExchangeName": "NasdaqGS",
                "regularMarketPrice": { "raw": 173.5, "fmt": "173.50" },
                "regularMarketChangePercent": { "raw": 1.15, "fmt": "+1.15%" }
              }
            ]
          }
        }
        """.data(using: .utf8)!

        URLProtocolMock.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-RapidAPI-Host"), "yh-finance.p.rapidapi.com")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, payload)
        }

        let manager = makeNetworkManager()
        let endpoint = Endpoint(path: "market/v2/get-summary", queryItems: [URLQueryItem(name: "region", value: "US")])
        let response: MarketSummaryResponse = try await manager.request(endpoint)

        XCTAssertEqual(response.marketSummaryAndSpark?.result.first?.symbol, "AAPL")
    }

    func testStockServiceMapsStocks() async throws {
        let payload = """
        {
          "marketSummaryAndSparkResponse": {
            "result": [
              {
                "symbol": "AAPL",
                "shortName": "Apple Inc.",
                "fullExchangeName": "NasdaqGS",
                "regularMarketPrice": { "raw": 173.5, "fmt": "173.50" },
                "regularMarketPreviousClose": { "raw": 170.0, "fmt": "170.00" }
              },
              {
                "symbol": "MSFT",
                "shortName": "Microsoft",
                "fullExchangeName": "NasdaqGS",
                "regularMarketPrice": { "raw": 410.0, "fmt": "410.00" },
                "regularMarketChangePercent": { "raw": -0.44, "fmt": "-0.44%" }
              }
            ]
          }
        }
        """.data(using: .utf8)!

        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, payload)
        }

        let service = StockService(networkManager: makeNetworkManager())
        let stocks = try await service.fetchStocks(region: "US")

        XCTAssertEqual(stocks.count, 2)
        XCTAssertEqual(stocks.first?.symbol, "AAPL")
        XCTAssertEqual(stocks.first?.changePercentValue ?? 0, 2.058, accuracy: 0.01)
        XCTAssertEqual(stocks.last?.changePercentValue ?? 0.0, -0.44, accuracy: 0.001)
    }

    func testStockServiceMapsDetailFromQuoteSummaryWrapper() async throws {
        let payload = """
        {
          "quoteSummary": {
            "result": [
              {
                "price": {
                  "symbol": "AAPL",
                  "shortName": "Apple Inc.",
                  "regularMarketPrice": { "raw": 173.5, "fmt": "173.50" },
                  "regularMarketPreviousClose": { "raw": 170.0, "fmt": "170.00" }
                },
                "summaryDetail": {
                  "previousClose": { "raw": 170.0, "fmt": "170.00" },
                  "open": { "raw": 171.0, "fmt": "171.00" },
                  "dayLow": { "raw": 169.5, "fmt": "169.50" },
                  "dayHigh": { "raw": 174.1, "fmt": "174.10" },
                  "volume": { "raw": 2000000, "fmt": "2M" }
                }
              }
            ]
          }
        }
        """.data(using: .utf8)!

        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, payload)
        }

        let service = StockService(networkManager: makeNetworkManager())
        let detail = try await service.fetchStockDetail(symbol: "AAPL", region: "US")

        XCTAssertEqual(detail.symbol, "AAPL")
        XCTAssertEqual(detail.displayName, "Apple Inc.")
        XCTAssertEqual(detail.priceText, "173.50")
        XCTAssertEqual(detail.changePercentText, "+2.06%")
        XCTAssertEqual(detail.dayRangeText, "169.50 - 174.10")
        XCTAssertEqual(detail.volumeText, "2M")
    }

    @MainActor
    func testStocksListViewModelFiltersByNameAndSymbol() async {
        let service = MockStockService(
            stocksToReturn: [
                Stock(symbol: "AAPL", name: "Apple Inc.", exchange: "Nasdaq", priceText: "173.50", changePercentText: "+1.15%", changePercentValue: 1.15),
                Stock(symbol: "MSFT", name: "Microsoft", exchange: "Nasdaq", priceText: "410.00", changePercentText: "-0.44%", changePercentValue: -0.44)
            ]
        )
        let viewModel = StocksListViewModel(service: service)

        await viewModel.loadStocks()
        XCTAssertEqual(viewModel.filteredStocks.count, 2)

        viewModel.searchText = "apple"
        XCTAssertEqual(viewModel.filteredStocks.map(\.symbol), ["AAPL"])

        viewModel.searchText = "msf"
        XCTAssertEqual(viewModel.filteredStocks.map(\.symbol), ["MSFT"])
    }

    @MainActor
    func testStocksListViewModelPublishesErrorWhenLoadFails() async {
        let service = MockStockService(stocksToReturn: [], errorToThrow: NetworkError.httpStatus(500))
        let viewModel = StocksListViewModel(service: service)

        await viewModel.loadStocks()
        XCTAssertTrue(viewModel.stocks.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    private func makeNetworkManager() -> NetworkManager {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: config)
        let apiConfig = APIConfiguration.default
        return NetworkManager(session: session, configuration: apiConfig)
    }
}

private struct MockStockService: StockServicing {
    let stocksToReturn: [Stock]
    var errorToThrow: Error?

    func fetchStocks(region: String) async throws -> [Stock] {
        if let errorToThrow {
            throw errorToThrow
        }
        return stocksToReturn
    }

    func fetchStockDetail(symbol: String, region: String) async throws -> StockDetail {
        StockDetail(
            symbol: symbol,
            displayName: symbol,
            priceText: "100",
            changePercentText: "0%",
            previousCloseText: "99",
            openText: "100",
            dayRangeText: "98 - 101",
            volumeText: "1M"
        )
    }
}

private final class URLProtocolMock: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = URLProtocolMock.requestHandler else {
            XCTFail("Missing request handler.")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
