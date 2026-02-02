//
//  SettingsView.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 26.08.2025.
//

import SwiftUI

struct SettingsView: View {
    
    @State private var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exchange") {
                    Picker("Choose", selection: $settingsViewModel.selectedExchange) {
                        ForEach(Exchange.allCases, id: \.self) { exchange in
                            Text(exchange.rawValue.capitalized).tag(exchange)
                        }
                    }
                    .onChange(of: settingsViewModel.selectedExchange) {
                        settingsViewModel.loadKeys()
                    }
                }

                Section("Account") {
                    TextField("Account Name (optional)", text: $settingsViewModel.accountLabel)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                
                Section("API Keys") {
                    TextField("API Key", text: $settingsViewModel.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Secret Key", text: $settingsViewModel.secretKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    if settingsViewModel.selectedExchange == .okx {
                        SecureField("Passphrase", text: $settingsViewModel.passphrase)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                
                Section {
                    Button("Save") {
                        settingsViewModel.saveKeys()
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .glassEffect(.regular, in: Capsule())
                }
                Section("Saved Accounts") {
                    ForEach(settingsViewModel.savedAccounts) { account in
                        let label = accountLabel(for: account)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.exchange.rawValue.capitalized)
                                    .fontWeight(.medium)
                                if label.isEmpty == false {
                                    Text(label)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if let apiKey = APIKeysManager.loadKeys(for: account)?.apiKey,
                               !apiKey.isEmpty {
                                Text("\(apiKey.prefix(4))••••")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let account = settingsViewModel.savedAccounts[index]
                            APIKeysManager.delete(account: account)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings API")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                settingsViewModel.loadKeys()
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
