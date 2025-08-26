//
//  SettingsView.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 26.08.2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Exchange") {
                    Picker("Choose", selection: $viewModel.selectedExchange) {
                        ForEach(Exchange.allCases, id: \.self) { exchange in
                            Text(exchange.rawValue.capitalized).tag(exchange)
                        }
                    }
                    .onChange(of: viewModel.selectedExchange) { _ in
                        viewModel.loadKeys()
                    }
                }
                
                Section("API Keys") {
                    TextField("API Key", text: $viewModel.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Secret Key", text: $viewModel.secretKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    if viewModel.selectedExchange == .okx {
                        SecureField("Passphrase", text: $viewModel.passphrase)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                
                Section {
                    Button("Save") {
                        viewModel.saveKeys()
                    }
                }
            }
            .navigationTitle("Settings API")
            .onAppear {
                viewModel.loadKeys()
            }
            .alert("Saved", isPresented: $viewModel.showSavedAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}

#Preview {
    SettingsView()
}
