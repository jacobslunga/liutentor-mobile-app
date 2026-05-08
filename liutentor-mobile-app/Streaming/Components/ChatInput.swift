//
//  ChatInput.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import SwiftUI

struct ChatInput: View {
    @Binding var text: String
    let isLoading: Bool
    let canSend: Bool
    var onSend: () -> Void
    var onCancel: () -> Void

    @FocusState private var isFocused: Bool

    private let maxLength = 4000

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 6) {
                TextField("Fråga om tentan...", text: $text, axis: .vertical)
                    .focused($isFocused)
                    .font(.system(.body))
                    .tint(.liutentorPrimary)
                    .lineLimit(1...6)
                    .padding(.leading, 16)
                    .padding(.vertical, 12)
                    .submitLabel(.send)

                Button {
                    if isLoading {
                        onCancel()
                    } else if canSend {
                        onSend()
                    }
                } label: {
                    Image(systemName: isLoading ? "stop.fill" : "arrow.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.liutentorPrimaryForeground)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle().fill(
                                isLoading
                                    ? Color.secondary
                                    : (canSend
                                        ? Color.liutentorPrimary
                                        : Color.secondary.opacity(0.4))
                            )
                        )
                }
                .padding(.trailing, 6)
                .padding(.bottom, 6)
                .animation(
                    .spring(response: 0.25, dampingFraction: 0.8),
                    value: isLoading
                )
                .animation(
                    .spring(response: 0.25, dampingFraction: 0.8),
                    value: canSend
                )
                .disabled(!isLoading && !canSend)
            }
            .glassEffect(
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )

            HStack {
                Text("AI kan göra misstag.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
                if text.count > Int(Double(maxLength) * 0.8) {
                    Text("\(text.count) / \(maxLength)")
                        .font(.system(size: 10))
                        .foregroundStyle(
                            text.count > maxLength ? .red : .secondary
                        )
                        .fontWeight(text.count > maxLength ? .bold : .regular)
                }
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            isFocused = true
        }
    }
}
