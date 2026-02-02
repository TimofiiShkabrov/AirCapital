//
//  BybitAllCoinsBalance.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 02.02.2026.
//

import Foundation

struct BybitAllCoinsBalanceResponse: Codable, Sendable {
    let retCode: Int
    let retMsg: String
    let result: BybitAllCoinsBalanceResult?
}

struct BybitAllCoinsBalanceResult: Codable, Sendable {
    let memberId: String?
    let accountType: String
    let balance: [BybitCoinBalance]
}

struct BybitCoinBalance: Codable, Sendable, Hashable, Identifiable {
    var id: String { coin }
    let coin: String
    let walletBalance: String
    let transferBalance: String?
    let bonus: String?
}
