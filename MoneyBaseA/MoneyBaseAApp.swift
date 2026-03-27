//
//  MoneyBaseAApp.swift
//  MoneyBaseA
//
//  Created by APPLE on 3/27/26.
//

import SwiftUI

@main
struct MoneyBaseAApp: App {
    private let container = AppDIContainer()

    var body: some Scene {
        WindowGroup {
            StocksListView(viewModel: container.makeStocksListViewModel())
        }
    }
}
