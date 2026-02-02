//
//  HomeView.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 04.08.2025.
//

import SwiftUI

struct HomeView: View {
    
    @State private var exchangeViewModel: ExchengeViewModel
    @State private var homeViewModel: HomeViewModel
    @State private var showSettings = false
    
    init() {
        let exchangeVM = ExchengeViewModel()
        _exchangeViewModel = State(initialValue: exchangeVM)
        _homeViewModel = State(initialValue: HomeViewModel(exchangeViewModel: exchangeVM))
    }
    
    var body: some View {
        Group {
            if homeViewModel.hasConnectedExchanges == false {
                NavigationStack {
                    ContentUnavailableView {
                        Label("No Exchanges", systemImage: "creditcard")
                    } description: {
                        Text("Add the first exchange in Settings.")
                    } actions: {
                        Button("Open Settings") {
                            showSettings.toggle()
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
                }
            } else {
                ExchangeView(exchangeViewModel: exchangeViewModel, showSettings: $showSettings)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: showSettings) { _, isPresented in
            if isPresented == false {
                exchangeViewModel.loadData()
            }
        }
    }
}

#Preview {
    HomeView()
}
