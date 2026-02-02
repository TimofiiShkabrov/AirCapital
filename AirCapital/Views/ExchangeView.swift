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
    @State private var selectedExchange: Exchange?

    var body: some View {
        let exchanges = exchangeViewModel.enabledExchanges

        NavigationSplitView {
            List(selection: $selectedExchange) {
                Section("Total Balance") {
                    LabeledContent {
                        Text("\(exchangeViewModel.totalBalanceUSDT, specifier: "%.2f") USDT")
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                    } label: {
                        Text("All Exchanges")
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    )
                }

                Section("Exchanges") {
                    ForEach(exchanges, id: \.self) { exchange in
                        NavigationLink(value: exchange) {
                            exchangeRow(for: exchange)
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
        } detail: {
            detailsPane(for: exchanges)
        }
        .navigationDestination(for: Exchange.self) { exchange in
            ExchangeDetailsView(exchange: exchange, exchangeViewModel: exchangeViewModel)
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
        .onChange(of: exchanges) { _, newValue in
            if let selected = selectedExchange, newValue.contains(selected) == false {
                selectedExchange = nil
            }
        }
    }

    private func exchangeRow(for exchange: Exchange) -> some View {
        let balance = exchangeViewModel.balanceUSDT(for: exchange)
        return HStack(spacing: 12) {
            Image(exchange.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            Text(exchange.rawValue.capitalized)
                .font(.body.weight(.medium))
            Spacer()
            Text("\(balance, specifier: "%.2f") USDT")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func detailsPane(for exchanges: [Exchange]) -> some View {
        if exchanges.isEmpty {
            ContentUnavailableView(
                "No Exchanges",
                systemImage: "creditcard",
                description: Text("Add an exchange in Settings.")
            )
        } else if let exchange = selectedExchange {
            ExchangeDetailsView(exchange: exchange, exchangeViewModel: exchangeViewModel)
        } else {
            ContentUnavailableView(
                "No Exchange Selected",
                systemImage: "bitcoinsign.circle",
                description: Text("Choose an exchange from the list.")
            )
        }
    }

}

#Preview {
    ExchangeView(exchangeViewModel: ExchengeViewModel(), showSettings: .constant(false))
}
