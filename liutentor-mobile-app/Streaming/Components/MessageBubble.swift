//
//  MessageBubble.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        switch message.role {
        case .user:
            UserBubble(content: message.content)
        case .assistant:
            AssistantBubble(
                content: message.content,
                isStreaming: message.isStreaming
            )
        }
    }
}

private struct UserBubble: View {
    let content: String

    var body: some View {
        HStack {
            Spacer(minLength: 40)
            Text(content)
                .font(.app(.body))
                .lineSpacing(2)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.liutentorPrimary.opacity(0.12))
                )
        }
    }
}

private struct AssistantBubble: View {
    let content: String
    let isStreaming: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                if content.isEmpty && isStreaming {
                    ThinkingIndicator()
                } else {
                    MarkdownMessage(content: content)
                    if isStreaming {
                        StreamingCaret()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
    }
}

private struct ThinkingIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            VariableSpinner(size: 16)
            ShimmerText(text: "Tänker...", font: .app(.subheadline))
        }
        .frame(height: 24)
    }
}

private struct VariableSpinner: View {
    var size: CGFloat = 16
    var lineWidth: CGFloat = 1.8

    @State private var rotation: Double = 0
    @State private var spinTask: Task<Void, Never>?

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(
                Color.secondary,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .onAppear { start() }
            .onDisappear { cancel() }
    }

    private func start() {
        cancel()
        // Mirrors the four cubic-bezier keyframes from the CSS variable-spin.
        let curves: [(Double, Double, Double, Double)] = [
            (0.4, 0, 0.2, 1),
            (0.8, 0, 0.2, 1),
            (0.4, 0, 0.6, 1),
            (0.8, 0, 0.2, 1),
        ]
        spinTask = Task { @MainActor in
            while !Task.isCancelled {
                for (a, b, c, d) in curves {
                    withAnimation(.timingCurve(a, b, c, d, duration: 1)) {
                        rotation += 180
                    }
                    do { try await Task.sleep(for: .seconds(1)) }
                    catch { return }
                }
            }
        }
    }

    private func cancel() {
        spinTask?.cancel()
        spinTask = nil
    }
}

private struct ShimmerText: View {
    let text: String
    let font: Font
    var cycle: Double = 3.2

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            let phase = (elapsed.truncatingRemainder(dividingBy: cycle)) / cycle

            Text(text)
                .font(font)
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: .secondary.opacity(0.6), location: 0),
                            .init(color: .secondary.opacity(0.6), location: 0.35),
                            .init(color: .primary, location: 0.5),
                            .init(color: .secondary.opacity(0.6), location: 0.65),
                            .init(color: .secondary.opacity(0.6), location: 1),
                        ],
                        startPoint: UnitPoint(x: 2 - phase * 3, y: 0.5),
                        endPoint: UnitPoint(x: 3 - phase * 3, y: 0.5)
                    )
                )
        }
    }
}

private struct StreamingCaret: View {
    @State private var visible = true

    var body: some View {
        Circle()
            .fill(.foreground)
            .frame(width: 8, height: 8)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                ) {
                    visible = false
                }
            }
    }
}
