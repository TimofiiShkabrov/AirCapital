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
    case userDataBybit
    
    var url: URL {
        switch self {
        case .userDataBinance:
            return URL(string: "https://api.binance.com/sapi/v1/asset/wallet/balance")!
        case .userDataBybit:
            return URL(string: "https://api.bybit.com/v5/account/wallet-balance")!
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
    
    // MARK: - Universal request
    private func request<T: Decodable>(
        _ url: URL,
        method: HTTPMethod = .get,
        headers: HTTPHeaders? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        AF.request(url, method: method, headers: headers)
            .validate()
            .responseDecodable(of: T.self, decoder: JSONDecoder()) { response in
                switch response.result {
                case .success(let decoded):
                    completion(.success(decoded))
                case .failure:
                    let code = response.response?.statusCode ?? -1
                    completion(.failure(self.mapError(code)))
                }
            }
    }
    
    // MARK: - Binance API
    func fetchUserDataBinance(completion: @escaping (Result<[UserDataBinance], NetworkError>) -> Void) {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let recvWindow = 5000
        let queryString = "timestamp=\(timestamp)&recvWindow=\(recvWindow)"
        let signature = hmacSHA256(query: queryString, secret: secretKeyBinance)
        
        let urlString = "\(Link.userDataBinance.url.absoluteString)?\(queryString)&signature=\(signature)"
        guard let url = URL(string: urlString) else {
            completion(.failure(.incorrectURL))
            return
        }
        
        let headers: HTTPHeaders = ["X-MBX-APIKEY": apiKeyBinance]
        request(url, headers: headers, completion: completion)
    }
    
    // MARK: - Bybit API
    func fetchUserDataBybit(completion: @escaping (Result<UserDataBybit, NetworkError>) -> Void) {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let recvWindow = 5000
        let queryString = "accountType=UNIFIED"
        
        let preSign = "\(timestamp)\(apiKeyBybit)\(recvWindow)\(queryString)"
        let signature = hmacSHA256(query: preSign, secret: secretKeyBybit)
        
        var urlComponents = URLComponents(url: Link.userDataBybit.url, resolvingAgainstBaseURL: false)!
        urlComponents.query = queryString
        
        guard let url = urlComponents.url else {
            completion(.failure(.incorrectURL))
            return
        }
        
        let headers: HTTPHeaders = [
            "X-BAPI-SIGN": signature,
            "X-BAPI-API-KEY": apiKeyBybit,
            "X-BAPI-TIMESTAMP": "\(timestamp)",
            "X-BAPI-RECV-WINDOW": "\(recvWindow)"
        ]
        
        request(url, headers: headers, completion: completion)
    }
    
    // MARK: - Error mapping
    private func mapError(_ code: Int) -> NetworkError {
        switch code {
        case 429: return .tooManyRequests
        case 403: return .limitWAF
        case 409: return .cancelReplace
        case 418: return .bannedIP
        case 400...499: return .malformedRequests
        default: return .unknownError
        }
    }
}
