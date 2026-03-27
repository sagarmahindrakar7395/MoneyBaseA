//
//  MoneyBaseATests.swift
//  MoneyBaseATests
//
//  Created by APPLE on 3/27/26.
//

import Foundation

struct APIConfiguration {
    let baseURL: URL
    let apiKey: String
    let host: String

    static let `default` = APIConfiguration(
        baseURL: URL(string: "https://yh-finance.p.rapidapi.com")!,
        apiKey: "22289b2029msh403b0376a963eccp195030jsndb97646d713a",
        host: "yh-finance.p.rapidapi.com"
    )
}
