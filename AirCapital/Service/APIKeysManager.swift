//
//  APIKeysManager.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 26.08.2025.
//

import Foundation

enum Exchange: String, CaseIterable, Codable {
    case binance, bybit, bingx, okx, gateio
}

struct ExchangeAccount: Identifiable, Hashable, Codable {
    let id: UUID
    let exchange: Exchange
    let label: String?
    let createdAt: Date
}

struct APIKeys {
    let apiKey: String
    let secretKey: String
    let passphrase: String?
}

final class APIKeysManager {
    private static let accountsStorageKey = "aircapital.exchangeAccounts.v1"
    private static let migrationKey = "aircapital.exchangeAccounts.migrated.v1"

    static func allAccounts() -> [ExchangeAccount] {
        migrateLegacyKeysIfNeeded()
        let accounts = loadStoredAccounts()
        return sortAccounts(accounts)
    }

    static func accounts(for exchange: Exchange) -> [ExchangeAccount] {
        allAccounts().filter { $0.exchange == exchange }
    }

    @discardableResult
    static func save(_ keys: APIKeys, for exchange: Exchange, label: String?) -> ExchangeAccount {
        migrateLegacyKeysIfNeeded()
        var accounts = loadStoredAccounts()
        let cleanedLabel = label?.trimmingCharacters(in: .whitespacesAndNewlines)
        let account = ExchangeAccount(
            id: UUID(),
            exchange: exchange,
            label: cleanedLabel?.isEmpty == true ? nil : cleanedLabel,
            createdAt: Date()
        )
        saveKeys(keys, for: account)
        accounts.append(account)
        storeAccounts(accounts)
        return account
    }

    static func loadKeys(for account: ExchangeAccount) -> APIKeys? {
        guard let apiKey = KeychainHelper.load(accountKey(account, suffix: "apiKey")),
              let secretKey = KeychainHelper.load(accountKey(account, suffix: "secretKey")) else {
            return nil
        }
        let passphrase = KeychainHelper.load(accountKey(account, suffix: "passphrase"))
        return APIKeys(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase)
    }

    static func delete(account: ExchangeAccount) {
        var accounts = loadStoredAccounts()
        accounts.removeAll { $0.id == account.id }
        storeAccounts(accounts)
        KeychainHelper.delete(accountKey(account, suffix: "apiKey"))
        KeychainHelper.delete(accountKey(account, suffix: "secretKey"))
        KeychainHelper.delete(accountKey(account, suffix: "passphrase"))
    }

    // MARK: - Migration
    private static func migrateLegacyKeysIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: migrationKey) == false else {
            return
        }
        var accounts = loadStoredAccounts()
        for exchange in Exchange.allCases {
            guard let legacyKeys = loadLegacyKeys(for: exchange) else {
                continue
            }
            let account = ExchangeAccount(
                id: UUID(),
                exchange: exchange,
                label: nil,
                createdAt: Date()
            )
            saveKeys(legacyKeys, for: account)
            accounts.append(account)
            deleteLegacyKeys(for: exchange)
        }
        storeAccounts(accounts)
        defaults.set(true, forKey: migrationKey)
    }

    // MARK: - Storage
    private static func loadStoredAccounts() -> [ExchangeAccount] {
        guard let data = UserDefaults.standard.data(forKey: accountsStorageKey) else {
            return []
        }
        return (try? JSONDecoder().decode([ExchangeAccount].self, from: data)) ?? []
    }

    private static func storeAccounts(_ accounts: [ExchangeAccount]) {
        guard let data = try? JSONEncoder().encode(accounts) else {
            return
        }
        UserDefaults.standard.set(data, forKey: accountsStorageKey)
    }

    private static func sortAccounts(_ accounts: [ExchangeAccount]) -> [ExchangeAccount] {
        accounts.sorted { lhs, rhs in
            if lhs.exchange == rhs.exchange {
                return lhs.createdAt < rhs.createdAt
            }
            let lhsIndex = Exchange.allCases.firstIndex(of: lhs.exchange) ?? 0
            let rhsIndex = Exchange.allCases.firstIndex(of: rhs.exchange) ?? 0
            return lhsIndex < rhsIndex
        }
    }

    private static func accountKey(_ account: ExchangeAccount, suffix: String) -> String {
        "account_\(account.id.uuidString)_\(suffix)"
    }

    private static func saveKeys(_ keys: APIKeys, for account: ExchangeAccount) {
        KeychainHelper.save(accountKey(account, suffix: "apiKey"), value: keys.apiKey)
        KeychainHelper.save(accountKey(account, suffix: "secretKey"), value: keys.secretKey)
        if let passphrase = keys.passphrase {
            KeychainHelper.save(accountKey(account, suffix: "passphrase"), value: passphrase)
        }
    }

    private static func loadLegacyKeys(for exchange: Exchange) -> APIKeys? {
        guard let apiKey = KeychainHelper.load("\(exchange.rawValue)_apiKey"),
              let secretKey = KeychainHelper.load("\(exchange.rawValue)_secretKey") else {
            return nil
        }
        let passphrase = KeychainHelper.load("\(exchange.rawValue)_passphrase")
        return APIKeys(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase)
    }

    private static func deleteLegacyKeys(for exchange: Exchange) {
        KeychainHelper.delete("\(exchange.rawValue)_apiKey")
        KeychainHelper.delete("\(exchange.rawValue)_secretKey")
        KeychainHelper.delete("\(exchange.rawValue)_passphrase")
    }
}

extension Notification.Name {
    static let apiKeysInvalidated = Notification.Name("apiKeysInvalidated")
}
