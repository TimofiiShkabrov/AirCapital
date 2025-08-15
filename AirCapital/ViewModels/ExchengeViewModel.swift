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
            let usdtBalance = balances.first { $0.asset == "" }
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
            let usdtBalance = wallet.data.first { $0.asset == "" }
            return partialResult + (Double(usdtBalance?.balance ?? "0") ?? 0)
        }
    }
    
    
    func loadData() {
        isLoading = true
        let group = DispatchGroup()
        
        group.enter()
        NetworkManager.shared.fetchPriceTickerBinance { [weak self] result in
            switch result {
            case .success(let data):
                self?.binancePrices = [data]
            case .failure(let error):
                self?.errorMessage = "\(error)"
                self?.alert = true
            }
            group.leave()
        }
        
        group.enter()
        NetworkManager.shared.fetchUserDataBinance { [weak self] result in
            switch result {
            case .success(let data):
                self?.binanceWallets = data
            case .failure(let error):
                self?.errorMessage = "\(error)"
                self?.alert = true
            }
            group.leave()
        }
        
        group.enter()
        NetworkManager.shared.fetchUserDataBybit { [weak self] result in
            switch result {
            case .success(let data):
                self?.bybitWallets = data.result.list
            case .failure(let error):
                self?.errorMessage = "\(error)"
                self?.alert = true
            }
            group.leave()
        }
        
        group.enter()
        NetworkManager.shared.fetchUserDataBingxSpot { [weak self] result in
            switch result {
            case .success(let data):
                self?.bingxSpotWallets = [data]
            case .failure(let error):
                self?.errorMessage = "\(error)"
                self?.alert = true
            }
            group.leave()
        }
        
        group.enter()
        NetworkManager.shared.fetchUserDataBingxFutures { [weak self] result in
            switch result {
            case .success(let data):
                self?.bingxFuturesWallets = [data]
            case .failure(let error):
                self?.errorMessage = "\(error)"
                self?.alert = true
            }
            group.leave()
        }
        
        group.enter()
        NetworkManager.shared.fetchUserDataGateio { [weak self] result in
            switch result {
            case .success(let data):
                self?.gateioWallets = [data]
            case .failure(let error):
                self?.errorMessage = "\(error)"
                self?.alert = true
            }
            group.leave()
        }
        
        group.enter()
        NetworkManager.shared.fetchUserDataOkx { [weak self] result in
            switch result {
            case .success(let data):
                self?.okxWallets = [data]
            case .failure(let error):
                self?.errorMessage = "\(error)"
                self?.alert = true
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
}
