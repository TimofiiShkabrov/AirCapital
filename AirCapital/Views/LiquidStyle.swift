//
//  LiquidStyle.swift
//  AirCapital
//
//  Created by Codex on 03.02.2026.
//

import SwiftUI

struct LiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.05, green: 0.07, blue: 0.1),
                        Color(red: 0.06, green: 0.09, blue: 0.12),
                        Color(red: 0.04, green: 0.06, blue: 0.09)
                    ]
                    : [
                        Color(red: 0.92, green: 0.96, blue: 0.99),
                        Color(red: 0.86, green: 0.95, blue: 0.96),
                        Color(red: 0.95, green: 0.97, blue: 0.99)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(colorScheme == .dark ? Color.cyan.opacity(0.18) : Color.cyan.opacity(0.25))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
                .offset(x: -140, y: -220)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(colorScheme == .dark ? Color.teal.opacity(0.16) : Color.teal.opacity(0.2))
                .frame(width: 320, height: 180)
                .blur(radius: 35)
                .rotationEffect(.degrees(-18))
                .offset(x: 150, y: 140)

            Circle()
                .fill(colorScheme == .dark ? Color.blue.opacity(0.16) : Color.blue.opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: 120, y: -40)

            if colorScheme == .dark {
                Circle()
                    .fill(Color.teal.opacity(0.12))
                    .frame(width: 180, height: 180)
                    .blur(radius: 45)
                    .offset(x: -120, y: 160)
            }
        }
        .ignoresSafeArea()
    }
}

struct LiquidSurface<S: Shape>: View {
    @Environment(\.colorScheme) private var colorScheme
    let shape: S
    var shadow: Bool = true
    var shadowRadius: CGFloat = 16
    var shadowY: CGFloat = 10

    var body: some View {
        shape
            .fill(.ultraThinMaterial)
            .glassEffect(.regular, in: shape)
            .overlay(
                shape.stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.2), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.12),
                radius: shadow ? shadowRadius : 0,
                x: 0,
                y: shadow ? shadowY : 0
            )
    }
}

struct LiquidCard<Content: View>: View {
    let title: String?
    var spacing: CGFloat = 14
    var padding: CGFloat = 18
    let content: Content

    init(title: String? = nil, spacing: CGFloat = 14, padding: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.title = title
        self.spacing = spacing
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            if let title {
                Text(title)
                    .font(.headline)
            }
            content
        }
        .padding(padding)
        .background(
            LiquidSurface(shape: RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }
}

struct LiquidSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.leading, 16)
            .padding(.top, 8)
    }
}
