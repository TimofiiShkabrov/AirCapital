//
//  DepositLoadingView.swift
//  AirCapital
//
//  Created by Codex on 03.02.2026.
//

import SwiftUI

struct DepositLoadingView: View {
    @State private var spin = false
    @State private var pulse = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LiquidBackground()
                .overlay(Color.black.opacity(colorScheme == .dark ? 0.45 : 0.2))
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(colorScheme == .dark ? 0.14 : 0.18), lineWidth: 10)
                        .frame(width: 86, height: 86)

                    Circle()
                        .trim(from: 0.08, to: 0.92)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.mint, .teal, .cyan, .mint]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 86, height: 86)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .animation(.linear(duration: 1.3).repeatForever(autoreverses: false), value: spin)

                    Image(systemName: "banknote.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.primary)
                        .scaleEffect(pulse ? 1.05 : 0.96)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
                }

                VStack(spacing: 6) {
                    Text("Суммируем депозит")
                        .font(.title3.weight(.semibold))
                    Text("Подгружаем балансы бирж и считаем итог")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.white.opacity(colorScheme == .dark ? 0.12 : 0.18))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            ShimmerBar(width: 180, height: 12)
                            ShimmerBar(width: 120, height: 10)
                        }

                        Spacer(minLength: 0)
                    }

                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.white.opacity(colorScheme == .dark ? 0.12 : 0.18))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image(systemName: "bitcoinsign.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            ShimmerBar(width: 160, height: 12)
                            ShimmerBar(width: 140, height: 10)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(24)
            .background(
                LiquidSurface(
                    shape: RoundedRectangle(cornerRadius: 28, style: .continuous),
                    shadow: false,
                    shadowRadius: 0,
                    shadowY: 0
                )
            )
            .shadow(color: .black.opacity(0.2), radius: 28, x: 0, y: 18)
            .padding(.horizontal, 24)
            .frame(maxWidth: 420)
        }
        .onAppear {
            spin = true
            pulse = true
        }
    }
}

private struct ShimmerBar: View {
    let width: CGFloat
    let height: CGFloat
    @State private var phase: CGFloat = -1
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(.white.opacity(colorScheme == .dark ? 0.1 : 0.14))
            .frame(width: width, height: height)
            .overlay {
                GeometryReader { proxy in
                    let fullWidth = proxy.size.width
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(colorScheme == .dark ? 0.4 : 0.5),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: fullWidth * 0.6)
                    .offset(x: phase * fullWidth)
                    .blendMode(.plusLighter)
                }
                .mask(
                    RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                )
            }
            .onAppear {
                withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

#Preview {
    DepositLoadingView()
}
