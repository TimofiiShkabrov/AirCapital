//
//  ExchangeDetailModels.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 02.02.2026.
//

import Foundation

struct ExchangeDetailRow: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let usdtValue: Double?
    let valueText: String?
}

struct ExchangeDetailSection: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let rows: [ExchangeDetailRow]
}

struct BybitEarnPositionItem: Identifiable, Hashable {
    let id = UUID()
    let category: String
    let coin: String
    let amount: String
    let status: String?
}
