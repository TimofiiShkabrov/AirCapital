//
//  ErrorHelper.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 05.08.2025.
//

import Foundation

import Foundation


func warningMassage(error: NetworkError) -> String {
    switch error {
    case .tooManyRequests:
        return "Too many requests"
    case .noData:
        return "No data"
    case .decodingError:
        return "Decoding error"
    case .limitWAF:
        return "WAF Limit (Web Application Firewall)"
    case .cancelReplace:
        return "cancelReplace order partially succeeds. (e.g. if the cancellation of the order fails but the new order placement succeeds.)"
    case .bannedIP:
        return "IP has been auto-banned for continuing to send requests after receiving 429 codes (e.g. too many requests)."
    case .malformedRequests:
        return "Malformed request; problem occurred on the sender's side."
    case .exchengeError:
        return "The issue occurred on Binance's side. It is important NOT to treat this as a transaction failure; the execution status is UNKNOWN and the transaction could have been successful."
    case .unknownError:
        return "Unknown error"
    case .incorrectURL:
        return "Incorrect API URL"
    }
}
