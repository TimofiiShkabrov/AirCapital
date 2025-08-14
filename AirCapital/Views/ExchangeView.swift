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
        List {
            VStack {
                HStack {
                    Image("Binance")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 64)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Text("\((exchangeViewModel.binanceTotalBalanceUSDT), specifier: "%.2f") USDT")
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
                
                if let bybit = exchangeViewModel.bybitWallets.first?.coin.first {
                    HStack {
                        Image("Bybit")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 64)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        Text("\(Double(bybit.walletBalance) ?? 0, specifier: "%.2f") USDT")
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
                }
                
                HStack {
                    Image("Bingx")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 64)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
//                    Text("\((exchangeViewModel.bingxTotalBalance), specifier: "%.2f") USDT")
//                        .font(.system(.subheadline, design: .monospaced, weight: .medium))
//                        .foregroundStyle(.secondary)
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
                
                HStack {
                    Image("Gateio")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 64)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Text("\((exchangeViewModel.gateioTotalBalance), specifier: "%.2f") USDT")
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
                
                HStack {
                    Image("Okx")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 64)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Text("\((exchangeViewModel.binanceTotalBalanceUSDT), specifier: "%.2f") USDT")
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
