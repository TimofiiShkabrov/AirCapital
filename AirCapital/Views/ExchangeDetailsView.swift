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
        VStack(spacing: 12) {
            ForEach(exchangeViewModel.detailSections(for: exchange)) { section in
                GlassSection(title: section.title) {
                    ForEach(section.rows) { row in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .font(.subheadline.weight(.medium))
                                if let subtitle = row.subtitle, subtitle.isEmpty == false {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(valueText(for: row))
                                .font(.system(.subheadline, design: .monospaced, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        if row.id != section.rows.last?.id {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 6)
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
    
    private struct GlassSection<Content: View>: View {
        let title: String
        @ViewBuilder let content: Content
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                
                GlassCard(cornerRadius: 18, padding: EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)) {
                    VStack(spacing: 8) {
                        content
                    }
                }
            }
        }
    }
}

#Preview {
    ExchangeDetailsView(exchange: .binance, exchangeViewModel: ExchengeViewModel())
        .padding()
}
