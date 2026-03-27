# MoneyBaseA

MoneyBaseA is a SwiftUI iOS app that shows market instruments from Yahoo Finance (via RapidAPI), with a searchable list and a local detail screen.

## Features

- Stock/market list from `market/v2/get-summary`
- Auto-refresh every 8 seconds
- Search by symbol or name
- Detail screen that uses selected list data (no extra API call)
- MVVM architecture with dependency injection
- Generic and reusable networking layer
- Unit tests for networking, mapping, and view model behavior

## Tech Stack

- Swift
- SwiftUI
- Swift Concurrency (`async/await`)
- XCTest

## Architecture

- **MVVM**
  - `StocksListView` + `StocksListViewModel`
  - `StockDetailView` (local data from list item)
- **DI Container**
  - `AppDIContainer` wires network and service dependencies
- **Networking**
  - `NetworkManaging` protocol
  - `NetworkManager` with generic `request<T: Decodable>()`
  - `Endpoint` abstraction for path/query/method
- **Service layer**
  - `StockServicing` + `StockService`

## API

Base URL:

- `https://yh-finance.p.rapidapi.com`

Endpoints used:

- `GET /market/v2/get-summary?region=US` (list)

Headers:

- `X-RapidAPI-Key`
- `X-RapidAPI-Host`

## Project Structure

- `MoneyBaseA/NetworkCore.swift` - generic network manager and errors
- `MoneyBaseA/StocksService.swift` - stock service calls
- `MoneyBaseA/StocksModels.swift` - API + domain models and mapping
- `MoneyBaseA/StocksListViewModel.swift` - list state/search/auto-refresh
- `MoneyBaseA/StocksListView.swift` - list UI and navigation
- `MoneyBaseA/StockDetailView.swift` - detail UI from selected stock data
- `MoneyBaseA/AppDIContainer.swift` - dependency wiring
- `MoneyBaseATests/MoneyBaseATests.swift` - unit tests

## Run

1. Open `MoneyBaseA.xcodeproj` in Xcode.
2. Choose an iOS simulator/device.
3. Build and run.

## Tests

Run tests from Xcode (`Product > Test`) or with:

```bash
xcodebuild test -project "MoneyBaseA.xcodeproj" -scheme "MoneyBaseA" -destination "platform=iOS Simulator,name=iPhone 16"
```

## Notes

- The app currently contains a hardcoded RapidAPI key for demo purposes.
- For production, move secrets to secure configuration (xcconfig, CI secrets, or runtime injection).
