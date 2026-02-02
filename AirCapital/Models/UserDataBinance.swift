//
//  UserDataBinance.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 04.08.2025.
//

import Foundation

// MARK: - UserDataBinance
struct UserDataBinance: Codable, Sendable {
    let activate: Bool
    let balance, walletName: String
}
