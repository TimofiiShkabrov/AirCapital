//
//  BalanceSnapshot.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 02.02.2026.
//

import Foundation

struct BalanceSnapshot: Identifiable, Codable, Hashable {
    let id: UUID
    let scope: BalanceScope
    let timestamp: Date
    let balanceUSDT: Double

    init(scope: BalanceScope, timestamp: Date = Date(), balanceUSDT: Double) {
        self.id = UUID()
        self.scope = scope
        self.timestamp = timestamp
        self.balanceUSDT = balanceUSDT
    }
}

enum BalanceScope: Codable, Hashable {
    case total
    case account(UUID)
    case exchange(Exchange)

    private enum CodingKeys: String, CodingKey {
        case type
        case accountId
        case exchange
    }

    private enum ScopeType: String, Codable {
        case total
        case account
        case exchange
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ScopeType.self, forKey: .type)
        switch type {
        case .total:
            self = .total
        case .account:
            let id = try container.decode(UUID.self, forKey: .accountId)
            self = .account(id)
        case .exchange:
            let exchange = try container.decode(Exchange.self, forKey: .exchange)
            self = .exchange(exchange)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .total:
            try container.encode(ScopeType.total, forKey: .type)
        case .account(let id):
            try container.encode(ScopeType.account, forKey: .type)
            try container.encode(id, forKey: .accountId)
        case .exchange(let exchange):
            try container.encode(ScopeType.exchange, forKey: .type)
            try container.encode(exchange, forKey: .exchange)
        }
    }
}
