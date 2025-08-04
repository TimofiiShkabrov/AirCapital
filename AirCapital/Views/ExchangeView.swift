//
//  ExchangeView.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 04.08.2025.
//

import SwiftUI

struct ExchangeView: View {
    
    @Bindable var networkManager = NetworkManager.shared
    
    var totalBalance: Double {
        networkManager.userDataBinance
            .compactMap { Double($0.balance) }
            .reduce(0, +)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Total Balance: \(totalBalance, specifier: "%.2f")")
                    .font(.headline)
                    .padding()
            }
            List(networkManager.userDataBinance, id: \.walletName) { item in
                HStack {
                    Text(item.walletName)
                    Spacer()
                    Text(item.balance)
                }
            }
        }
        .onAppear {
            networkManager.fetchUserDataBinance()
        }
    }
}

#Preview {
    ExchangeView()
}
