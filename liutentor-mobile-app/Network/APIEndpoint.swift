//
//  APIEndpoint.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Foundation

protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: String]? { get }
}

enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case PATCH
}

extension APIEndpoint {
    var baseURL: String {
        "https://liutentor-go-api-production.up.railway.app/v1"
    }
    var method: HTTPMethod { .GET }
    var queryItems: [URLQueryItem]? { nil }
    var headers: [String: String]? { nil }

    func asURLRequest() throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
}

enum ExamEndpoint: APIEndpoint {
    case examsByCourseCode(courseCode: String)
    case examById(examId: String)

    var path: String {
        switch self {
        case .examsByCourseCode(let courseCode):
            return "/exams/LIU/\(courseCode)"
        case .examById(let examId):
            return "/exams/\(examId)"
        }
    }
}
