//
//  UserDataBingx.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 12.08.2025.
//

import Foundation

// MARK: - UserDataBingxSpot
struct UserDataBingxSpot: Codable, Sendable {
    let code: Int
    let msg, debugMsg: String?
    let data: DataClass?
}

struct DataClass: Codable, Sendable {
    let balances: [Balance]
}

struct Balance: Codable, Sendable {
    let asset, free, locked: String
}


// MARK: - UserDataBingxFutures
struct UserDataBingxFutures: Codable, Sendable {
    let code: Int64
    let msg: String
    let data: [BingxFuturesData]
}

struct BingxFuturesData: Codable, Sendable {
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
