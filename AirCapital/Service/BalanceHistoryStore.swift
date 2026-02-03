//
//  BalanceHistoryStore.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 02.02.2026.
//

import Foundation

actor BalanceHistoryStore {
    static let shared = BalanceHistoryStore()
    private init() {}

    private let fileName = "balanceSnapshots.json"

    func snapshots(for scope: BalanceScope) -> [BalanceSnapshot] {
        let all = loadSnapshots()
        let scoped = all.filter { $0.scope == scope }.sorted { $0.timestamp < $1.timestamp }
        return filteredSnapshots(scoped)
    }

    func snapshots(for scope: BalanceScope, range: ChartRange) -> [BalanceSnapshot] {
        let all = loadSnapshots()
        let start = range.startDate()
        let scoped = all
            .filter { $0.scope == scope && $0.timestamp >= start }
            .sorted { $0.timestamp < $1.timestamp }
        return filteredSnapshots(scoped)
    }

    func addSnapshot(scope: BalanceScope, balanceUSDT: Double) {
        var snapshots = loadSnapshots()
        let now = Date()
        if let lastIndex = snapshots.lastIndex(where: { $0.scope == scope }) {
            let last = snapshots[lastIndex]
            if balanceUSDT == 0, last.balanceUSDT > 0, now.timeIntervalSince(last.timestamp) < 60 * 10 {
                return
            }
            if now.timeIntervalSince(last.timestamp) < 60 * 30 {
                snapshots[lastIndex] = BalanceSnapshot(scope: scope, timestamp: now, balanceUSDT: balanceUSDT)
            } else {
                snapshots.append(BalanceSnapshot(scope: scope, timestamp: now, balanceUSDT: balanceUSDT))
            }
        } else {
            if balanceUSDT == 0 {
                return
            }
            snapshots.append(BalanceSnapshot(scope: scope, timestamp: now, balanceUSDT: balanceUSDT))
        }
        saveSnapshots(snapshots)
        Task { @MainActor in
            NotificationCenter.default.post(name: .balanceSnapshotsUpdated, object: nil)
        }
    }

    func addSnapshots(
        total: Double,
        accounts: [ExchangeAccount],
        balances: [UUID: Double],
        exchangeTotals: [Exchange: Double]
    ) {
        addSnapshot(scope: .total, balanceUSDT: total)
        for account in accounts {
            let balance = balances[account.id] ?? 0
            addSnapshot(scope: .account(account.id), balanceUSDT: balance)
        }
        for (exchange, total) in exchangeTotals {
            addSnapshot(scope: .exchange(exchange), balanceUSDT: total)
        }
    }

    private func loadSnapshots() -> [BalanceSnapshot] {
        guard let url = fileURL(),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([BalanceSnapshot].self, from: data)) ?? []
    }

    private func saveSnapshots(_ snapshots: [BalanceSnapshot]) {
        guard let url = fileURL() else {
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(snapshots) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func fileURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }

    private func filteredSnapshots(_ snapshots: [BalanceSnapshot]) -> [BalanceSnapshot] {
        let hasNonZero = snapshots.contains { $0.balanceUSDT > 0.000001 }
        if hasNonZero {
            return snapshots.filter { $0.balanceUSDT > 0.000001 }
        }
        return snapshots
    }
}

extension Notification.Name {
    static let balanceSnapshotsUpdated = Notification.Name("balanceSnapshotsUpdated")
}
