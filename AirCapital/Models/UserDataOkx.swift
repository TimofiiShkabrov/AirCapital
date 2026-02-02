//
//  UserDataOkx.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 14.08.2025.
//

import Foundation

// MARK: - UserDataOkx
struct UserDataOkx: Codable, Sendable {
    let code: String
    let data: [Datum]
    let msg: String
}

// MARK: - Datum
struct Datum: Codable, Sendable {
    let adjEq, availEq, borrowFroz: String
    let details: [Detail]
    let imr, isoEq, mgnRatio, mmr: String
    let notionalUsd, notionalUsdForBorrow, notionalUsdForFutures, notionalUsdForOption: String
    let notionalUsdForSwap, ordFroz, totalEq, uTime: String
    let upl: String
}

// MARK: - Detail
struct Detail: Codable, Sendable {
    let autoLendStatus, autoLendMTAmt, availBAL, availEq: String
    let borrowFroz, cashBAL, ccy, crossLiab: String
    let colRes: String
    let collateralEnabled, collateralRestrict: Bool
    let colBorrAutoConversion, disEq, eq, eqUsd: String
    let smtSyncEq, spotCopyTradingEq, fixedBAL, frozenBAL: String
    let imr, interest, isoEq, isoLiab: String
    let isoUpl, liab, maxLoan, mgnRatio: String
    let mmr, notionalLever, ordFrozen, rewardBAL: String
    let spotInUseAmt, clSpotInUseAmt, maxSpotInUse, spotISOBAL: String
    let stgyEq, twap, uTime, upl: String
    let uplLiab, spotBAL, openAvgPx, accAvgPx: String
    let spotUpl, spotUplRatio, totalPnl, totalPnlRatio: String

    enum CodingKeys: String, CodingKey {
        case autoLendStatus
        case autoLendMTAmt = "autoLendMtAmt"
        case availBAL = "availBal"
        case availEq, borrowFroz
        case cashBAL = "cashBal"
        case ccy, crossLiab, colRes, collateralEnabled, collateralRestrict, colBorrAutoConversion, disEq, eq, eqUsd, smtSyncEq, spotCopyTradingEq
        case fixedBAL = "fixedBal"
        case frozenBAL = "frozenBal"
        case imr, interest, isoEq, isoLiab, isoUpl, liab, maxLoan, mgnRatio, mmr, notionalLever, ordFrozen
        case rewardBAL = "rewardBal"
        case spotInUseAmt, clSpotInUseAmt, maxSpotInUse
        case spotISOBAL = "spotIsoBal"
        case stgyEq, twap, uTime, upl, uplLiab
        case spotBAL = "spotBal"
        case openAvgPx, accAvgPx, spotUpl, spotUplRatio, totalPnl, totalPnlRatio
    }
}
