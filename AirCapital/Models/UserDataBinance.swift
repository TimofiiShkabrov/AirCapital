//
//  UserDataBinance.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 04.08.2025.
//

import Foundation
//import Alamofire
//
//// MARK: - UserDataBinanceElement
//struct UserDataBinanceElement: Codable {
//    let activate: Bool
//    let balance, walletName: String
//}
//
//typealias UserDataBinance = [UserDataBinanceElement]
//
//// MARK: - Helper functions for creating encoders and decoders
//
//func newJSONDecoder() -> JSONDecoder {
//    let decoder = JSONDecoder()
//    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
//        decoder.dateDecodingStrategy = .iso8601
//    }
//    return decoder
//}
//
//func newJSONEncoder() -> JSONEncoder {
//    let encoder = JSONEncoder()
//    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
//        encoder.dateEncodingStrategy = .iso8601
//    }
//    return encoder
//}
//
//// MARK: - Alamofire response handlers
//
//extension DataRequest {
//    fileprivate func decodableResponseSerializer<T: Decodable>() -> DataResponseSerializer<T> {
//        return DataResponseSerializer { _, response, data, error in
//                guard error == nil else { return .failure(error!) }
//
//                guard let data = data else {
//                        return .failure(AFError.responseSerializationFailed(reason: .inputDataNil))
//                }
//
//                return Result { try newJSONDecoder().decode(T.self, from: data) }
//        }
//    }
//
//    @discardableResult
//    fileprivate func responseDecodable<T: Decodable>(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
//        return response(queue: queue, responseSerializer: decodableResponseSerializer(), completionHandler: completionHandler)
//    }
//
//    @discardableResult
//    func responseUserDataBinance(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<UserDataBinance>) -> Void) -> Self {
//        return responseDecodable(queue: queue, completionHandler: completionHandler)
//    }
//}

struct UserDataBinance: Decodable {
    let activate: Bool
    let balance, walletName: String
}

struct Query: Decodable {
    let code: Int
    let msg: String
    let data: [UserDataBinance]
}

extension UserDataBinance {
    static let example: [UserDataBinance] = [
        UserDataBinance(activate: true, balance: "34666", walletName: "Spot"),
        UserDataBinance(activate: true, balance: "45633.45", walletName: "USDⓈ-M Futures"),
        UserDataBinance(activate: true, balance: "234567", walletName: "Earn"),
        UserDataBinance(activate: true, balance: "3452", walletName: "Trading Bots"),
        UserDataBinance(activate: true, balance: "1535", walletName: "Copy Trading")
    ]
}
