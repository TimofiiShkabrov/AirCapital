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

struct BybitEarnPositionItem: Identifiable, Hashable {
    let id = UUID()
    let category: String
    let coin: String
    let amount: String
    let status: String?
}

@Observable
final class ExchengeViewModel {
    var binanceWallets: [UserDataBinance] = []
    var bybitWallets: [UserDataBybit.Result.List] = []
    var bybitEarnPositions: [BybitEarnPositionItem] = []
    var bingxSpotWallets: [UserDataBingxSpot] = []
    var bingxFuturesWallets: [UserDataBingxFutures] = []
    var gateioWallets: [UserDataGateio] = []
    var okxWallets: [UserDataOkx] = []
    var isLoading = false
    var errorMessage = ""
    var alert = false

    var enabledExchanges: [Exchange] {
        let accounts = APIKeysManager.allAccounts()
        return Exchange.allCases.filter { exchange in
            accounts.contains { $0.exchange == exchange }
        }
    }

    var totalBalanceUSDT: Double {
        enabledExchanges.reduce(0) { partialResult, exchange in
            partialResult + balanceUSDT(for: exchange)
        }
    }
    
    var binanceTotalBalanceUSDT: Double {
        binanceWallets.reduce(0) { partialResult, wallet in
            partialResult + (Double(wallet.balance) ?? 0)
        }
    }

    var bybitTotalBalanceUSDT: Double {
        let walletTotal = bybitWallets.reduce(0) { partialResult, wallet in
            partialResult + (Double(wallet.totalEquity) ?? 0)
        }
        return walletTotal + bybitEarnTotalUSDT
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
        okxWallets.reduce(0) { partialResult, wallet in
            let total = wallet.data.reduce(0.0) { innerResult, data in
                innerResult + (Double(data.totalEq) ?? 0)
            }
            return partialResult + total
        }
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

    private var bybitCoinPriceMap: [String: Double] {
        var map: [String: Double] = [:]
        for wallet in bybitWallets {
            for coin in wallet.coin {
                guard let usdValue = Double(coin.usdValue),
                      let equity = Double(coin.equity),
                      equity > 0 else {
                    continue
                }
                map[coin.coin.uppercased()] = usdValue / equity
            }
        }
        return map
    }

    private var bybitEarnTotalUSDT: Double {
        bybitEarnPositions.reduce(0) { partialResult, position in
            guard let amount = Double(position.amount),
                  let usdtValue = bybitEarnUSDTValue(coin: position.coin, amount: amount) else {
                return partialResult
            }
            return partialResult + usdtValue
        }
    }

    private func bybitEarnUSDTValue(coin: String, amount: Double) -> Double? {
        let upperCoin = coin.uppercased()
        if upperCoin == "USDT" || upperCoin == "USDC" {
            return amount
        }
        guard let price = bybitCoinPriceMap[upperCoin] else {
            return nil
        }
        return amount * price
    }

    private func bybitEarnCategoryLabel(_ category: String) -> String {
        switch category {
        case "FlexibleSaving":
            return "Flexible Saving"
        case "OnChain":
            return "On-chain"
        default:
            return category
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

        let accounts = APIKeysManager.allAccounts()
        if accounts.isEmpty {
            binanceWallets = []
            bybitWallets = []
            bybitEarnPositions = []
            bingxSpotWallets = []
            bingxFuturesWallets = []
            gateioWallets = []
            okxWallets = []
            isLoading = false
            completion?()
            return
        }

        binanceWallets = []
        bybitWallets = []
        bybitEarnPositions = []
        bingxSpotWallets = []
        bingxFuturesWallets = []
        gateioWallets = []
        okxWallets = []

        isLoading = true
        let group = DispatchGroup()

        let binanceAccounts = accounts.filter { $0.exchange == .binance }
        if binanceAccounts.isEmpty == false {
            for account in binanceAccounts {
                guard let keys = APIKeysManager.loadKeys(for: account) else {
                    APIKeysManager.delete(account: account)
                    continue
                }
                group.enter()
                NetworkManager.shared.fetchUserDataBinance(keys: keys) { [weak self] result in
                    switch result {
                    case .success(let data):
                        self?.binanceWallets.append(contentsOf: data)
                    case .failure(let error):
                        self?.handleFailure(error, exchange: .binance, account: account)
                    }
                    group.leave()
                }
            }
        }

        let bybitAccounts = accounts.filter { $0.exchange == .bybit }
        if bybitAccounts.isEmpty == false {
            let earnCategories = ["FlexibleSaving", "OnChain"]
            for account in bybitAccounts {
                guard let keys = APIKeysManager.loadKeys(for: account) else {
                    APIKeysManager.delete(account: account)
                    continue
                }

                group.enter()
                NetworkManager.shared.fetchUserDataBybit(keys: keys) { [weak self] result in
                    switch result {
                    case .success(let data):
                        self?.bybitWallets.append(contentsOf: data.result.list)
                    case .failure(let error):
                        self?.handleFailure(error, exchange: .bybit, account: account)
                    }
                    group.leave()
                }
                for category in earnCategories {
                    group.enter()
                    NetworkManager.shared.fetchBybitEarnPositions(category: category, keys: keys) { [weak self] result in
                        switch result {
                        case .success(let data):
                            guard data.retCode == 0, let positions = data.result?.list else {
                                group.leave()
                                return
                            }
                            let items = positions.map {
                                BybitEarnPositionItem(
                                    category: category,
                                    coin: $0.coin,
                                    amount: $0.amount,
                                    status: $0.status
                                )
                            }
                            self?.bybitEarnPositions.append(contentsOf: items)
                        case .failure:
                            break
                        }
                        group.leave()
                    }
                }
            }
        }

        let bingxAccounts = accounts.filter { $0.exchange == .bingx }
        if bingxAccounts.isEmpty == false {
            for account in bingxAccounts {
                guard let keys = APIKeysManager.loadKeys(for: account) else {
                    APIKeysManager.delete(account: account)
                    continue
                }
                group.enter()
                NetworkManager.shared.fetchUserDataBingxSpot(keys: keys) { [weak self] result in
                    switch result {
                    case .success(let data):
                        self?.bingxSpotWallets.append(data)
                    case .failure(let error):
                        self?.handleFailure(error, exchange: .bingx, account: account)
                    }
                    group.leave()
                }

                group.enter()
                NetworkManager.shared.fetchUserDataBingxFutures(keys: keys) { [weak self] result in
                    switch result {
                    case .success(let data):
                        self?.bingxFuturesWallets.append(data)
                    case .failure(let error):
                        self?.handleFailure(error, exchange: .bingx, account: account)
                    }
                    group.leave()
                }
            }
        }

        let gateioAccounts = accounts.filter { $0.exchange == .gateio }
        if gateioAccounts.isEmpty == false {
            for account in gateioAccounts {
                guard let keys = APIKeysManager.loadKeys(for: account) else {
                    APIKeysManager.delete(account: account)
                    continue
                }
                group.enter()
                NetworkManager.shared.fetchUserDataGateio(keys: keys) { [weak self] result in
                    switch result {
                    case .success(let data):
                        self?.gateioWallets.append(data)
                    case .failure(let error):
                        self?.handleFailure(error, exchange: .gateio, account: account)
                    }
                    group.leave()
                }
            }
        }

        let okxAccounts = accounts.filter { $0.exchange == .okx }
        if okxAccounts.isEmpty == false {
            for account in okxAccounts {
                guard let keys = APIKeysManager.loadKeys(for: account) else {
                    APIKeysManager.delete(account: account)
                    continue
                }
                group.enter()
                NetworkManager.shared.fetchUserDataOkx(keys: keys) { [weak self] result in
                    switch result {
                    case .success(let data):
                        self?.okxWallets.append(data)
                    case .failure(let error):
                        self?.handleFailure(error, exchange: .okx, account: account)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            completion?()
        }
    }

    private func handleFailure(
        _ error: NetworkError,
        exchange: Exchange,
        account: ExchangeAccount,
        invalidatesKeys: Bool = true
    ) {
        if invalidatesKeys && error == .malformedRequests {
            APIKeysManager.delete(account: account)
            NotificationCenter.default.post(name: .apiKeysInvalidated, object: exchange)
            errorMessage = "Invalid API keys for \(exchange.rawValue.capitalized)"
        } else {
            errorMessage = warningMassage(error: error)
        }
        alert = true
    }

    // MARK: - Detail sections
    private func binanceDetailSections() -> [ExchangeDetailSection] {
        let rows = binanceWallets.map { wallet in
            let usdtValue = Double(wallet.balance)
            return ExchangeDetailRow(
                title: wallet.walletName.isEmpty ? "Wallet" : wallet.walletName,
                subtitle: wallet.activate ? "Active" : "Inactive",
                usdtValue: usdtValue,
                valueText: usdtValue == nil ? "—" : nil
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
        if bybitEarnPositions.isEmpty == false {
            let earnRows = bybitEarnPositions.map { position in
                let amount = Double(position.amount) ?? 0
                let usdtValue = bybitEarnUSDTValue(coin: position.coin, amount: amount)
                let subtitle = "Earn \(bybitEarnCategoryLabel(position.category))"
                return ExchangeDetailRow(
                    title: position.coin,
                    subtitle: subtitle,
                    usdtValue: usdtValue,
                    valueText: usdtValue == nil ? "Price unavailable" : nil
                )
            }
            sections.append(sectionOrPlaceholder(title: "Earn", rows: earnRows))
        } else {
            sections.append(placeholderSection(title: "Earn", message: "No data"))
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
        let rows: [ExchangeDetailRow] = okxWallets.flatMap { wallet in
            wallet.data.flatMap { data in
                data.details.map { detail in
                    let usdtValue = Double(detail.eqUsd)
                    return ExchangeDetailRow(
                        title: detail.ccy,
                        subtitle: "Equity",
                        usdtValue: usdtValue,
                        valueText: usdtValue == nil ? "—" : nil
                    )
                }
            }
        }
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
