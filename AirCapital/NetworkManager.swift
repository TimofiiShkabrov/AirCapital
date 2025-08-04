//
//  NetworkManager.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 04.08.2025.
//

import Foundation
import Observation

enum Link {
    case userDataBinance
    
    var url: URL {
        switch self {
        case .userDataBinance:
            return URL(string: "https://api.binance.com/sapi/v1/asset/wallet/balance")!
        }
    }
}

@Observable
final class NetworkManager {
    
    init() {}
    
    static let shared = NetworkManager()
    
    var userDataBinance = [UserDataBinance]()
    
    func fetchUserDataBinance() {
        // userDataBinance = UserDataBinance.example
        
        print("Try to fetch user data...")
        
        let fetchRequest: URLRequest = URLRequest(url: Link.userDataBinance.url)
        
        
    }
}
