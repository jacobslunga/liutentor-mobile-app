//
//  ChatMessage.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: Role
    var content: String
    var isStreaming: Bool

    enum Role: String, Codable, Equatable {
        case user
        case assistant
    }

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.isStreaming = isStreaming
    }
}

struct ChatRequestBody: Encodable {
    let messages: [WireMessage]
    let examUrl: String
    let courseCode: String
    let solutionUrl: String?
    let modelId: String
    let conversationId: String?

    struct WireMessage: Encodable {
        let role: String
        let content: String
    }
}
