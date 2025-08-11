//
//  UserDataBybit.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 08.08.2025.
//

import Foundation

// MARK: - UserDataBybit
struct UserDataBybit: Codable {
    let retCode: Int
    let retMsg: String
    let result: Result
    let retEXTInfo: RetEXTInfo
    let time: Int
    
    enum CodingKeys: String, CodingKey {
        case retCode, retMsg, result
        case retEXTInfo = "retExtInfo"
        case time
    }
    
    // MARK: - Result
    struct Result: Codable {
        let list: [List]
        
        // MARK: - List
        struct List: Codable {
            let totalEquity, accountIMRate, accountIMRateByMp, totalMarginBalance: String
            let totalInitialMargin, totalInitialMarginByMp, accountType, totalAvailableBalance: String
            let accountMMRate, accountMMRateByMp, totalPerpUPL, totalWalletBalance: String
            let accountLTV, totalMaintenanceMargin, totalMaintenanceMarginByMp: String
            let coin: [Coin]
        }
    }
    
    // MARK: - Coin
    struct Coin: Codable {
        let availableToBorrow, bonus, accruedInterest, availableToWithdraw: String
        let totalOrderIM, equity, totalPositionMM, usdValue: String
        let spotHedgingQty, unrealisedPnl: String
        let collateralSwitch: Bool
        let borrowAmount, totalPositionIM, walletBalance, cumRealisedPnl: String
        let locked: String
        let marginCollateral: Bool
        let coin: String
    }
    
    // MARK: - RetEXTInfo
    struct RetEXTInfo: Codable {
    }
}
