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
        ZStack {
            LiquidBackground()
            Group {
                if homeViewModel.hasConnectedExchanges == false {
                    NavigationStack {
                        ContentUnavailableView {
                            Label("No Exchanges", systemImage: "creditcard")
                        } description: {
                            Text("Add the first exchange in Settings.")
                        } actions: {
                            Button {
                                showSettings.toggle()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "gear")
                                    Text("Open Settings")
                                }
                                .font(.headline)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.cyan.opacity(0.65),
                                                    Color.teal.opacity(0.7),
                                                    Color.blue.opacity(0.6)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .glassEffect(.regular, in: Capsule())
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
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
