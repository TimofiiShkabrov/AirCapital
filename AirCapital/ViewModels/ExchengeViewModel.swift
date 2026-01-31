//
//  ExchengeViewModel.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 09.08.2025.
//

import Foundation
import Observation

struct ExchangeDetailRow: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let usdtValue: Double?
    let valueText: String?
}

struct ExchangeDetailSection: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let rows: [ExchangeDetailRow]
}

@Observable
final class ExchengeViewModel {
    var binanceWallets: [UserDataBinance] = []
    var bybitWallets: [UserDataBybit.Result.List] = []
    var bingxSpotWallets: [UserDataBingxSpot] = []
    var bingxFuturesWallets: [UserDataBingxFutures] = []
    var gateioWallets: [UserDataGateio] = []
    var okxWallets: [UserDataOkx] = []
    var binancePrices: [PriceTickerBinance] = []
    var isLoading = false
    var errorMessage = ""
    var alert = false

    var enabledExchanges: [Exchange] {
        Exchange.allCases.filter { APIKeysManager.load(for: $0) != nil }
    }

    var totalBalanceUSDT: Double {
        enabledExchanges.reduce(0) { partialResult, exchange in
            partialResult + balanceUSDT(for: exchange)
        }
    }
    
    var binanceTotalBalance: Double {
        binanceWallets.reduce(0) { partialResult, wallet in
            partialResult + (Double(wallet.balance) ?? 0)
        }
    }
    
    var binanceTotalBalanceUSDT: Double {
        guard let btcPriceString = binancePrices.first(where: { $0.symbol == "BTCUSDT" })?.price,
              let btcPrice = Double(btcPriceString) else {
            return 0
        }
        return binanceTotalBalance * btcPrice
    }

    var bybitTotalBalanceUSDT: Double {
        bybitWallets.reduce(0) { partialResult, wallet in
            partialResult + (Double(wallet.totalEquity) ?? 0)
        }
    }
    
    var gateioTotalBalance: Double {
        gateioWallets.reduce(0) { partialResult, wallet in
            partialResult + (Double(wallet.total.amount) ?? 0)
        }
    }
    
    // MARK: - BingX Balances
    var bingxTotalBalance: Double {
        bingxSpotTotalBalance + bingxFuturesTotalBalance
    }
    
    var bingxSpotTotalBalance: Double {
        bingxSpotWallets.reduce(0) { partialResult, wallet in
            guard wallet.code == 0, let balances = wallet.data?.balances else {
                return partialResult
            }
            let usdtBalance = balances.first { $0.asset.uppercased() == "USDT" }
            let free = Double(usdtBalance?.free ?? "0") ?? 0
            let locked = Double(usdtBalance?.locked ?? "0") ?? 0
            return partialResult + free + locked
        }
    }
    
    var bingxFuturesTotalBalance: Double {
        bingxFuturesWallets.reduce(0) { partialResult, wallet in
            guard wallet.code == 0 else {
                return partialResult
            }
            let usdtBalance = wallet.data.first { $0.asset.uppercased() == "USDT" }
            return partialResult + (Double(usdtBalance?.balance ?? "0") ?? 0)
        }
    }

    var okxTotalBalanceUSDT: Double {
        guard let okx = okxWallets.first?.data.first,
              let totalBalance = Double(okx.totalEq) else {
            return 0
        }
        return totalBalance
    }

    func balanceUSDT(for exchange: Exchange) -> Double {
        switch exchange {
        case .binance:
            return binanceTotalBalanceUSDT
        case .bybit:
            return bybitTotalBalanceUSDT
        case .bingx:
            return bingxTotalBalance
        case .gateio:
            return gateioTotalBalance
        case .okx:
            return okxTotalBalanceUSDT
        }
    }

    func detailSections(for exchange: Exchange) -> [ExchangeDetailSection] {
        var sections: [ExchangeDetailSection]
        switch exchange {
        case .binance:
            sections = binanceDetailSections()
        case .bybit:
            sections = bybitDetailSections()
        case .bingx:
            sections = bingxDetailSections()
        case .gateio:
            sections = gateioDetailSections()
        case .okx:
            sections = okxDetailSections()
        }
        sections.append(subaccountsSection())
        return sections
    }

    func loadData(completion: (() -> Void)? = nil) {
        errorMessage = ""
        alert = false

        let enabled = enabledExchanges
        if enabled.isEmpty {
            binanceWallets = []
            bybitWallets = []
            bingxSpotWallets = []
            bingxFuturesWallets = []
            gateioWallets = []
            okxWallets = []
            binancePrices = []
            isLoading = false
            completion?()
            return
        }

        isLoading = true
        let group = DispatchGroup()

        if enabled.contains(.binance) {
            group.enter()
            NetworkManager.shared.fetchPriceTickerBinance { [weak self] result in
                switch result {
                case .success(let data):
                    self?.binancePrices = [data]
                case .failure(let error):
                    self?.handleFailure(error, exchange: .binance, invalidatesKeys: false)
                }
                group.leave()
            }

            group.enter()
            NetworkManager.shared.fetchUserDataBinance { [weak self] result in
                switch result {
                case .success(let data):
                    self?.binanceWallets = data
                case .failure(let error):
                    self?.handleFailure(error, exchange: .binance)
                }
                group.leave()
            }
        } else {
            binanceWallets = []
            binancePrices = []
        }

        if enabled.contains(.bybit) {
            group.enter()
            NetworkManager.shared.fetchUserDataBybit { [weak self] result in
                switch result {
                case .success(let data):
                    self?.bybitWallets = data.result.list
                case .failure(let error):
                    self?.handleFailure(error, exchange: .bybit)
                }
                group.leave()
            }
        } else {
            bybitWallets = []
        }

        if enabled.contains(.bingx) {
            group.enter()
            NetworkManager.shared.fetchUserDataBingxSpot { [weak self] result in
                switch result {
                case .success(let data):
                    self?.bingxSpotWallets = [data]
                case .failure(let error):
                    self?.handleFailure(error, exchange: .bingx)
                }
                group.leave()
            }

            group.enter()
            NetworkManager.shared.fetchUserDataBingxFutures { [weak self] result in
                switch result {
                case .success(let data):
                    self?.bingxFuturesWallets = [data]
                case .failure(let error):
                    self?.handleFailure(error, exchange: .bingx)
                }
                group.leave()
            }
        } else {
            bingxSpotWallets = []
            bingxFuturesWallets = []
        }

        if enabled.contains(.gateio) {
            group.enter()
            NetworkManager.shared.fetchUserDataGateio { [weak self] result in
                switch result {
                case .success(let data):
                    self?.gateioWallets = [data]
                case .failure(let error):
                    self?.handleFailure(error, exchange: .gateio)
                }
                group.leave()
            }
        } else {
            gateioWallets = []
        }

        if enabled.contains(.okx) {
            group.enter()
            NetworkManager.shared.fetchUserDataOkx { [weak self] result in
                switch result {
                case .success(let data):
                    self?.okxWallets = [data]
                case .failure(let error):
                    self?.handleFailure(error, exchange: .okx)
                }
                group.leave()
            }
        } else {
            okxWallets = []
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            completion?()
        }
    }

    private func handleFailure(
        _ error: NetworkError,
        exchange: Exchange,
        invalidatesKeys: Bool = true
    ) {
        if invalidatesKeys && error == .malformedRequests {
            APIKeysManager.delete(for: exchange)
            clearData(for: exchange)
            NotificationCenter.default.post(name: .apiKeysInvalidated, object: exchange)
            errorMessage = "Invalid API keys for \(exchange.rawValue.capitalized)"
        } else {
            errorMessage = warningMassage(error: error)
        }
        alert = true
    }

    private func clearData(for exchange: Exchange) {
        switch exchange {
        case .binance:
            binanceWallets = []
            binancePrices = []
        case .bybit:
            bybitWallets = []
        case .bingx:
            bingxSpotWallets = []
            bingxFuturesWallets = []
        case .gateio:
            gateioWallets = []
        case .okx:
            okxWallets = []
        }
    }

    // MARK: - Detail sections
    private func binanceDetailSections() -> [ExchangeDetailSection] {
        let btcPrice = Double(binancePrices.first(where: { $0.symbol == "BTCUSDT" })?.price ?? "")
        let rows = binanceWallets.map { wallet in
            let balanceBTC = Double(wallet.balance)
            let usdtValue = (balanceBTC ?? 0) * (btcPrice ?? 0)
            let valueText = btcPrice == nil ? "BTCUSDT price unavailable" : nil
            return ExchangeDetailRow(
                title: wallet.walletName.isEmpty ? "Wallet" : wallet.walletName,
                subtitle: wallet.activate ? "Active" : "Inactive",
                usdtValue: (btcPrice == nil || balanceBTC == nil) ? nil : usdtValue,
                valueText: valueText
            )
        }
        return [sectionOrPlaceholder(title: "Wallets", rows: rows)]
    }

    private func bybitDetailSections() -> [ExchangeDetailSection] {
        var sections: [ExchangeDetailSection] = []
        for account in bybitWallets {
            var rows: [ExchangeDetailRow] = []
            if let total = Double(account.totalEquity) {
                rows.append(
                    ExchangeDetailRow(
                        title: "Total",
                        subtitle: nil,
                        usdtValue: total,
                        valueText: nil
                    )
                )
            }
            for coin in account.coin {
                let usdValue = Double(coin.usdValue)
                rows.append(
                    ExchangeDetailRow(
                        title: coin.coin,
                        subtitle: "Equity \(coin.equity)",
                        usdtValue: usdValue,
                        valueText: usdValue == nil ? "—" : nil
                    )
                )
            }
            let title = "Account \(account.accountType)"
            sections.append(sectionOrPlaceholder(title: title, rows: rows))
        }
        return sections.isEmpty ? [placeholderSection(title: "Wallets", message: "No data")] : sections
    }

    private func bingxDetailSections() -> [ExchangeDetailSection] {
        let spotRows = bingxSpotWallets.flatMap { wallet -> [ExchangeDetailRow] in
            guard wallet.code == 0, let balances = wallet.data?.balances else {
                return []
            }
            return balances.compactMap { balance in
                guard balance.asset.uppercased() == "USDT" else {
                    return nil
                }
                let total = (Double(balance.free) ?? 0) + (Double(balance.locked) ?? 0)
                return ExchangeDetailRow(
                    title: balance.asset,
                    subtitle: "Spot",
                    usdtValue: total,
                    valueText: nil
                )
            }
        }
        let futuresRows = bingxFuturesWallets.flatMap { wallet -> [ExchangeDetailRow] in
            guard wallet.code == 0 else {
                return []
            }
            return wallet.data.map { data in
                let usdtValue = Double(data.equity) ?? Double(data.balance)
                return ExchangeDetailRow(
                    title: data.asset,
                    subtitle: "Futures",
                    usdtValue: usdtValue,
                    valueText: usdtValue == nil ? "—" : nil
                )
            }
        }
        return [
            sectionOrPlaceholder(title: "Spot", rows: spotRows, emptyMessage: "No USDT"),
            sectionOrPlaceholder(title: "Futures", rows: futuresRows)
        ]
    }

    private func gateioDetailSections() -> [ExchangeDetailSection] {
        let rows = gateioWallets.flatMap { wallet -> [ExchangeDetailRow] in
            wallet.details.values.compactMap { detail in
                guard detail.currency.uppercased() == "USDT" else {
                    return nil
                }
                let usdtValue = Double(detail.amount)
                return ExchangeDetailRow(
                    title: detail.currency.uppercased(),
                    subtitle: nil,
                    usdtValue: usdtValue,
                    valueText: usdtValue == nil ? "—" : nil
                )
            }
        }
        return [sectionOrPlaceholder(title: "Wallets", rows: rows, emptyMessage: "No USDT")]
    }

    private func okxDetailSections() -> [ExchangeDetailSection] {
        let rows: [ExchangeDetailRow] = okxWallets.first?.data.first?.details.map { detail in
            let usdtValue = Double(detail.eqUsd)
            return ExchangeDetailRow(
                title: detail.ccy,
                subtitle: "Equity",
                usdtValue: usdtValue,
                valueText: usdtValue == nil ? "—" : nil
            )
        } ?? []
        return [sectionOrPlaceholder(title: "Assets", rows: rows)]
    }

    private func subaccountsSection() -> ExchangeDetailSection {
        placeholderSection(title: "Subaccounts", message: "No data")
    }

    private func sectionOrPlaceholder(
        title: String,
        rows: [ExchangeDetailRow],
        emptyMessage: String = "No data"
    ) -> ExchangeDetailSection {
        rows.isEmpty ? placeholderSection(title: title, message: emptyMessage) : ExchangeDetailSection(title: title, rows: rows)
    }

    private func placeholderSection(title: String, message: String) -> ExchangeDetailSection {
        ExchangeDetailSection(
            title: title,
            rows: [ExchangeDetailRow(title: message, subtitle: nil, usdtValue: nil, valueText: nil)]
        )
    }
}
