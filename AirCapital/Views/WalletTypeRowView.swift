//
//  WalletTypeRowView.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 02.02.2026.
//

import SwiftUI

struct WalletTypeRowView: View {
    let section: WalletTypeSection
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("USDT")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(totalText)
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(rowShape.fill(Color(.secondarySystemBackground)))
        .overlay(rowShape.stroke(Color(.separator).opacity(0.35), lineWidth: 1))
        .overlay(separatorOverlay, alignment: .bottom)
        .contentShape(Rectangle())
    }

    private var totalText: String {
        guard let total = section.totalUSDT else {
            return "—"
        }
        return String(format: "%.2f USDT", total)
    }

    private var rowShape: RowBackgroundShape {
        RowBackgroundShape(
            isFirst: isFirst,
            isLast: isLast,
            radius: 24
        )
    }

    @ViewBuilder
    private var separatorOverlay: some View {
        if isLast == false {
            Divider()
                .overlay(Color(.separator).opacity(0.35))
                .padding(.leading, 56)
        }
    }
}

private struct RowBackgroundShape: Shape {
    let isFirst: Bool
    let isLast: Bool
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        if isFirst && isLast {
            return RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: rect)
        }
        if isFirst {
            return RoundedCornersShape(corners: [.topLeft, .topRight], radius: radius).path(in: rect)
        }
        if isLast {
            return RoundedCornersShape(corners: [.bottomLeft, .bottomRight], radius: radius).path(in: rect)
        }
        return Rectangle().path(in: rect)
    }
}
