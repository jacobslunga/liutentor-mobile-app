//
//  ExamDetail.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Foundation

struct ExamDetailEnvelope: Decodable {
    let data: ExamDetail
}

struct ExamDetail: Decodable {
    let exam: ExamDetailBody
    let solution: Solution?

    enum CodingKeys: String, CodingKey {
        case exam
        case solution
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        exam = try c.decode(ExamDetailBody.self, forKey: .exam)
        solution = try c.decodeIfPresent(Solution.self, forKey: .solution)
    }
}

struct ExamDetailBody: Decodable, Identifiable {
    let id: Int
    let courseCode: String
    let examDate: String
    let pdfURL: String

    enum CodingKeys: String, CodingKey {
        case id
        case courseCode = "course_code"
        case examDate = "exam_date"
        case pdfURL = "pdf_url"
    }
}

struct Solution: Decodable, Identifiable {
    let id: Int
    let examId: Int
    let pdfURL: String

    enum CodingKeys: String, CodingKey {
        case id
        case examId = "exam_id"
        case pdfURL = "pdf_url"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        examId = try c.decode(Int.self, forKey: .examId)
        pdfURL = try c.decodeIfPresent(String.self, forKey: .pdfURL) ?? ""
    }
}
