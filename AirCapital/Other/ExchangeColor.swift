//
//  ExchangeColor.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 02.02.2026.
//

import SwiftUI

enum ExchangeColor {
    static func color(for exchange: Exchange) -> Color {
        switch exchange {
        case .binance:
            return Color(red: 0.953, green: 0.725, blue: 0.184) // #F3BA2F
        case .bybit:
            return Color(red: 0.969, green: 0.639, blue: 0.000) // #F7A300
        case .bingx:
            return Color(red: 0.149, green: 0.396, blue: 0.980) // #2665FA
        case .okx:
            return Color(red: 0.110, green: 0.110, blue: 0.110) // #1C1C1C
        case .gateio:
            return Color(red: 0.247, green: 0.478, blue: 0.988) // #3F7AFD
        }
    }
}
