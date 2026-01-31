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
        NavigationView {
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
                }
                Section("Saved Exchanges") {
                    ForEach(settingsViewModel.savedExchanges, id: \.self) { exchange in
                        HStack {
                            Text(exchange.rawValue.capitalized)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if let apiKey = APIKeysManager.load(for: exchange)?.apiKey,
                               !apiKey.isEmpty {
                                Text("\(apiKey.prefix(4))••••")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let exchange = settingsViewModel.savedExchanges[index]
                            APIKeysManager.delete(for: exchange)
                        }
                    }
                }
            }
            .navigationTitle("Settings API")
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
