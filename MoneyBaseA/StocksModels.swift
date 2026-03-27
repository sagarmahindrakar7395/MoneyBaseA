//
//  MoneyBaseATests.swift
//  MoneyBaseATests
//
//  Created by APPLE on 3/27/26.
//

import Foundation

struct MarketSummaryResponse: Decodable {
    let marketSummaryAndSpark: MarketSummaryContainer?

    private enum CodingKeys: String, CodingKey {
        case marketSummaryAndSpark
        case marketSummaryAndSparkResponse
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // API can return either key depending on endpoint/revision.
        self.marketSummaryAndSpark =
            try container.decodeIfPresent(MarketSummaryContainer.self, forKey: .marketSummaryAndSpark)
            ?? container.decodeIfPresent(MarketSummaryContainer.self, forKey: .marketSummaryAndSparkResponse)
    }
}

struct MarketSummaryContainer: Decodable {
    let result: [MarketStockDTO]
}

struct MarketStockDTO: Decodable {
    let symbol: String?
    let shortName: String?
    let fullExchangeName: String?
    let regularMarketPrice: QuoteValue?
    let regularMarketChangePercent: QuoteValue?
    let regularMarketPreviousClose: QuoteValue?
}

struct StockSummaryResponse: Decodable {
    let price: PriceDTO?
    let summaryDetail: SummaryDetailDTO?

    private enum CodingKeys: String, CodingKey {
        case price
        case summaryDetail
        case quoteSummary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let directPrice = try container.decodeIfPresent(PriceDTO.self, forKey: .price)
        let directSummary = try container.decodeIfPresent(SummaryDetailDTO.self, forKey: .summaryDetail)

        if directPrice != nil || directSummary != nil {
            self.price = directPrice
            self.summaryDetail = directSummary
            return
        }

        let wrapper = try container.decodeIfPresent(QuoteSummaryWrapper.self, forKey: .quoteSummary)
        let first = wrapper?.result.first
        self.price = first?.price
        self.summaryDetail = first?.summaryDetail
    }
}

struct PriceDTO: Decodable {
    let symbol: String?
    let shortName: String?
    let longName: String?
    let regularMarketPrice: QuoteValue?
    let regularMarketChangePercent: QuoteValue?
    let regularMarketPreviousClose: QuoteValue?
}

struct SummaryDetailDTO: Decodable {
    let previousClose: QuoteValue?
    let open: QuoteValue?
    let dayLow: QuoteValue?
    let dayHigh: QuoteValue?
    let volume: QuoteValue?
}

struct QuoteValue: Decodable {
    let raw: Double?
    let fmt: String?
}

private struct QuoteSummaryWrapper: Decodable {
    let result: [QuoteSummaryResult]
}

private struct QuoteSummaryResult: Decodable {
    let price: PriceDTO?
    let summaryDetail: SummaryDetailDTO?
}

struct Stock: Identifiable, Equatable {
    let symbol: String
    let name: String
    let exchange: String
    let priceText: String
    let changePercentText: String
    let changePercentValue: Double

    var id: String { symbol }
}

struct StockDetail: Equatable {
    let symbol: String
    let displayName: String
    let priceText: String
    let changePercentText: String
    let previousCloseText: String
    let openText: String
    let dayRangeText: String
    let volumeText: String
}

extension Stock {
    static func from(dto: MarketStockDTO) -> Stock? {
        guard let symbol = dto.symbol, !symbol.isEmpty else { return nil }
        let name = dto.shortName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let exchange = dto.fullExchangeName ?? "-"
        let priceText = dto.regularMarketPrice?.fmt ?? "-"
        let changeValue: Double = {
            if let provided = dto.regularMarketChangePercent?.raw {
                return provided
            }
            guard
                let current = dto.regularMarketPrice?.raw,
                let previous = dto.regularMarketPreviousClose?.raw,
                previous != 0
            else {
                return 0
            }
            return ((current - previous) / previous) * 100
        }()

        let changeText = dto.regularMarketChangePercent?.fmt ?? percentString(from: changeValue)

        return Stock(
            symbol: symbol,
            name: (name?.isEmpty == false ? name! : symbol),
            exchange: exchange,
            priceText: priceText,
            changePercentText: changeText,
            changePercentValue: changeValue
        )
    }

    static func percentString(from value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, value)
    }
}

extension StockDetail {
    static func from(response: StockSummaryResponse, fallbackSymbol: String) -> StockDetail {
        let price = response.price
        let summary = response.summaryDetail

        let symbol = price?.symbol ?? fallbackSymbol
        let name = price?.longName ?? price?.shortName ?? symbol
        let priceText = price?.regularMarketPrice?.fmt ?? "-"
        let changePercentValue: Double = {
            if let provided = price?.regularMarketChangePercent?.raw {
                return provided
            }
            guard
                let current = price?.regularMarketPrice?.raw,
                let previous = price?.regularMarketPreviousClose?.raw,
                previous != 0
            else {
                return 0
            }
            return ((current - previous) / previous) * 100
        }()
        let changePercentText = price?.regularMarketChangePercent?.fmt ?? Stock.percentString(from: changePercentValue)
        let previousCloseText = summary?.previousClose?.fmt ?? "-"
        let openText = summary?.open?.fmt ?? "-"
        let low = summary?.dayLow?.fmt ?? "-"
        let high = summary?.dayHigh?.fmt ?? "-"
        let volumeText = summary?.volume?.fmt ?? "-"

        return StockDetail(
            symbol: symbol,
            displayName: name,
            priceText: priceText,
            changePercentText: changePercentText,
            previousCloseText: previousCloseText,
            openText: openText,
            dayRangeText: "\(low) - \(high)",
            volumeText: volumeText
        )
    }
}
