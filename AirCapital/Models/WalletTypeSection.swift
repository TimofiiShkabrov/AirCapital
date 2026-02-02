//
//  WalletTypeSection.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 02.02.2026.
//

import Foundation

struct WalletTypeSection: Identifiable, Hashable {
    let id: String
    let title: String
    let totalUSDT: Double?
    let rows: [ExchangeDetailRow]
}
