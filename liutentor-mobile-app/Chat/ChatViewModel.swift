//
//  ChatViewModel.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Combine
import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var draftInput: String = ""
    @Published private(set) var isLoading: Bool = false

    private let service: ChatServiceProtocol
    private let modelId = "gemini-3.1-flash-lite-preview"
    private let maxRecentMessages = 10
    private var streamTask: Task<Void, Never>?

    let examId: Int
    let courseCode: String
    let examURL: String
    let solutionURL: String?

    init(
        examId: Int,
        courseCode: String,
        examURL: String,
        solutionURL: String?,
        service: ChatServiceProtocol = ChatService.shared
    ) {
        self.examId = examId
        self.courseCode = courseCode
        self.examURL = examURL
        self.solutionURL = solutionURL
        self.service = service
    }

    var canSend: Bool {
        !draftInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isLoading
            && draftInput.count <= 4000
    }

    func send() {
        let text = draftInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let userMessage = ChatMessage(role: .user, content: text)
        let assistantPlaceholder = ChatMessage(
            role: .assistant,
            content: "",
            isStreaming: true
        )

        messages.append(userMessage)
        messages.append(assistantPlaceholder)
        draftInput = ""
        isLoading = true

        streamTask = Task { [weak self] in
            await self?.runStream(assistantId: assistantPlaceholder.id)
        }
    }

    func cancel() {
        streamTask?.cancel()
        streamTask = nil

        guard let lastIndex = messages.indices.last else { return }
        var last = messages[lastIndex]
        if last.role == .assistant {
            if last.content.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
            {
                last.content = "> *Avbruten av användaren*"
            } else {
                last.content += "\n\n> *Avbruten av användaren*"
            }
            last.isStreaming = false
            messages[lastIndex] = last
        }
        isLoading = false
    }

    private func runStream(assistantId: UUID) async {
        let recent = Array(messages.dropLast().suffix(maxRecentMessages))
        let wire = recent.map {
            ChatRequestBody.WireMessage(
                role: $0.role.rawValue,
                content: $0.content
            )
        }

        let body = ChatRequestBody(
            messages: wire,
            examUrl: examURL,
            courseCode: courseCode,
            solutionUrl: solutionURL,
            modelId: modelId,
            conversationId: nil
        )

        do {
            var accumulated = ""
            var lastFlush = Date()
            let flushInterval: TimeInterval = 0.08

            let stream = service.streamCompletion(
                examId: examId,
                body: body,
                anonymousUserId: AnonymousUserID.current
            )
            for try await chunk in stream {
                accumulated += chunk
                let now = Date()
                if now.timeIntervalSince(lastFlush) >= flushInterval {
                    updateAssistantMessage(
                        id: assistantId,
                        content: accumulated,
                        streaming: true
                    )
                    lastFlush = now
                }
            }
            let finalText = accumulated.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            updateAssistantMessage(
                id: assistantId,
                content: finalText.isEmpty
                    ? "Jag kunde inte generera ett svar." : finalText,
                streaming: false
            )
        } catch is CancellationError {
            return
        } catch {
            updateAssistantMessage(
                id: assistantId,
                content: "Något gick fel. Försök igen senare.",
                streaming: false
            )
        }

        isLoading = false
        streamTask = nil
    }

    private func updateAssistantMessage(
        id: UUID,
        content: String,
        streaming: Bool
    ) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else {
            return
        }
        messages[index].content = content
        messages[index].isStreaming = streaming
    }
}
