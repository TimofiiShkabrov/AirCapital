//
//  UserDataGateio.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 13.08.2025.
//

import Foundation

// MARK: - UserDataGateio
struct UserDataGateio: Codable, Sendable {
    let details: [String: Account]
    let total: Total
}

// MARK: - Account
struct Account: Codable, Sendable {
    let currency: String
    let amount: String
    let unrealisedPnl: String?
    let borrowed: String?

    enum CodingKeys: String, CodingKey {
        case currency, amount, borrowed
        case unrealisedPnl = "unrealised_pnl"
    }
}

// MARK: - Total
struct Total: Codable, Sendable {
    let amount, currency, borrowed: String
    let unrealisedPnl: String?

    enum CodingKeys: String, CodingKey {
        case amount, currency, borrowed
        case unrealisedPnl = "unrealised_pnl"
    }
}
