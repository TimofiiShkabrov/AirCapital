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
    var isLoading = false
    var errorMessage = ""
    var alert = false
    
    var binanceTotalBalance: Double {
        binanceWallets.reduce(0) { partialResult, wallet in
            partialResult + (Double(wallet.balance) ?? 0)
        }
    }
    
    func loadData() {
        isLoading = true
        let group = DispatchGroup()
        
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
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
}
