//
//  SettingsViewModel.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 26.08.2025.
//

import Foundation
import Observation

@Observable
final class SettingsViewModel {
    var selectedExchange: Exchange = .binance
    var apiKey: String = ""
    var secretKey: String = ""
    var passphrase: String = ""
    var showSavedAlert = false
    
    var savedExchanges: [Exchange] {
            Exchange.allCases.filter { APIKeysManager.load(for: $0) != nil }
        }
    
    func loadKeys() {
        if let keys = APIKeysManager.load(for: selectedExchange) {
            apiKey = keys.apiKey
            secretKey = keys.secretKey
            passphrase = keys.passphrase ?? ""
        } else {
            apiKey = ""
            secretKey = ""
            passphrase = ""
        }
    }
    
    func saveKeys() {
        let keys = APIKeys(apiKey: apiKey, secretKey: secretKey,
                           passphrase: passphrase.isEmpty ? nil : passphrase)
        APIKeysManager.save(keys, for: selectedExchange)
        showSavedAlert = true
    }
}
