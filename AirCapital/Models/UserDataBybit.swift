//
//  UserDataBybit.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 08.08.2025.
//

import Foundation

// MARK: - UserDataBybit
struct UserDataBybit: Codable, Sendable {
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
    struct Result: Codable, Sendable {
        let list: [List]
        
        // MARK: - List
        struct List: Codable, Sendable {
            let totalEquity, accountIMRate, accountIMRateByMp, totalMarginBalance: String
            let totalInitialMargin, totalInitialMarginByMp, accountType, totalAvailableBalance: String
            let accountMMRate, accountMMRateByMp, totalPerpUPL, totalWalletBalance: String
            let accountLTV, totalMaintenanceMargin, totalMaintenanceMarginByMp: String
            let coin: [Coin]
        }
    }
    
    // MARK: - Coin
    struct Coin: Codable, Sendable {
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
    struct RetEXTInfo: Codable, Sendable {
    }
}

// MARK: - Bybit Earn Positions
struct BybitEarnPositionResponse: Codable, Sendable {
    let retCode: Int
    let retMsg: String
    let result: Result?
    let retExtInfo: RetExtInfo?
    let time: Int?

    struct Result: Codable, Sendable {
        let list: [Position]
    }

    struct Position: Codable, Sendable {
        let coin: String
        let productId: String?
        let amount: String
        let totalPnl: String?
        let claimableYield: String?
        let id: String?
        let status: String?
        let orderId: String?
        let estimateRedeemTime: String?
        let estimateStakeTime: String?
        let estimateInterestCalculationTime: String?
        let settlementTime: String?
    }

    struct RetExtInfo: Codable, Sendable {
    }
}
