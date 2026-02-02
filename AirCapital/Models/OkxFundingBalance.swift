//
//  OkxFundingBalance.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 02.02.2026.
//

import Foundation

struct OkxFundingBalanceResponse: Codable, Sendable {
    let code: String
    let msg: String
    let data: [OkxFundingBalance]
}

struct OkxFundingBalance: Codable, Sendable, Hashable, Identifiable {
    var id: String { ccy }
    let ccy: String
    let bal: String
    let availBal: String
    let frozenBal: String
}
