//
//  SignatureManager.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 05.08.2025.
//

import Foundation
import CryptoKit

// MARK: - Binance/Bybit
func hmacSHA256(query: String, secret: String) -> String {
    let key = SymmetricKey(data: Data(secret.utf8))
    let signature = HMAC<SHA256>.authenticationCode(for: Data(query.utf8), using: key)
    return Data(signature).map { String(format: "%02hhx", $0) }.joined() }

// MARK: - Gateio
func sha512Hex(input: String) -> String {
    let data = Data(input.utf8)
    let hash = SHA512.hash(data: data)
    return hash.map { String(format: "%02x", $0) }.joined()
}

func hmacSHA512(query: String, secret: String) -> String {
    let key = SymmetricKey(data: Data(secret.utf8))
    let signature = HMAC<SHA512>.authenticationCode(for: Data(query.utf8), using: key)
    return signature.map { String(format: "%02x", $0) }.joined()
}
