//
//  ChartRange.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 02.02.2026.
//

import Foundation

enum ChartRange: String, CaseIterable, Identifiable {
    case day = "1D"
    case week = "1W"
    case month = "1M"

    var id: String { rawValue }

    func startDate(from date: Date = Date()) -> Date {
        switch self {
        case .day:
            return Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        case .week:
            return Calendar.current.date(byAdding: .day, value: -7, to: date) ?? date
        case .month:
            return Calendar.current.date(byAdding: .month, value: -1, to: date) ?? date
        }
    }
}
