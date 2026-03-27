//
//  MoneyBaseATests.swift
//  MoneyBaseATests
//
//  Created by APPLE on 3/27/26.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]

    init(path: String, method: HTTPMethod = .get, queryItems: [URLQueryItem] = []) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }
}

enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case transport(String)
    case invalidResponse
    case httpStatus(Int)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL could not be built."
        case .transport(let message):
            return "Network request failed: \(message)"
        case .invalidResponse:
            return "Received invalid response."
        case .httpStatus(let code):
            return "Request failed with HTTP status: \(code)"
        case .decoding(let message):
            return "Failed to decode response: \(message)"
        }
    }
}

protocol NetworkManaging {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

final class NetworkManager: NetworkManaging {
    private let session: URLSession
    private let configuration: APIConfiguration
    private let decoder: JSONDecoder

    init(
        session: URLSession,
        configuration: APIConfiguration,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.configuration = configuration
        self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard var components = URLComponents(
            url: configuration.baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue(configuration.apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue(configuration.host, forHTTPHeaderField: "X-RapidAPI-Host")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.transport(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpStatus(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error.localizedDescription)
        }
    }
}

extension Data {
    var prettyJSON: String? {
        guard let obj = try? JSONSerialization.jsonObject(with: self),
              let data = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
