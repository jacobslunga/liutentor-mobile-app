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
                .font(.system(.body))
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
    @State private var phase: Double = 0

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 6, height: 6)
                        .opacity(0.3 + 0.7 * dotOpacity(for: i))
                }
            }
            Text("Tänker...")
                .font(.system(.subheadline))
                .foregroundStyle(.secondary)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: false)
            ) {
                phase = 1
            }
        }
    }

    private func dotOpacity(for index: Int) -> Double {
        let offset = Double(index) * 0.2
        let value = sin((phase + offset) * .pi * 2)
        return (value + 1) / 2
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
