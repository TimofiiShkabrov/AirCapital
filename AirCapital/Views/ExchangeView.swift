//
//  ExchangeView.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 04.08.2025.
//

import SwiftUI

struct ExchangeView: View {
    @State private var exchangeViewModel = ExchengeViewModel()
    
    var body: some View {
        VStack {
            if let bybit = exchangeViewModel.bybitWallets.first?.coin.first {
                HStack {
                    Text("Binance total balance: ")
                    Spacer()
                    Text("\(Double(bybit.walletBalance) ?? 0, specifier: "%.2f") USDT")
                }
            }
            HStack {
                Text("Binance total balance: ")
                Spacer()
                Text("\((exchangeViewModel.binanceTotalBalance), specifier: "%.2f") USDT")
            }
        }
        .overlay {
            if exchangeViewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Ошибка", isPresented: $exchangeViewModel.alert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exchangeViewModel.errorMessage)
        }
        .task {
            exchangeViewModel.loadData()
        }
    }
}

#Preview {
    ExchangeView()
}
