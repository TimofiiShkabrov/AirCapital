//
//  HomeViewModel.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 29.08.2025.
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private var exchangeViewModel: ExchengeViewModel

    init(exchangeViewModel: ExchengeViewModel) {
        self.exchangeViewModel = exchangeViewModel
    }
    
    var totalBalanceUSDT: Double {
        exchangeViewModel.totalBalanceUSDT
    }

    var hasConnectedExchanges: Bool {
        !exchangeViewModel.enabledAccounts.isEmpty
    }
}
