//
//  SettingsViewModel.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 26.08.2025.
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
    private var invalidationObserver: NSObjectProtocol?
    
    var savedExchanges: [Exchange] {
            Exchange.allCases.filter { APIKeysManager.load(for: $0) != nil }
        }

    init() {
        invalidationObserver = NotificationCenter.default.addObserver(
            forName: .apiKeysInvalidated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let exchange = notification.object as? Exchange else {
                return
            }
            guard exchange == self?.selectedExchange else {
                return
            }
            self?.apiKey = ""
            self?.secretKey = ""
            self?.passphrase = ""
        }
    }

    deinit {
        if let observer = invalidationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func loadKeys() {
        apiKey = ""
        secretKey = ""
        passphrase = ""
    }
    
    func saveKeys() {
        let keys = APIKeys(apiKey: apiKey, secretKey: secretKey,
                           passphrase: passphrase.isEmpty ? nil : passphrase)
        APIKeysManager.save(keys, for: selectedExchange)
        apiKey = ""
        secretKey = ""
        passphrase = ""
        showSavedAlert = true
    }
}
