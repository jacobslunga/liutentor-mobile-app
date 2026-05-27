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
        "https://liutentor-go-687405545415.europe-west1.run.app"
    }
    var method: HTTPMethod { .GET }
    var queryItems: [URLQueryItem]? { nil }
    var headers: [String: String]? { nil }

    func asURLRequest() throws -> URLRequest {
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }

        components.path = "/v1" + path
        components.queryItems = queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

enum ExamEndpoint: APIEndpoint {
    case examsByCourseCode(courseCode: String)
    case examById(examId: String)

    var path: String {
        switch self {
        case .examsByCourseCode(let courseCode):
            return
                "/exams/LIU/\(courseCode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? courseCode)"
        case .examById(let examId):
            return "/exams/\(examId)"
        }
    }
}
