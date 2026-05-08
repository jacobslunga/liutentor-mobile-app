//
//  ExamResult.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Foundation

struct ExamsEnvelope: Decodable {
    let data: ExamsResult
}

struct ExamsResult: Decodable {
    let courseCode: String
    let courseName: String
    let exams: [Exam]

    enum CodingKeys: String, CodingKey {
        case courseCode
        case courseName
        case exams
    }
}
