//
//  MoneyBaseATests.swift
//  MoneyBaseATests
//
//  Created by APPLE on 3/27/26.
//

import SwiftUI

struct StockDetailView: View {
    let stock: Stock

    var body: some View {
        List {
            section(title: "Identity") {
                labeledRow("Symbol", stock.symbol)
                labeledRow("Name", stock.name)
                labeledRow("Exchange", stock.exchange)
            }
            section(title: "Price") {
                labeledRow("Current", stock.priceText)
                HStack {
                    Text("Change %")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(stock.changePercentText)
                        .foregroundStyle(stock.changePercentValue >= 0 ? .green : .red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(stock.symbol)
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        Section(title) {
            content()
        }
    }

    private func labeledRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
