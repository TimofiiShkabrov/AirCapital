//
//  ExchangeDetailsView.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 31.01.2026.
//

import SwiftUI

struct ExchangeDetailsView: View {
    let exchange: Exchange
    @Bindable var exchangeViewModel: ExchengeViewModel

    var body: some View {
        List {
            Section("Overview") {
                HStack(spacing: 12) {
                    Image(exchange.rawValue)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exchange.rawValue.capitalized)
                            .font(.headline)
                        Text("Total Balance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(exchangeViewModel.balanceUSDT(for: exchange), specifier: "%.2f") USDT")
                        .font(.headline)
                        .monospacedDigit()
                }
            }

            ForEach(exchangeViewModel.detailSections(for: exchange)) { section in
                Section(section.title) {
                    ForEach(section.rows) { row in
                        LabeledContent {
                            Text(valueText(for: row))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .font(.subheadline.weight(.medium))
                                if let subtitle = row.subtitle, subtitle.isEmpty == false {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(exchange.rawValue.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func valueText(for row: ExchangeDetailRow) -> String {
        if let value = row.usdtValue {
            return String(format: "%.2f USDT", value)
        }
        if let valueText = row.valueText {
            return valueText
        }
        return "—"
    }
}

#Preview {
    ExchangeDetailsView(exchange: .binance, exchangeViewModel: ExchengeViewModel())
}
