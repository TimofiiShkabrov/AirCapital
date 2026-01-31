//
//  UserDataBingx.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 12.08.2025.
//

import Foundation

// MARK: - UserDataBingxSpot
struct UserDataBingxSpot: Codable {
    let code: Int
    let msg, debugMsg: String?
    let data: DataClass?
}

struct DataClass: Codable {
    let balances: [Balance]
}

struct Balance: Codable {
    let asset, free, locked: String
}


// MARK: - UserDataBingxFutures
struct UserDataBingxFutures: Codable {
    let code: Int64
    let msg: String
    let data: [BingxFuturesData]
}

struct BingxFuturesData: Codable {
    let userId: String
    let asset: String
    let balance: String
    let equity: String
    let unrealizedProfit: String
    let realisedProfit: String
    let availableMargin: String
    let usedMargin: String
    let freezedMargin: String
    let shortUid: String
}
