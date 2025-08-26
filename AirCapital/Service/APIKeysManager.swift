//
//  APIKeysManager.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 26.08.2025.
//

import Foundation

enum Exchange: String, CaseIterable {
    case binance, bybit, bingx, okx, gateio
}

struct APIKeys {
    let apiKey: String
    let secretKey: String
    let passphrase: String?
}

final class APIKeysManager {
    static func save(_ keys: APIKeys, for exchange: Exchange) {
        KeychainHelper.save("\(exchange.rawValue)_apiKey", value: keys.apiKey)
        KeychainHelper.save("\(exchange.rawValue)_secretKey", value: keys.secretKey)
        if let passphrase = keys.passphrase {
            KeychainHelper.save("\(exchange.rawValue)_passphrase", value: passphrase)
        }
    }
    
    static func load(for exchange: Exchange) -> APIKeys? {
        guard let apiKey = KeychainHelper.load("\(exchange.rawValue)_apiKey"),
              let secretKey = KeychainHelper.load("\(exchange.rawValue)_secretKey") else {
            return nil
        }
        let passphrase = KeychainHelper.load("\(exchange.rawValue)_passphrase")
        return APIKeys(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase)
    }
}
