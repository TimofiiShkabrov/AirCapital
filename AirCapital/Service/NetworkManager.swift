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
    case limitWAF
    case cancelReplace
    case bannedIP
    case malformedRequests
    case exchengeError
    case unknownError
}

private actor ServiceActor {
    func loadUserDataBinance() async throws -> [UserDataBinance] {
        let timestamp = Date().timeIntervalSince1970 * 1000
        let recvWindow = 5000
        let queryString = "timestamp=\(Int(timestamp))&recvWindow=\(recvWindow)"
        let signature = hmacSHA256(query: queryString, secret: secretKey)
        
        let fullURLString = "\(Link.userDataBinance.url.absoluteString)?\(queryString)&signature=\(signature)"
        
        guard let url = URL(string: fullURLString) else {
            throw NetworkError.unknownError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "X-MBX-APIKEY")
        
        print("Fetching: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknownError
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoded = try JSONDecoder().decode([UserDataBinance].self, from: data)
                print("HTTP response status code: \(httpResponse.statusCode)")
                return decoded
            } catch {
                print("Decoding error: \(error)")
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw NetworkError.decodingError
            }
        case 429:
            throw NetworkError.tooManyRequests
        case 403:
            throw NetworkError.limitWAF
        case 409:
            throw NetworkError.cancelReplace
        case 418:
            throw NetworkError.bannedIP
        case 400...402, 404...408, 410...418, 420...499:
            throw NetworkError.malformedRequests
        default:
            throw NetworkError.unknownError
        }
    }
}

@Observable
final class NetworkManager {
    var userDataBinance = [UserDataBinance]()
    var isLoading = false
    var alert = false
    var errorMessage = ""
    private let serviceActor = ServiceActor()
    
    @MainActor func fetchUserDataBinance() async {
        isLoading = true
        defer {
            isLoading = false
        }
        do {
            userDataBinance = try await serviceActor.loadUserDataBinance()
        } catch {
            print("Catch error: \(error)")
            if let networkError = error as? NetworkError {
                self.errorMessage = warningMassage(error: networkError)
            } else {
                self.errorMessage = "Unknown error"
            }
            self.alert = true
        }
    }
}
