//
//  ExchangeView.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 04.08.2025.
//

import SwiftUI

struct ExchangeView: View {
    
    @Bindable var networkManager = NetworkManager.shared
    @State var userDataBinance: [UserDataBinance] = []
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
            ProgressView()
                .progressViewStyle(.circular)
                .opacity(isLoading ? 1 : 0)
        }
        .alert(isPresented: $alert, content: {
            Alert(title: Text("Error"), message: Text("\(errorMessage)"), dismissButton: .default(Text("OK")))
        })
        .onAppear {
            isLoading = true
            networkManager.fetchUserDataBinance { result in
                switch result {
                case .success(let decodedUserDataBinance):
                    userDataBinance = decodedUserDataBinance
                    isLoading = false
                    print("Success decoded")
                case .failure(let networkError):
                    errorMessage = warningMassage(error: networkError)
                    alert = true
                    isLoading = false
                    print("Error: \(networkError)")
                }
            }
        }
    }
}

#Preview {
    ExchangeView()
}
