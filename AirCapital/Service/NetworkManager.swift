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

enum NetworkError: Error {
    case noData
    case decodingError
    case tooManyRequests
}

@Observable
final class NetworkManager {
    
    init() {}
    
    static let shared = NetworkManager()
    
    var userDataBinance = [UserDataBinance]()
    
    func fetchUserDataBinance(                completion: @escaping (Result<[UserDataBinance], NetworkError>) -> Void) {
        // userDataBinance = UserDataBinance.example
        
        let timestamp = Date().timeIntervalSince1970 * 1000
        let recvWindow = 5000
        
        let queryString = "timestamp=\(Int(timestamp))&recvWindow=\(recvWindow)"
        let signature = hmacSHA256(query: queryString, secret: secretKey)
        
        let fullURLString = "\(Link.userDataBinance.url.absoluteString)?\(queryString)&signature=\(signature)"
        
        guard let url = URL(string: fullURLString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "X-MBX-APIKEY")
        
        print("Fetching: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(.failure(.noData))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Status HTTP code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 429 {
                    completion(.failure(.tooManyRequests))
                } else {
                    guard let safeData = data else { return }
                    do {
                        let decoded = try JSONDecoder().decode([UserDataBinance].self, from: safeData)
                        completion(.success(decoded))
                        
                    } catch {
                        print("Decoding error: \(error)")
                        print("Raw response: \(String(data: safeData, encoding: .utf8) ?? "nil")")
                        completion(.failure(.decodingError))
                    }
                }
            }
        }.resume()
    }
}
