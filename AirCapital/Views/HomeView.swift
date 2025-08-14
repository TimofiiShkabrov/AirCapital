//
//  HomeView.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 04.08.2025.
//

import SwiftUI

struct HomeView: View {
    
    var body: some View {
        //        List {
        VStack {
            HStack {
                Image("Bybit")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 64)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text("100 000 USDT")
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
            
            HStack {
                Image("Binance")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 64)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text("100 000 USDT")
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
            
            HStack {
                Image("Bingx")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 32)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text("100 000 USDT")
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
            
            HStack {
                Image("Gateio")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 70)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text("100 000 USDT")
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
            
            HStack {
                Image("Okx")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 64)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text("100 000 USDT")
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
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(.container, edges: .horizontal)
    }
}

#Preview {
    HomeView()
}
