//
//  ExchangeView.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 04.08.2025.
//

import SwiftUI

struct ExchangeView: View {
    @Bindable var exchangeViewModel: ExchengeViewModel
    @Binding var showSettings: Bool
    @State private var selectedAccount: ExchangeAccount?
    @State private var totalSnapshots: [BalanceSnapshot] = []
    @State private var selectedRange: ChartRange = .day
    @State private var showInitialLoading = true

    var body: some View {
        let accounts = exchangeViewModel.enabledAccounts
        let isShowingLoading = exchangeViewModel.isLoading || showInitialLoading
        ZStack {
            LiquidBackground()
            NavigationSplitView {
                List(selection: $selectedAccount) {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Range", selection: $selectedRange) {
                                ForEach(ChartRange.allCases) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)

                            LabeledContent {
                                Text("\(exchangeViewModel.totalBalanceUSDT, specifier: "%.2f") USDT")
                                    .font(.title3.weight(.semibold))
                                    .monospacedDigit()
                            } label: {
                                Text("All Accounts")
                            }
                            BalanceChartView(snapshots: totalSnapshots, range: selectedRange)
                        }
                        .padding(.vertical, 6)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.horizontal, 16)
                        .background(
                            LiquidSurface(shape: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        )
                    } header: {
                        LiquidSectionHeader(title: "Total Balance")
                    }

                    Section {
                        ForEach(accounts) { account in
                            NavigationLink(value: account) {
                                accountRow(for: account)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(
                                LiquidSurface(
                                    shape: RoundedRectangle(cornerRadius: 18, style: .continuous),
                                    shadow: false,
                                    shadowRadius: 0,
                                    shadowY: 0
                                )
                            )
                        }
                    } header: {
                        LiquidSectionHeader(title: "Accounts")
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(
                    LiquidBackground()
                )
                .background(Color.clear)
                .navigationTitle("AirCapital")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "gear")
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .refreshable {
                    await withCheckedContinuation { continuation in
                        exchangeViewModel.loadData {
                            continuation.resume()
                        }
                    }
                }
                .navigationDestination(for: ExchangeAccount.self) { account in
                    ExchangeDetailsView(account: account, exchangeViewModel: exchangeViewModel)
                }
            } detail: {
                detailsPane(for: accounts)
            }
            .background(
                LiquidBackground()
            )
            .background(Color.clear)
        }
        .overlay {
            if isShowingLoading {
                DepositLoadingView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isShowingLoading)
        .alert("Error", isPresented: $exchangeViewModel.alert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exchangeViewModel.errorMessage)
        }
        .task {
            await withCheckedContinuation { continuation in
                exchangeViewModel.loadData {
                    showInitialLoading = false
                    continuation.resume()
                }
            }
            await reloadSnapshots()
        }
        .onReceive(NotificationCenter.default.publisher(for: .balanceSnapshotsUpdated)) { _ in
            Task { await reloadSnapshots() }
        }
        .onChange(of: selectedRange) { _, _ in
            // Filtering is local; no reload needed.
        }
        .onChange(of: accounts) { _, newValue in
            if let selected = selectedAccount, newValue.contains(selected) == false {
                selectedAccount = nil
            }
        }
    }

    @MainActor
    private func reloadSnapshots() async {
        totalSnapshots = await BalanceHistoryStore.shared.snapshots(for: .total)
    }

    private func accountRow(for account: ExchangeAccount) -> some View {
        let balance = exchangeViewModel.balanceUSDT(for: account)
        return HStack(spacing: 12) {
            Image(account.exchange.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.exchange.rawValue.capitalized)
                    .font(.body.weight(.medium))
                let label = accountLabel(for: account)
                if label.isEmpty == false {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(balance, specifier: "%.2f") USDT")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func detailsPane(for accounts: [ExchangeAccount]) -> some View {
        if accounts.isEmpty {
            ContentUnavailableView(
                "No Exchanges",
                systemImage: "creditcard",
                description: Text("Add an exchange in Settings.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
        } else if let account = selectedAccount {
            ExchangeDetailsView(account: account, exchangeViewModel: exchangeViewModel)
        } else {
            ContentUnavailableView(
                "No Exchange Selected",
                systemImage: "bitcoinsign.circle",
                description: Text("Choose an account from the list.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
        }
    }

}

#Preview {
    ExchangeView(exchangeViewModel: ExchengeViewModel(), showSettings: .constant(false))
}

private func accountLabel(for account: ExchangeAccount) -> String {
    if let label = account.label, label.isEmpty == false {
        return label
    }
    let accounts = APIKeysManager.accounts(for: account.exchange)
    let index = accounts.firstIndex(of: account).map { $0 + 1 } ?? 1
    return "Account \(index)"
}
