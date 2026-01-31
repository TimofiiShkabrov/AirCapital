//
//  Decoder.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 07.08.2025.
//

import Foundation

func decode<T: Decodable>(_ data: Data) -> T? {
    do {
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        return nil
    }
}
