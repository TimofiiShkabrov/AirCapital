//
//  ExchangeView.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 04.08.2025.
//

import SwiftUI

struct ExchangeView: View {
    
    let networkManager = NetworkManager.shared
    @State private var userDataBinance = [UserDataBinance]()
    @State private var isLoading = false
    @State private var alert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            List(userDataBinance, id: \.walletName) { item in
                HStack {
                    Text(item.walletName)
                    Spacer()
                    Text(item.balance)
                }
            }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .alert("Ошибка", isPresented: $alert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            isLoading = true
            networkManager.fetchUserDataBinance(from: Link.userDataBinance.url) { result in
                isLoading = false
                switch result {
                case .success(let data):
                    userDataBinance = data
                case .failure(let error):
                    errorMessage = warningMassage(error: error)
                    alert = true
                }
            }
        }
    }
}

#Preview {
    ExchangeView()
}
