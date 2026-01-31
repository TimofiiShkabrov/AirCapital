//
//  ExchengeViewModel.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 09.08.2025.
//

import Foundation
import Observation

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
            errorMessage = "Неверные API ключи для \(exchange.rawValue.capitalized)"
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
}
