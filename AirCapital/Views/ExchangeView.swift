//
//  ExchangeView.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 04.08.2025.
//

import SwiftUI

struct ExchangeView: View {
    
    @Bindable var networkManager = NetworkManager()
    
    var body: some View {
        ZStack {
            List(networkManager.userDataBinance, id: \.walletName) { item in
                HStack {
                    Text(item.walletName)
                    Spacer()
                    Text(item.balance)
                }
            }
            if networkManager.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .alert("Error", isPresented: $networkManager.alert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(networkManager.errorMessage)
        }
        .task {
            await networkManager.fetchUserDataBinance()
        }
    }
}

#Preview {
    ExchangeView()
}
