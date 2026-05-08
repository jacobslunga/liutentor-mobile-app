//
//  APIError.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case notFound
    case decodingFailed(Error)
    case httpError(statusCode: Int, data: Data?)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL was malformed."
        case .notFound:
            return "The requested resource was not found (404)."
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .httpError(let code, _):
            return "HTTP error with status code \(code)."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
