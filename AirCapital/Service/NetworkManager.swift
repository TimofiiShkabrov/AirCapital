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
    case userDataBingx
    case userDataGateio
    case priceTickerBinance
    
    var url: URL {
        switch self {
        case .userDataBinance:
            return URL(string: "https://api.binance.com/sapi/v1/asset/wallet/balance")!
        case .userDataBybit:
            return URL(string: "https://api.bybit.com/v5/account/wallet-balance")!
        case .userDataBingx:
            return URL(string: "https://open-api.bingx.com")!
        case .userDataGateio:
            return URL (string: "https://api.gateio.ws")!
        case .priceTickerBinance:
            return URL(string: "https://api.binance.com/api/v3/ticker/price")!
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
    
    private func request<T: Decodable>(
        _ url: URL,
        method: HTTPMethod = .get,
        headers: HTTPHeaders? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        AF.request(url, method: method, headers: headers)
            .validate()
            .responseDecodable(of: T.self, decoder: JSONDecoder()) { response in
                if let statusCode = response.response?.statusCode {
                    print("HTTP Status Code: \(statusCode)")
                }
                if let data = response.data, let rawResponse = String(data: data, encoding: .utf8) {
                    print("Response Data: \(rawResponse)")
                }
                switch response.result {
                case .success(let decoded):
                    completion(.success(decoded))
                case .failure(let error):
                    print("Error: \(error)")
                    let code = response.response?.statusCode ?? -1
                    completion(.failure(self.mapError(code)))
                }
            }
    }
    
    // MARK: - Binance API
    func fetchPriceTickerBinance(completion: @escaping (Result<PriceTickerBinance, NetworkError>) -> Void) {
        let queryString = "?symbol=BTCUSDT"
        
        let urlString = "\(Link.priceTickerBinance.url.absoluteString)\(queryString)"
        guard let url = URL(string: urlString) else {
            completion(.failure(.incorrectURL))
            return
        }
        
        request(url, completion: completion)
    }
    
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
        
        let urlString = "\(timestamp)\(apiKeyBybit)\(recvWindow)\(queryString)"
        let signature = hmacSHA256(query: urlString, secret: secretKeyBybit)
        
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
    
    // MARK: - Bingx API
    //    func fetchBingxSpotBalances(completion: @escaping (Result<UserDataBingx, NetworkError>) -> Void) {
    //        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    //        let recvWindow = 5000
    //
    //        let path = "/openApi/spot/v1/account"
    //        let queryString = "timestamp=\(timestamp)&recvWindow=\(recvWindow)"
    //        let signature = hmacSHA256(query: queryString, secret: secretKeyBingx)
    //
    //        let urlString = "\(Link.userDataBingx.url.absoluteString)\(path)?\(queryString)&signature=\(signature)"
    //        guard let url = URL(string: urlString) else {
    //            completion(.failure(.incorrectURL))
    //            return
    //        }
    //
    //        let headers: HTTPHeaders = ["X-BX-APIKEY": apiKeyBingx]
    //        request(url, method: .get, headers: headers, completion: completion)
    //    }
    
    // MARK: - Gateio API
    func fetchGateioBalances(completion: @escaping (Result<UserDataGateio, NetworkError>) -> Void) {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let method = "GET"
        let path = "/api/v4/wallet/total_balance"
        let queryString = ""
        let body = ""
        let bodyHash = sha512Hex(input: body)
        
        let signString = "\(method)\n\(path)\n\(queryString)\n\(bodyHash)\n\(timestamp)"
        let signature = hmacSHA512(query: signString, secret: secretKeyGateio)
        
        guard let url = URL(string: "https://api.gateio.ws\(path)?\(queryString)") else {
            completion(.failure(.incorrectURL))
            return
        }
        
        let headers: HTTPHeaders = [
            "KEY": apiKeyGateio,
            "SIGN": signature,
            "Timestamp": timestamp,
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        request(url, method: .get, headers: headers, completion: completion)
    }
    
    // MARK: - Error mapping
    private func mapError(_ code: Int) -> NetworkError {
        switch code {
        case 401: return .malformedRequests
        case 429: return .tooManyRequests
        case 403: return .limitWAF
        case 409: return .cancelReplace
        case 418: return .bannedIP
        case 400...428: return .malformedRequests
        case 430...499: return .malformedRequests
        case 500...599: return .exchengeError
        default: return .unknownError
        }
    }
}
