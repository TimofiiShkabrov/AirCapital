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
    }
}
