//
//  ExamService.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Foundation

protocol ExamServiceProtocol {
    func fetchExams(for courseCode: String) async throws -> ExamsResult?
    func fetchExam(by id: Int) async throws -> ExamDetail
}

final class ExamService: ExamServiceProtocol {
    private let client: APIClientProtocol

    init(client: APIClientProtocol = APIClient.shared) {
        self.client = client
    }

    func fetchExams(for courseCode: String) async throws -> ExamsResult? {
        do {
            let envelope = try await client.fetch(
                ExamEndpoint.examsByCourseCode(courseCode: courseCode),
                as: ExamsEnvelope.self
            )
            return envelope.data
        } catch APIError.notFound {
            return nil
        }
    }

    func fetchExam(by id: Int) async throws -> ExamDetail {
        let envelope = try await client.fetch(
            ExamEndpoint.examById(examId: String(id)),
            as: ExamDetailEnvelope.self
        )
        return envelope.data
    }
}
