//
//  Decoder.swift
//  AirCapital
//
//  Created by Тимофей Шкабров on 07.08.2025.
//

import Foundation

func decode<T: Decodable>(_ data: Data) -> T? {
    do {
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        print("Decoding error: \(error)")
        return nil
    }
}
