//
//  ChatView.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isAtBottom = true
    @State private var showScrollButton = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if viewModel.messages.isEmpty {
                    EmptyChatState()
                } else {
                    MessagesScrollView(
                        messages: viewModel.messages,
                        showScrollButton: $showScrollButton
                    )
                }

                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            Color(.systemBackground).opacity(0),
                            Color(.systemBackground),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    .allowsHitTesting(false)

                    ChatInput(
                        text: $viewModel.draftInput,
                        isLoading: viewModel.isLoading,
                        canSend: viewModel.canSend,
                        onSend: { viewModel.send() },
                        onCancel: { viewModel.cancel() }
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                    .background(Color(.systemBackground))
                }
                .ignoresSafeArea(edges: .bottom)

                if showScrollButton && !viewModel.messages.isEmpty {
                    ScrollToBottomButton {
                        NotificationCenter.default.post(
                            name: .scrollChatToBottom,
                            object: nil
                        )
                    }
                    .padding(.bottom, 90)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(
                .spring(response: 0.3, dampingFraction: 0.8),
                value: showScrollButton
            )
            .navigationTitle("Chatt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text("Chatt")
                            .font(.system(.subheadline))
                            .fontWeight(.semibold)
                        Text(viewModel.courseCode)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                    }
                }
            }
        }
    }
}

private struct MessagesScrollView: View {
    let messages: [ChatMessage]
    @Binding var showScrollButton: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    Color.clear
                        .frame(height: 100)
                        .id("bottom")
                        .onAppear { showScrollButton = false }
                        .onDisappear { showScrollButton = true }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                if !messages.isEmpty {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .scrollChatToBottom)
            ) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
}

private struct ScrollToBottomButton: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "arrow.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.foreground)
                .frame(width: 36, height: 36)
                .glassEffect(in: Circle())
        }
    }
}

private struct EmptyChatState: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Vad kan jag hjälpa till med?")
                .font(.system(.title3))
                .fontWeight(.medium)
            Text(
                "Ställ frågor om tentan, be om ledtrådar eller få hjälp att förstå lösningarna."
            )
            .font(.system(.subheadline))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }
}

extension Notification.Name {
    static let scrollChatToBottom = Notification.Name("scrollChatToBottom")
}
