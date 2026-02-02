//
//  SettingsViewModel.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 26.08.2025.
//

import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var selectedExchange: Exchange = .binance
    var accountLabel: String = ""
    var apiKey: String = ""
    var secretKey: String = ""
    var passphrase: String = ""
    var showSavedAlert = false
    private var invalidationObserver: NSObjectProtocol?
    
    var savedAccounts: [ExchangeAccount] {
        APIKeysManager.allAccounts()
    }

    init() {
        invalidationObserver = NotificationCenter.default.addObserver(
            forName: .apiKeysInvalidated,
            object: nil,
            queue: .main
        ) { notification in
            guard let exchange = notification.object as? Exchange else {
                return
            }
            Task { @MainActor [weak self] in
                guard let self, exchange == self.selectedExchange else {
                    return
                }
                self.apiKey = ""
                self.secretKey = ""
                self.passphrase = ""
            }
        }
    }

    func loadKeys() {
        accountLabel = ""
        apiKey = ""
        secretKey = ""
        passphrase = ""
    }
    
    func saveKeys() {
        let keys = APIKeys(apiKey: apiKey, secretKey: secretKey,
                           passphrase: passphrase.isEmpty ? nil : passphrase)
        APIKeysManager.save(keys, for: selectedExchange, label: accountLabel)
        accountLabel = ""
        apiKey = ""
        secretKey = ""
        passphrase = ""
        showSavedAlert = true
    }
}
