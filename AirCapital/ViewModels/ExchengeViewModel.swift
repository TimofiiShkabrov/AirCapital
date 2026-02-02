//
//  ExchengeViewModel.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 09.08.2025.
//

import Foundation
import Observation

@Observable
final class ExchengeViewModel {
    var binanceWalletsByAccount: [UUID: [UserDataBinance]] = [:]
    var bybitWalletsByAccount: [UUID: [UserDataBybit.Result.List]] = [:]
    var bybitEarnPositionsByAccount: [UUID: [BybitEarnPositionItem]] = [:]
    var bybitCoinBalancesByAccount: [UUID: [String: [BybitCoinBalance]]] = [:]
    var bingxSpotWalletsByAccount: [UUID: UserDataBingxSpot] = [:]
    var bingxFuturesWalletsByAccount: [UUID: UserDataBingxFutures] = [:]
    var gateioWalletsByAccount: [UUID: UserDataGateio] = [:]
    var okxWalletsByAccount: [UUID: UserDataOkx] = [:]
    var okxFundingBalancesByAccount: [UUID: [OkxFundingBalance]] = [:]
    var isLoading = false
    var errorMessage = ""
    var alert = false

    var enabledAccounts: [ExchangeAccount] {
        APIKeysManager.allAccounts()
    }

    var totalBalanceUSDT: Double {
        enabledAccounts.reduce(0) { partialResult, account in
            partialResult + balanceUSDT(for: account)
        }
    }
    
    private func binanceTotalBalanceUSDT(for accountID: UUID) -> Double {
        let wallets = binanceWalletsByAccount[accountID] ?? []
        return wallets.reduce(0) { partialResult, wallet in
            partialResult + (Double(wallet.balance) ?? 0)
        }
    }

    private func bybitTotalBalanceUSDT(for accountID: UUID) -> Double {
        let wallets = bybitWalletsByAccount[accountID] ?? []
        let walletTotal = wallets.reduce(0) { partialResult, wallet in
            partialResult + (Double(wallet.totalEquity) ?? 0)
        }
        let earnTotal = bybitEarnTotalUSDT(for: accountID)
        let extraTotal = bybitExtraUsdtBalance(for: accountID)
        return walletTotal + earnTotal + extraTotal
    }
    
    private func gateioTotalBalance(for accountID: UUID) -> Double {
        guard let wallet = gateioWalletsByAccount[accountID] else {
            return 0
        }
        return Double(wallet.total.amount) ?? 0
    }
    
    // MARK: - BingX Balances
    private func bingxTotalBalance(for accountID: UUID) -> Double {
        bingxSpotTotalBalance(for: accountID) + bingxFuturesTotalBalance(for: accountID)
    }
    
    private func bingxSpotTotalBalance(for accountID: UUID) -> Double {
        guard let wallet = bingxSpotWalletsByAccount[accountID],
              wallet.code == 0,
              let balances = wallet.data?.balances else {
            return 0
        }
        let usdtBalance = balances.first { $0.asset.uppercased() == "USDT" }
        let free = Double(usdtBalance?.free ?? "0") ?? 0
        let locked = Double(usdtBalance?.locked ?? "0") ?? 0
        return free + locked
    }
    
    private func bingxFuturesTotalBalance(for accountID: UUID) -> Double {
        guard let wallet = bingxFuturesWalletsByAccount[accountID],
              wallet.code == 0 else {
            return 0
        }
        let usdtBalance = wallet.data.first { $0.asset.uppercased() == "USDT" }
        return Double(usdtBalance?.balance ?? "0") ?? 0
    }

    private func okxTotalBalanceUSDT(for accountID: UUID) -> Double {
        guard let wallet = okxWalletsByAccount[accountID] else {
            return okxFundingUsdtBalance(for: accountID)
        }
        let tradingTotal = wallet.data.reduce(0.0) { partialResult, data in
            partialResult + (Double(data.totalEq) ?? 0)
        }
        return tradingTotal + okxFundingUsdtBalance(for: accountID)
    }

    func balanceUSDT(for account: ExchangeAccount) -> Double {
        switch account.exchange {
        case .binance:
            return binanceTotalBalanceUSDT(for: account.id)
        case .bybit:
            return bybitTotalBalanceUSDT(for: account.id)
        case .bingx:
            return bingxTotalBalance(for: account.id)
        case .gateio:
            return gateioTotalBalance(for: account.id)
        case .okx:
            return okxTotalBalanceUSDT(for: account.id)
        }
    }

    private func bybitCoinPriceMap(for accountID: UUID) -> [String: Double] {
        var map: [String: Double] = [:]
        let wallets = bybitWalletsByAccount[accountID] ?? []
        for wallet in wallets {
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

    private func bybitEarnTotalUSDT(for accountID: UUID) -> Double {
        let positions = bybitEarnPositionsByAccount[accountID] ?? []
        return positions.reduce(0) { partialResult, position in
            guard let amount = Double(position.amount),
                  let usdtValue = bybitEarnUSDTValue(coin: position.coin, amount: amount, accountID: accountID) else {
                return partialResult
            }
            return partialResult + usdtValue
        }
    }

    private func bybitEarnUSDTValue(coin: String, amount: Double, accountID: UUID) -> Double? {
        let upperCoin = coin.uppercased()
        if upperCoin == "USDT" || upperCoin == "USDC" {
            return amount
        }
        guard let price = bybitCoinPriceMap(for: accountID)[upperCoin] else {
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

    private func bybitExtraUsdtBalance(for accountID: UUID) -> Double {
        let balances = bybitCoinBalancesByAccount[accountID] ?? [:]
        let accountTypes = ["FUND", "SPOT", "CONTRACT", "OPTION"]
        return accountTypes.reduce(0.0) { partialResult, accountType in
            guard let coins = balances[accountType] else {
                return partialResult
            }
            let usdtCoins = coins.filter { $0.coin.uppercased() == "USDT" }
            let total = usdtCoins.reduce(0.0) { innerResult, coin in
                innerResult + (Double(coin.walletBalance) ?? 0)
            }
            return partialResult + total
        }
    }

    private func okxFundingUsdtBalance(for accountID: UUID) -> Double {
        guard let balances = okxFundingBalancesByAccount[accountID] else {
            return 0
        }
        return balances.reduce(0) { partialResult, balance in
            guard balance.ccy.uppercased() == "USDT" else {
                return partialResult
            }
            return partialResult + (Double(balance.bal) ?? 0)
        }
    }

    func walletTypeSections(for account: ExchangeAccount) -> [WalletTypeSection] {
        switch account.exchange {
        case .binance:
            return binanceWalletTypeSections(for: account.id)
        case .bybit:
            return bybitWalletTypeSections(for: account.id)
        case .bingx:
            return bingxWalletTypeSections(for: account.id)
        case .gateio:
            return gateioWalletTypeSections(for: account.id)
        case .okx:
            return okxWalletTypeSections(for: account.id)
        }
    }

    func detailSections(for account: ExchangeAccount) -> [ExchangeDetailSection] {
        var sections: [ExchangeDetailSection]
        switch account.exchange {
        case .binance:
            sections = binanceDetailSections(for: account.id)
        case .bybit:
            sections = bybitDetailSections(for: account.id)
        case .bingx:
            sections = bingxDetailSections(for: account.id)
        case .gateio:
            sections = gateioDetailSections(for: account.id)
        case .okx:
            sections = okxDetailSections(for: account.id)
        }
        return sections
    }

    func loadData(completion: (() -> Void)? = nil) {
        errorMessage = ""
        alert = false

        let accounts = APIKeysManager.allAccounts()
        if accounts.isEmpty {
            binanceWalletsByAccount = [:]
            bybitWalletsByAccount = [:]
            bybitEarnPositionsByAccount = [:]
            bybitCoinBalancesByAccount = [:]
            bingxSpotWalletsByAccount = [:]
            bingxFuturesWalletsByAccount = [:]
            gateioWalletsByAccount = [:]
            okxWalletsByAccount = [:]
            okxFundingBalancesByAccount = [:]
            isLoading = false
            completion?()
            return
        }

        binanceWalletsByAccount = [:]
        bybitWalletsByAccount = [:]
        bybitEarnPositionsByAccount = [:]
        bybitCoinBalancesByAccount = [:]
        bingxSpotWalletsByAccount = [:]
        bingxFuturesWalletsByAccount = [:]
        gateioWalletsByAccount = [:]
        okxWalletsByAccount = [:]
        okxFundingBalancesByAccount = [:]

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
                        self?.binanceWalletsByAccount[account.id] = data
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
                        self?.bybitWalletsByAccount[account.id] = data.result.list
                    case .failure(let error):
                        self?.handleFailure(error, exchange: .bybit, account: account)
                    }
                    group.leave()
                }
                let additionalAccountTypes = ["FUND", "SPOT", "CONTRACT", "OPTION"]
                for accountType in additionalAccountTypes {
                    group.enter()
                    NetworkManager.shared.fetchBybitAllCoinsBalance(accountType: accountType, keys: keys) { [weak self] result in
                        switch result {
                        case .success(let data):
                            guard data.retCode == 0, let balance = data.result?.balance else {
                                group.leave()
                                return
                            }
                            var existing = self?.bybitCoinBalancesByAccount[account.id] ?? [:]
                            existing[accountType] = balance
                            self?.bybitCoinBalancesByAccount[account.id] = existing
                        case .failure:
                            break
                        }
                        group.leave()
                    }
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
                            var existing = self?.bybitEarnPositionsByAccount[account.id] ?? []
                            existing.append(contentsOf: items)
                            self?.bybitEarnPositionsByAccount[account.id] = existing
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
                        self?.bingxSpotWalletsByAccount[account.id] = data
                    case .failure(let error):
                        self?.handleFailure(error, exchange: .bingx, account: account)
                    }
                    group.leave()
                }

                group.enter()
                NetworkManager.shared.fetchUserDataBingxFutures(keys: keys) { [weak self] result in
                    switch result {
                    case .success(let data):
                        self?.bingxFuturesWalletsByAccount[account.id] = data
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
                        self?.gateioWalletsByAccount[account.id] = data
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
                        self?.okxWalletsByAccount[account.id] = data
                    case .failure(let error):
                        self?.handleFailure(error, exchange: .okx, account: account)
                    }
                    group.leave()
                }
                group.enter()
                NetworkManager.shared.fetchFundingBalancesOkx(keys: keys) { [weak self] result in
                    switch result {
                    case .success(let data):
                        self?.okxFundingBalancesByAccount[account.id] = data.data
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
    private func binanceDetailSections(for accountID: UUID) -> [ExchangeDetailSection] {
        let wallets = binanceWalletsByAccount[accountID] ?? []
        let rows = wallets.map { wallet in
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

    private func bybitDetailSections(for accountID: UUID) -> [ExchangeDetailSection] {
        var sections: [ExchangeDetailSection] = []
        let accounts = bybitWalletsByAccount[accountID] ?? []
        for account in accounts {
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
        let earnPositions = bybitEarnPositionsByAccount[accountID] ?? []
        if earnPositions.isEmpty == false {
            let earnRows = earnPositions.map { position in
                let amount = Double(position.amount) ?? 0
                let usdtValue = bybitEarnUSDTValue(coin: position.coin, amount: amount, accountID: accountID)
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

    private func bingxDetailSections(for accountID: UUID) -> [ExchangeDetailSection] {
        let spotRows: [ExchangeDetailRow]
        if let wallet = bingxSpotWalletsByAccount[accountID],
           wallet.code == 0,
           let balances = wallet.data?.balances {
            spotRows = balances.compactMap { balance in
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
        } else {
            spotRows = []
        }

        let futuresRows: [ExchangeDetailRow]
        if let wallet = bingxFuturesWalletsByAccount[accountID],
           wallet.code == 0 {
            futuresRows = wallet.data.map { data in
                let usdtValue = Double(data.equity) ?? Double(data.balance)
                return ExchangeDetailRow(
                    title: data.asset,
                    subtitle: "Futures",
                    usdtValue: usdtValue,
                    valueText: usdtValue == nil ? "—" : nil
                )
            }
        } else {
            futuresRows = []
        }
        return [
            sectionOrPlaceholder(title: "Spot", rows: spotRows, emptyMessage: "No USDT"),
            sectionOrPlaceholder(title: "Futures", rows: futuresRows)
        ]
    }

    private func gateioDetailSections(for accountID: UUID) -> [ExchangeDetailSection] {
        let rows: [ExchangeDetailRow]
        if let wallet = gateioWalletsByAccount[accountID] {
            rows = wallet.details
                .sorted { $0.key < $1.key }
                .compactMap { key, detail in
                    guard detail.currency.uppercased() == "USDT" else {
                        return nil
                    }
                    let usdtValue = Double(detail.amount)
                    guard let amount = usdtValue, amount > 0 else {
                        return nil
                    }
                    return ExchangeDetailRow(
                        title: key.capitalized,
                        subtitle: detail.currency.uppercased(),
                        usdtValue: usdtValue,
                        valueText: usdtValue == nil ? "—" : nil
                    )
                }
        } else {
            rows = []
        }
        return [sectionOrPlaceholder(title: "Wallets", rows: rows, emptyMessage: "No USDT")]
    }

    private func okxDetailSections(for accountID: UUID) -> [ExchangeDetailSection] {
        let rows: [ExchangeDetailRow]
        if let wallet = okxWalletsByAccount[accountID] {
            rows = wallet.data.flatMap { data in
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
        } else {
            rows = []
        }
        return [sectionOrPlaceholder(title: "Assets", rows: rows)]
    }

    // MARK: - Wallet type sections
    private func binanceWalletTypeSections(for accountID: UUID) -> [WalletTypeSection] {
        let wallets = binanceWalletsByAccount[accountID] ?? []
        let sections = wallets.map { wallet -> WalletTypeSection in
            let total = Double(wallet.balance)
            let rows = [
                ExchangeDetailRow(
                    title: "Balance",
                    subtitle: wallet.activate ? "Active" : "Inactive",
                    usdtValue: total,
                    valueText: total == nil ? "—" : nil
                )
            ]
            let title = wallet.walletName.isEmpty ? "Wallet" : wallet.walletName
            return WalletTypeSection(id: walletTypeID(accountID: accountID, title: title), title: title, totalUSDT: total, rows: rows)
        }
        return sections.isEmpty ? [placeholderWalletTypeSection(accountID: accountID, title: "Wallets", message: "No data")] : sections
    }

    private func bybitWalletTypeSections(for accountID: UUID) -> [WalletTypeSection] {
        var sections: [WalletTypeSection] = []
        let accounts = bybitWalletsByAccount[accountID] ?? []
        for account in accounts {
            let total = Double(account.totalEquity)
            let rows = account.coin.map { coin in
                let usdValue = Double(coin.usdValue)
                return ExchangeDetailRow(
                    title: coin.coin,
                    subtitle: "Equity \(coin.equity)",
                    usdtValue: usdValue,
                    valueText: usdValue == nil ? "—" : nil
                )
            }
            sections.append(
                WalletTypeSection(
                    id: walletTypeID(accountID: accountID, title: "Account \(account.accountType)"),
                    title: "Account \(account.accountType)",
                    totalUSDT: total,
                    rows: rows.isEmpty ? [placeholderRow(message: "No data")] : rows
                )
            )
        }

        if let extraBalances = bybitCoinBalancesByAccount[accountID] {
            let displayOrder = ["FUND", "SPOT", "CONTRACT", "OPTION"]
            for accountType in displayOrder {
                guard let balances = extraBalances[accountType], balances.isEmpty == false else {
                    continue
                }
                let usdtTotal = balances.reduce(0.0) { partialResult, balance in
                    guard balance.coin.uppercased() == "USDT" else {
                        return partialResult
                    }
                    return partialResult + (Double(balance.walletBalance) ?? 0)
                }
                let rows = balances.map { balance in
                    ExchangeDetailRow(
                        title: balance.coin,
                        subtitle: "Balance",
                        usdtValue: nil,
                        valueText: "\(balance.walletBalance) \(balance.coin)"
                    )
                }
                sections.append(
                    WalletTypeSection(
                        id: walletTypeID(accountID: accountID, title: bybitAccountTypeLabel(accountType)),
                        title: bybitAccountTypeLabel(accountType),
                        totalUSDT: usdtTotal > 0 ? usdtTotal : nil,
                        rows: rows
                    )
                )
            }
        }

        let earnPositions = bybitEarnPositionsByAccount[accountID] ?? []
        if earnPositions.isEmpty == false {
            let rows = earnPositions.map { position in
                let amount = Double(position.amount) ?? 0
                let usdtValue = bybitEarnUSDTValue(coin: position.coin, amount: amount, accountID: accountID)
                let subtitle = "Earn \(bybitEarnCategoryLabel(position.category))"
                return ExchangeDetailRow(
                    title: position.coin,
                    subtitle: subtitle,
                    usdtValue: usdtValue,
                    valueText: usdtValue == nil ? "Price unavailable" : nil
                )
            }
            let total = rows.compactMap { $0.usdtValue }.reduce(0, +)
            sections.append(
                WalletTypeSection(
                    id: walletTypeID(accountID: accountID, title: "Earn"),
                    title: "Earn",
                    totalUSDT: total,
                    rows: rows
                )
            )
        } else if sections.isEmpty {
            sections.append(placeholderWalletTypeSection(accountID: accountID, title: "Wallets", message: "No data"))
        }
        return sections
    }

    private func bingxWalletTypeSections(for accountID: UUID) -> [WalletTypeSection] {
        let spotRows: [ExchangeDetailRow]
        if let wallet = bingxSpotWalletsByAccount[accountID],
           wallet.code == 0,
           let balances = wallet.data?.balances {
            spotRows = balances.map { balance in
                let total = (Double(balance.free) ?? 0) + (Double(balance.locked) ?? 0)
                let isUsdt = balance.asset.uppercased() == "USDT"
                return ExchangeDetailRow(
                    title: balance.asset,
                    subtitle: "Spot",
                    usdtValue: isUsdt ? total : nil,
                    valueText: isUsdt ? nil : "\(total) \(balance.asset)"
                )
            }
        } else {
            spotRows = []
        }

        let futuresRows: [ExchangeDetailRow]
        if let wallet = bingxFuturesWalletsByAccount[accountID],
           wallet.code == 0 {
            futuresRows = wallet.data.map { data in
                let usdtValue = Double(data.equity) ?? Double(data.balance)
                let isUsdt = data.asset.uppercased() == "USDT"
                return ExchangeDetailRow(
                    title: data.asset,
                    subtitle: "Futures",
                    usdtValue: isUsdt ? usdtValue : nil,
                    valueText: isUsdt ? nil : "\(data.balance) \(data.asset)"
                )
            }
        } else {
            futuresRows = []
        }

        let spotTotal = spotRows.compactMap { $0.usdtValue }.reduce(0, +)
        let futuresTotal = futuresRows.compactMap { $0.usdtValue }.reduce(0, +)
        let spotSection = WalletTypeSection(
            id: walletTypeID(accountID: accountID, title: "Spot"),
            title: "Spot",
            totalUSDT: spotRows.isEmpty ? nil : spotTotal,
            rows: spotRows.isEmpty ? [placeholderRow(message: "No USDT")] : spotRows
        )
        let futuresSection = WalletTypeSection(
            id: walletTypeID(accountID: accountID, title: "Futures"),
            title: "Futures",
            totalUSDT: futuresRows.isEmpty ? nil : futuresTotal,
            rows: futuresRows.isEmpty ? [placeholderRow(message: "No data")] : futuresRows
        )
        return [spotSection, futuresSection]
    }

    private func gateioWalletTypeSections(for accountID: UUID) -> [WalletTypeSection] {
        guard let wallet = gateioWalletsByAccount[accountID] else {
            return [placeholderWalletTypeSection(accountID: accountID, title: "Wallets", message: "No USDT")]
        }
        let sections = wallet.details
            .sorted { $0.key < $1.key }
            .compactMap { key, detail -> WalletTypeSection? in
                guard detail.currency.uppercased() == "USDT" else {
                    return nil
                }
                let usdtValue = Double(detail.amount)
                guard let amount = usdtValue, amount > 0 else {
                    return nil
                }
                let rows = [
                    ExchangeDetailRow(
                        title: "USDT",
                        subtitle: nil,
                        usdtValue: usdtValue,
                        valueText: usdtValue == nil ? "—" : nil
                    )
                ]
                return WalletTypeSection(
                    id: walletTypeID(accountID: accountID, title: key.capitalized),
                    title: key.capitalized,
                    totalUSDT: amount,
                    rows: rows
                )
            }
        return sections.isEmpty ? [placeholderWalletTypeSection(accountID: accountID, title: "Wallets", message: "No USDT")] : sections
    }

    private func okxWalletTypeSections(for accountID: UUID) -> [WalletTypeSection] {
        var sections: [WalletTypeSection] = []
        let tradingRows: [ExchangeDetailRow]
        if let wallet = okxWalletsByAccount[accountID] {
            tradingRows = wallet.data.flatMap { data in
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
        } else {
            tradingRows = []
        }
        let tradingTotal = tradingRows.compactMap { $0.usdtValue }.reduce(0, +)
        sections.append(
            WalletTypeSection(
                id: walletTypeID(accountID: accountID, title: "Trading"),
                title: "Trading",
                totalUSDT: tradingRows.isEmpty ? nil : tradingTotal,
                rows: tradingRows.isEmpty ? [placeholderRow(message: "No data")] : tradingRows
            )
        )

        let fundingRows: [ExchangeDetailRow]
        if let balances = okxFundingBalancesByAccount[accountID] {
            fundingRows = balances.map { balance in
                let amount = Double(balance.bal) ?? 0
                let isUsdt = balance.ccy.uppercased() == "USDT"
                return ExchangeDetailRow(
                    title: balance.ccy,
                    subtitle: "Funding",
                    usdtValue: isUsdt ? amount : nil,
                    valueText: isUsdt ? nil : "\(balance.bal) \(balance.ccy)"
                )
            }
        } else {
            fundingRows = []
        }
        let fundingTotal = fundingRows.compactMap { $0.usdtValue }.reduce(0, +)
        sections.append(
            WalletTypeSection(
                id: walletTypeID(accountID: accountID, title: "Funding"),
                title: "Funding",
                totalUSDT: fundingRows.isEmpty ? nil : fundingTotal,
                rows: fundingRows.isEmpty ? [placeholderRow(message: "No data")] : fundingRows
            )
        )
        return sections
    }

    private func bybitAccountTypeLabel(_ accountType: String) -> String {
        switch accountType.uppercased() {
        case "FUND":
            return "Funding"
        case "SPOT":
            return "Spot"
        case "CONTRACT":
            return "Derivatives"
        case "OPTION":
            return "Options"
        default:
            return accountType.capitalized
        }
    }

    private func placeholderRow(message: String) -> ExchangeDetailRow {
        ExchangeDetailRow(title: message, subtitle: nil, usdtValue: nil, valueText: nil)
    }

    private func placeholderWalletTypeSection(accountID: UUID, title: String, message: String) -> WalletTypeSection {
        WalletTypeSection(
            id: walletTypeID(accountID: accountID, title: title),
            title: title,
            totalUSDT: nil,
            rows: [placeholderRow(message: message)]
        )
    }

    private func walletTypeID(accountID: UUID, title: String) -> String {
        "\(accountID.uuidString)-\(title)"
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
