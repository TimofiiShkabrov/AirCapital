//
//  ExchangeView.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 04.08.2025.
//

import SwiftUI

struct ExchangeView: View {
    
    @Bindable var exchangeViewModel: ExchengeViewModel
    
    var body: some View {
        List {
            ForEach(exchangeViewModel.enabledExchanges, id: \.self) { exchange in
                exchangeRow(for: exchange)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await withCheckedContinuation { continuation in
                exchangeViewModel.loadData {
                    continuation.resume()
                }
            }
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
    }

    @ViewBuilder
    private func exchangeRow(for exchange: Exchange) -> some View {
        let balance = exchangeViewModel.balanceUSDT(for: exchange)
        HStack {
            Image(exchange.rawValue)
                .resizable()
                .scaledToFit()
                .frame(height: 64)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text("\(balance, specifier: "%.2f") USDT")
                .font(.system(.subheadline, design: .monospaced, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

#Preview {
    ExchangeView(exchangeViewModel: ExchengeViewModel())
}
