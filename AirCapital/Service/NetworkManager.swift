//
//  NetworkManager.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 04.08.2025.
//

import Foundation
import Observation
import Alamofire

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
    case incorrectURL
}

@Observable
final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func fetchUserDataBinance(from url:URL, completion: @escaping (Result<[UserDataBinance], NetworkError>) -> Void) {
        let timestamp = Date().timeIntervalSince1970 * 1000
        let recvWindow = 5000
        let queryString = "timestamp=\(Int(timestamp))&recvWindow=\(recvWindow)"
        let signature = hmacSHA256(query: queryString, secret: secretKey)

        let fullURLString = "\(Link.userDataBinance.url.absoluteString)?\(queryString)&signature=\(signature)"

        guard let url = URL(string: fullURLString) else {
            completion(.failure(.incorrectURL))
            return
        }

        let headers: HTTPHeaders = [
            "X-MBX-APIKEY": apiKey
        ]

        print("Fetching: \(url.absoluteString)")

        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseData(queue: .main) { response in
                switch response.result {
                case .success(let data):
                    let decoded = self.parseUserDataBinance(data)
                    completion(.success(decoded))

                case .failure:
                    let statusCode = response.response?.statusCode ?? -1

                    let networkError: NetworkError
                    switch statusCode {
                    case 429:
                        networkError = .tooManyRequests
                    case 403:
                        networkError = .limitWAF
                    case 409:
                        networkError = .cancelReplace
                    case 418:
                        networkError = .bannedIP
                    case 400...402, 404...408, 410...418, 420...499:
                        networkError = .malformedRequests
                    default:
                        networkError = .unknownError
                    }

                    print("Alamofire error: \(response.error?.localizedDescription ?? "Unknown error")")
                    completion(.failure(networkError))
                }
            }
    }

    private func parseUserDataBinance(_ data: Data) -> [UserDataBinance] {
        var userDataBinance = [UserDataBinance]()
        if let decoded: [UserDataBinance] = decode(data) {
            userDataBinance = decoded
        } else {
            print("Failed to decode UserDataBinance from response.")
        }
        return userDataBinance
    }
}
