//
//  HomeView.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 04.08.2025.
//

import SwiftUI

struct HomeView: View {
    
    @State private var homeViewModel = HomeViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // If there are no added exchanges
                if settingsViewModel.savedExchanges.isEmpty {
                    VStack(spacing: 12) {
                        Text("Welcome to AirCapital 🚀")
                            .font(.title3.bold())
                        Text("Add the first exchange in the settings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            showSettings.toggle()
                        } label: {
                            Label("Go to settings", systemImage: "gear")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    
                    // MARK: - Total Balance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Balance")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("\(homeViewModel.totalBalanceUSDT, specifier: "%.2f") USDT")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                    
                    // MARK: - Exchanges
                    ExchangeView()
                        .frame(maxHeight: .infinity)
                }
            }
            .navigationTitle("Dashboard")
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    HomeView()
}
