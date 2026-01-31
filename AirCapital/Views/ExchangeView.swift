//
//  ExchangeView.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 04.08.2025.
//

import SwiftUI

struct ExchangeView: View {
    
    @Bindable var exchangeViewModel: ExchengeViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedExchange: Exchange?
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var isTwoColumn: Bool {
        horizontalSizeClass == .regular || isLandscape
    }

    private var outerHorizontalPadding: CGFloat {
        isTwoColumn ? 20 : 0
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(
            top: isTwoColumn ? 6 : 10,
            leading: isTwoColumn ? 0 : 12,
            bottom: isTwoColumn ? 6 : 10,
            trailing: isTwoColumn ? 0 : 12
        )
    }
    
    var body: some View {
        let exchanges = exchangeViewModel.enabledExchanges
        Group {
            if isTwoColumn {
                HStack(alignment: .top, spacing: 20) {
                    exchangeList(exchanges: exchanges, inlineDetails: false)
                        .frame(minWidth: 260, idealWidth: 320, maxWidth: 360)
                    
                    detailsPane(for: exchanges)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, outerHorizontalPadding)
                .padding(.bottom, 8)
            } else {
                exchangeList(exchanges: exchanges, inlineDetails: true)
            }
        }
        .overlay {
            if exchangeViewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: $exchangeViewModel.alert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exchangeViewModel.errorMessage)
        }
        .task {
            exchangeViewModel.loadData()
        }
        .onAppear {
            ensureSelection(for: exchanges)
        }
        .onChange(of: verticalSizeClass) { _, newValue in
            if newValue == .compact {
                ensureSelection(for: exchanges)
            }
        }
        .onChange(of: exchanges) { _, newValue in
            ensureSelection(for: newValue)
        }
        .onChange(of: horizontalSizeClass) { _, _ in
            ensureSelection(for: exchanges)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedExchange)
    }

    @ViewBuilder
    private func exchangeList(exchanges: [Exchange], inlineDetails: Bool) -> some View {
        List {
            ForEach(exchanges, id: \.self) { exchange in
                let stackSpacing: CGFloat = inlineDetails ? 0 : (isTwoColumn ? 10 : 12)
                VStack(spacing: stackSpacing) {
                    Button {
                        select(exchange: exchange, inlineDetails: inlineDetails)
                    } label: {
                        exchangeRow(
                            for: exchange,
                            isSelected: isTwoColumn && selectedExchange == exchange,
                            isCompact: isTwoColumn
                        )
                    }
                    .buttonStyle(.plain)
                    
                    if inlineDetails {
                        ExpandableSection(isExpanded: selectedExchange == exchange) {
                            ExchangeDetailsView(
                                exchange: exchange,
                                exchangeViewModel: exchangeViewModel
                            )
                            .padding(.top, 10)
                        }
                    }
                }
                .listRowInsets(rowInsets)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await withCheckedContinuation { continuation in
                exchangeViewModel.loadData {
                    continuation.resume()
                }
            }
        }
    }
    
    @ViewBuilder
    private func exchangeRow(for exchange: Exchange, isSelected: Bool, isCompact: Bool) -> some View {
        let balance = exchangeViewModel.balanceUSDT(for: exchange)
        HStack {
            Image(exchange.rawValue)
                .resizable()
                .scaledToFit()
                .frame(height: 64)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text("\(balance, specifier: "%.2f") USDT")
                .font(.system(.subheadline, design: .monospaced, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, isCompact ? 14 : 18)
        .padding(.vertical, isCompact ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isSelected ? Color.primary.opacity(0.18) : Color.primary.opacity(0.08),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .shadow(
            color: isSelected ? Color.accentColor.opacity(0.22) : .clear,
            radius: 18,
            x: 0,
            y: 0
        )
        .shadow(
            color: isSelected ? Color.white.opacity(0.12) : .clear,
            radius: 8,
            x: 0,
            y: 0
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func detailsPane(for exchanges: [Exchange]) -> some View {
        if let exchange = selectedExchange ?? exchanges.first {
            ScrollView {
                VStack(spacing: 14) {
                    exchangeHeader(for: exchange)
                    ExchangeDetailsView(
                        exchange: exchange,
                        exchangeViewModel: exchangeViewModel
                    )
                }
                .padding(.bottom, 12)
            }
        } else {
            VStack {
                Text("Select an exchange")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
    }
    
    private func exchangeHeader(for exchange: Exchange) -> some View {
        let balance = exchangeViewModel.balanceUSDT(for: exchange)
        return HStack(spacing: 16) {
            Image(exchange.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(exchange.rawValue.capitalized)
                    .font(.headline)
                Text(String(format: "%.2f USDT", balance))
                    .font(.system(.title3, design: .monospaced, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 6)
    }
    
    private func select(exchange: Exchange, inlineDetails: Bool) {
        if inlineDetails {
            if selectedExchange == exchange {
                selectedExchange = nil
            } else {
                selectedExchange = exchange
            }
        } else {
            selectedExchange = exchange
        }
    }
    
    private func ensureSelection(for exchanges: [Exchange]) {
        guard isTwoColumn else {
            return
        }
        if let selected = selectedExchange, exchanges.contains(selected) {
            return
        }
        selectedExchange = exchanges.first
    }
}

private struct ExpandableSection<Content: View>: View {
    let isExpanded: Bool
    @ViewBuilder let content: Content
    @State private var contentHeight: CGFloat = 0
    
    var body: some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: HeightPreferenceKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(HeightPreferenceKey.self) { newValue in
                if newValue > 0 {
                    contentHeight = newValue
                }
            }
            .frame(height: isExpanded ? contentHeight : 0, alignment: .top)
            .clipped()
            .opacity(isExpanded ? 1 : 0)
            .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }
}

private enum HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    ExchangeView(exchangeViewModel: ExchengeViewModel())
}
