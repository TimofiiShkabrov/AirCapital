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

    var body: some View {
        let accounts = exchangeViewModel.enabledAccounts

        NavigationSplitView {
            List(selection: $selectedAccount) {
                Section("Total Balance") {
                    LabeledContent {
                        Text("\(exchangeViewModel.totalBalanceUSDT, specifier: "%.2f") USDT")
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                    } label: {
                        Text("All Accounts")
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    )
                }

                Section("Accounts") {
                    ForEach(accounts) { account in
                        NavigationLink(value: account) {
                            accountRow(for: account)
                        }
                    }
                }
            }
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
        .overlay {
            if exchangeViewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: $exchangeViewModel.alert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exchangeViewModel.errorMessage)
        }
        .task {
            exchangeViewModel.loadData()
        }
        .onChange(of: accounts) { _, newValue in
            if let selected = selectedAccount, newValue.contains(selected) == false {
                selectedAccount = nil
            }
        }
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
        } else if let account = selectedAccount {
            ExchangeDetailsView(account: account, exchangeViewModel: exchangeViewModel)
        } else {
            ContentUnavailableView(
                "No Exchange Selected",
                systemImage: "bitcoinsign.circle",
                description: Text("Choose an account from the list.")
            )
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
