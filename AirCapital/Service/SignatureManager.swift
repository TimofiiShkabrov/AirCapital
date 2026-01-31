//
//  SignatureManager.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 05.08.2025.
//

import Foundation
import CryptoKit
import CommonCrypto

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

// MARK: - Okx
func hmacSHA256Base64(input: String, secret: String) -> String {
    let keyData = Data(secret.utf8)
    let messageData = Data(input.utf8)
    var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
    
    digest.withUnsafeMutableBytes { digestBytes in
        keyData.withUnsafeBytes { keyBytes in
            messageData.withUnsafeBytes { messageBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
                       keyBytes.baseAddress, keyData.count,
                       messageBytes.baseAddress, messageData.count,
                       digestBytes.baseAddress)
            }
        }
    }
    return digest.base64EncodedString()
}
