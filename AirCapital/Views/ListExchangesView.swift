//
//  ListExchangesView.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 04.08.2025.
//

import SwiftUI

struct ListExchangesView: View {
    
    @State private var userDataBinance = UserDataBinance.example
    
    var totalBalance: Double {
        userDataBinance
            .compactMap { Double($0.balance) }
            .reduce(0, +)
    }
    
    var body: some View {
        HStack {
            Text("Binence")
            Spacer()
            Text("\(totalBalance, specifier: "%.2f")")
        }
        .padding()
    }
}

#Preview {
    ListExchangesView()
}
