//
//  WalletTypeDetailView.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 02.02.2026.
//

import SwiftUI

struct WalletTypeDetailView: View {
    let section: WalletTypeSection
    let valueText: (ExchangeDetailRow) -> String

    var body: some View {
        List {
            Section {
                rowsCard
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, 16)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var rowsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                detailRow(row)
                if index < section.rows.count - 1 {
                    Divider()
                        .overlay(Color(.separator).opacity(0.35))
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
    }

    private func detailRow(_ row: ExchangeDetailRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(row.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                if let subtitle = row.subtitle, subtitle.isEmpty == false {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(valueText(row))
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }
}
