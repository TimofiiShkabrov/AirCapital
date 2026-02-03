//
//  BalanceChartView.swift
//  AirCapital
//
//  Created by Timofey Shkabrov on 02.02.2026.
//

import SwiftUI
import Charts

struct BalanceChartView: View {
    let snapshots: [BalanceSnapshot]
    let range: ChartRange

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if snapshots.count < 2 {
                Text("Not enough data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                let points = chartPoints(from: snapshots, range: range)
                let yDomain = yDomain(for: points)
                let yAxisValues = yAxisValues(for: yDomain, desiredCount: 4)
                Chart(points) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Balance", point.balanceUSDT)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.blue)
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Balance", point.balanceUSDT)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.linearGradient(
                        colors: [Color.blue.opacity(0.35), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                }
                .chartXScale(domain: range.startDate()...Date())
                .chartYScale(domain: yDomain)
                .chartPlotStyle { plot in
                    plot.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: yAxisValues) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4))
                }
                .frame(height: 160)
            }
        }
        .padding(.vertical, 6)
    }

    private func yDomain(for points: [ChartPoint]) -> ClosedRange<Double> {
        let values = points.map(\.balanceUSDT)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...1
        }
        if minValue == maxValue {
            let padding = max(1, minValue * 0.05)
            return (minValue - padding)...(maxValue + padding)
        }
        let padding = (maxValue - minValue) * 0.1
        return minValue...(maxValue + padding)
    }

    private func chartPoints(from snapshots: [BalanceSnapshot], range: ChartRange) -> [ChartPoint] {
        let sorted = snapshots.sorted { $0.timestamp < $1.timestamp }
        let hasNonZero = sorted.contains { $0.balanceUSDT > 0.000001 }
        let filtered = hasNonZero ? sorted.filter { $0.balanceUSDT > 0.000001 } : []
        guard let first = filtered.first, let last = filtered.last else {
            return []
        }
        let start = range.startDate()
        let end = Date()
        var points: [ChartPoint] = filtered.map { ChartPoint(timestamp: $0.timestamp, balanceUSDT: $0.balanceUSDT) }
        if first.timestamp > start {
            points.insert(ChartPoint(timestamp: start, balanceUSDT: first.balanceUSDT), at: 0)
        }
        if last.timestamp < end {
            points.append(ChartPoint(timestamp: end, balanceUSDT: last.balanceUSDT))
        }
        return points
    }

    private func yAxisValues(for domain: ClosedRange<Double>, desiredCount: Int) -> [Double] {
        let lower = domain.lowerBound
        let upper = domain.upperBound
        guard desiredCount >= 2, upper > lower else {
            return [lower, upper]
        }
        let step = (upper - lower) / Double(desiredCount - 1)
        return stride(from: lower, through: upper, by: step).map { $0 }
    }
}

private struct ChartPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let balanceUSDT: Double
}
