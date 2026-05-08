//
//  Exam.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Foundation

struct Exam: Decodable, Identifiable {
    let id: Int
    let courseCode: String
    let examDate: String
    let pdfURL: String
    let examName: String
    let hasSolution: Bool
    let statistics: ExamStatistics?
    let passRate: Double

    enum CodingKeys: String, CodingKey {
        case id
        case courseCode = "course_code"
        case examDate = "exam_date"
        case pdfURL = "pdf_url"
        case examName = "exam_name"
        case hasSolution = "has_solution"
        case statistics
        case passRate = "pass_rate"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        courseCode = try c.decode(String.self, forKey: .courseCode)
        examDate = try c.decode(String.self, forKey: .examDate)
        pdfURL = try c.decode(String.self, forKey: .pdfURL)
        examName = try c.decode(String.self, forKey: .examName)
        hasSolution =
            try c.decodeIfPresent(Bool.self, forKey: .hasSolution) ?? false
        statistics = try c.decodeIfPresent(
            ExamStatistics.self,
            forKey: .statistics
        )
        passRate = try c.decodeIfPresent(Double.self, forKey: .passRate) ?? 0
    }
}

struct ExamStatistics: Decodable {
    let grade3: Double?
    let grade4: Double?
    let grade5: Double?
    let failed: Double?

    enum CodingKeys: String, CodingKey {
        case grade3 = "3"
        case grade4 = "4"
        case grade5 = "5"
        case failed = "U"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        grade3 = try c.decodeIfPresent(Double.self, forKey: .grade3)
        grade4 = try c.decodeIfPresent(Double.self, forKey: .grade4)
        grade5 = try c.decodeIfPresent(Double.self, forKey: .grade5)
        failed = try c.decodeIfPresent(Double.self, forKey: .failed)
    }
}
