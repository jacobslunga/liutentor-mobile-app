//
//  ChatService.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Foundation

protocol ChatServiceProtocol {
    func streamCompletion(
        examId: Int,
        body: ChatRequestBody,
        anonymousUserId: String
    ) -> AsyncThrowingStream<String, Error>
}

final class ChatService: ChatServiceProtocol {
    static let shared = ChatService()

    private let baseURL: String
    private let session: URLSession

    init(
        baseURL: String =
            "https://liutentor-api-production.up.railway.app/api/v1",
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func streamCompletion(
        examId: Int,
        body: ChatRequestBody,
        anonymousUserId: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard
                        let url = URL(
                            string: "\(baseURL)/chat/completion/\(examId)"
                        )
                    else {
                        throw APIError.invalidURL
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue(
                        "application/json",
                        forHTTPHeaderField: "Content-Type"
                    )
                    request.setValue(
                        anonymousUserId,
                        forHTTPHeaderField: "x-anonymous-user-id"
                    )
                    request.httpBody = try JSONEncoder().encode(body)

                    let (bytes, response) = try await session.bytes(
                        for: request
                    )

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIError.unknown(URLError(.badServerResponse))
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        throw APIError.httpError(
                            statusCode: httpResponse.statusCode,
                            data: nil
                        )
                    }

                    var buffer = Data()
                    for try await byte in bytes {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }
                        buffer.append(byte)
                        if let chunk = String(data: buffer, encoding: .utf8),
                            !chunk.isEmpty
                        {
                            continuation.yield(chunk)
                            buffer.removeAll(keepingCapacity: true)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

enum AnonymousUserID {
    private static let key = "liutentor_anonymous_id"

    static var current: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }
}
