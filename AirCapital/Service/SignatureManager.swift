//
//  SignatureManager.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 05.08.2025.
//

import Foundation
import CryptoKit

func hmacSHA256(query: String, secret: String) -> String {
    let key = SymmetricKey(data: Data(secret.utf8))
    let signature = HMAC<SHA256>.authenticationCode(for: Data(query.utf8), using: key)
    return Data(signature).map { String(format: "%02hhx", $0) }.joined() }
