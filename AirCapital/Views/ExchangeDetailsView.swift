//
//  ExchangeDetailsView.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 31.01.2026.
//

import SwiftUI

struct ExchangeDetailsView: View {
    let account: ExchangeAccount
    @Bindable var exchangeViewModel: ExchengeViewModel
    @State private var path: [WalletTypeSection] = []
    @State private var accountSnapshots: [BalanceSnapshot] = []
    @State private var selectedRange: ChartRange = .day

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    overviewCard
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.horizontal, 16)
                } header: {
                    sectionHeader("Overview")
                }

                Section {
                    Picker("Range", selection: $selectedRange) {
                        ForEach(ChartRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    BalanceChartView(snapshots: filteredAccountSnapshots, range: selectedRange)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.horizontal, 16)
                } header: {
                    sectionHeader("Balance")
                }

                Section {
                    let sections = exchangeViewModel.walletTypeSections(for: account)
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        Button {
                            path.append(section)
                        } label: {
                            WalletTypeRowView(
                                section: section,
                                isFirst: index == 0,
                                isLast: index == sections.count - 1
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.horizontal, 16)
                    }
                } header: {
                    sectionHeader("Wallets")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle(account.exchange.rawValue.capitalized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: WalletTypeSection.self) { section in
                WalletTypeDetailView(section: section, valueText: valueText(for:))
            }
        }
        .task {
            accountSnapshots = await BalanceHistoryStore.shared.snapshots(for: .account(account.id))
        }
        .onReceive(NotificationCenter.default.publisher(for: .balanceSnapshotsUpdated)) { _ in
            Task {
                accountSnapshots = await BalanceHistoryStore.shared.snapshots(for: .account(account.id))
            }
        }
    }

    private var filteredAccountSnapshots: [BalanceSnapshot] {
        let startDate = selectedRange.startDate()
        return accountSnapshots.filter { $0.timestamp >= startDate }
    }

    private func valueText(for row: ExchangeDetailRow) -> String {
        if let value = row.usdtValue {
            return String(format: "%.2f USDT", value)
        }
        if let valueText = row.valueText {
            return valueText
        }
        return "—"
    }

    private var overviewCard: some View {
        HStack(spacing: 12) {
            Image(account.exchange.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(account.exchange.rawValue.capitalized)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(accountLabel(for: account))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(exchangeViewModel.balanceUSDT(for: account), specifier: "%.2f") USDT")
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
    }


    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.leading, 16)
            .padding(.top, 8)
    }
}

#Preview {
    let account = ExchangeAccount(id: UUID(), exchange: .binance, label: nil, createdAt: Date())
    ExchangeDetailsView(account: account, exchangeViewModel: ExchengeViewModel())
}

private func accountLabel(for account: ExchangeAccount) -> String {
    if let label = account.label, label.isEmpty == false {
        return label
    }
    let accounts = APIKeysManager.accounts(for: account.exchange)
    let index = accounts.firstIndex(of: account).map { $0 + 1 } ?? 1
    return "Account \(index)"
}
