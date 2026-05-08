//
//  APIClient.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Foundation

protocol APIClientProtocol {
    func fetch<T: Decodable>(_ endpoint: any APIEndpoint, as type: T.Type)
        async throws -> T
}

final class APIClient: APIClientProtocol {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func fetch<T: Decodable>(
        _ endpoint: any APIEndpoint,
        as type: T.Type = T.self
    ) async throws -> T {
        let request = try endpoint.asURLRequest()

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 404:
            throw APIError.notFound
        default:
            throw APIError.httpError(
                statusCode: httpResponse.statusCode,
                data: data
            )
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            #if DEBUG
                print("Decoding failed for \(T.self):")
                switch decodingError {
                case .keyNotFound(let key, let ctx):
                    print(
                        "   Missing key '\(key.stringValue)' at \(ctx.codingPath.map { $0.stringValue }.joined(separator: "."))"
                    )
                case .typeMismatch(let type, let ctx):
                    print(
                        "   Type mismatch: expected \(type) at \(ctx.codingPath.map { $0.stringValue }.joined(separator: "."))"
                    )
                case .valueNotFound(let type, let ctx):
                    print(
                        "   Value not found: \(type) at \(ctx.codingPath.map { $0.stringValue }.joined(separator: "."))"
                    )
                case .dataCorrupted(let ctx):
                    print(
                        "   Data corrupted at \(ctx.codingPath.map { $0.stringValue }.joined(separator: ".")): \(ctx.debugDescription)"
                    )
                @unknown default:
                    print("   \(decodingError)")
                }
                if let raw = String(data: data, encoding: .utf8) {
                    print("Raw response: \(raw.prefix(500))")
                }
            #endif
            throw APIError.decodingFailed(decodingError)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}
