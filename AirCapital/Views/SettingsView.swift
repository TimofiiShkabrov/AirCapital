//
//  SettingsView.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 26.08.2025.
//

import SwiftUI

struct SettingsView: View {
    
    @State private var settingsViewModel = SettingsViewModel()
    @State private var savedAccounts: [ExchangeAccount] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        
                        LiquidCard(title: "Exchange") {
                            GlassPickerRow(
                                title: "Choose exchange",
                                systemImage: "creditcard",
                                selection: $settingsViewModel.selectedExchange
                            )
                            .onChange(of: settingsViewModel.selectedExchange) {
                                settingsViewModel.loadKeys()
                            }
                        }
                        
                        LiquidCard(title: "Account") {
                            GlassField(
                                title: "Account Name",
                                placeholder: "Optional label",
                                text: $settingsViewModel.accountLabel,
                                textInputAutocapitalization: .words
                            )
                        }
                        
                        LiquidCard(title: "API Keys") {
                            GlassField(
                                title: "API Key",
                                placeholder: "Paste API key",
                                text: $settingsViewModel.apiKey,
                                textInputAutocapitalization: .never
                            )
                            GlassField(
                                title: "Secret Key",
                                placeholder: "Paste secret key",
                                text: $settingsViewModel.secretKey,
                                isSecure: true,
                                textInputAutocapitalization: .never
                            )
                            if settingsViewModel.selectedExchange == .okx {
                                GlassField(
                                    title: "Passphrase",
                                    placeholder: "OKX passphrase",
                                    text: $settingsViewModel.passphrase,
                                    isSecure: true,
                                    textInputAutocapitalization: .never
                                )
                            }
                        }
                        
                        Button {
                            settingsViewModel.saveKeys()
                            refreshAccounts()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Save Keys")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
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
                        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
                        
                        LiquidCard(title: "Saved Accounts") {
                            if savedAccounts.isEmpty {
                                HStack(spacing: 12) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("No saved accounts yet.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.white.opacity(0.08))
                                )
                            } else {
                                ForEach(savedAccounts) { account in
                                    SavedAccountRow(
                                        account: account,
                                        label: accountLabel(for: account),
                                        apiKeyPreview: APIKeysManager.loadKeys(for: account)?.apiKey
                                    ) {
                                        deleteAccount(account)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                settingsViewModel.loadKeys()
                refreshAccounts()
            }
            .alert("Saved", isPresented: $settingsViewModel.showSavedAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}

#Preview {
    SettingsView()
}

private func accountLabel(for account: ExchangeAccount) -> String {
    if let label = account.label, label.isEmpty == false {
        return label
    }
    let accounts = APIKeysManager.accounts(for: account.exchange)
    let index = accounts.firstIndex(of: account).map { $0 + 1 } ?? 1
    return "Account \(index)"
}

private extension SettingsView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("API Access")
                .font(.largeTitle.weight(.semibold))
            Text("Store exchange keys securely and keep balances in sync.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
    
    func refreshAccounts() {
        savedAccounts = settingsViewModel.savedAccounts
    }
    
    func deleteAccount(_ account: ExchangeAccount) {
        APIKeysManager.delete(account: account)
        refreshAccounts()
    }
}

private struct GlassField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var textInputAutocapitalization: TextInputAutocapitalization = .never
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textInputAutocapitalization(textInputAutocapitalization)
            .autocorrectionDisabled()
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorScheme == .dark ? .white.opacity(0.08) : .white.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.2), lineWidth: 1)
            )
        }
    }
}

private struct GlassPickerRow: View {
    let title: String
    let systemImage: String
    @Binding var selection: Exchange
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.2))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(selection.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("", selection: $selection) {
                ForEach(Exchange.allCases, id: \.self) { exchange in
                    Text(exchange.rawValue.capitalized).tag(exchange)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? .white.opacity(0.08) : .white.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.2), lineWidth: 1)
        )
    }
}

private struct SavedAccountRow: View {
    let account: ExchangeAccount
    let label: String
    let apiKeyPreview: String?
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(account.exchange.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.18))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.exchange.rawValue.capitalized)
                    .font(.subheadline.weight(.semibold))
                if label.isEmpty == false {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let apiKeyPreview, apiKeyPreview.isEmpty == false {
                    Text("\(apiKeyPreview.prefix(4))••••")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? .white.opacity(0.06) : .white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.15), lineWidth: 1)
        )
    }
}
