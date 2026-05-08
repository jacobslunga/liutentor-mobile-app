//
//  CourseDetailViewModel.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Combine
import Foundation

@MainActor
final class CourseDetailViewModel: ObservableObject {
    enum LoadState {
        case idle
        case loading
        case loaded(ExamsResult)
        case empty
        case failed(Error)
    }

    @Published private(set) var state: LoadState = .idle
    @Published var sortDescending: Bool = true
    @Published var activeFilters: Set<String> = []

    private let service: ExamServiceProtocol

    init(service: ExamServiceProtocol? = nil) {
        self.service = service ?? ExamService()
    }
    
    func load(courseCode: String) async {
        state = .loading
        do {
            if let result = try await service.fetchExams(for: courseCode) {
                state = .loaded(result)
            } else {
                state = .empty
            }
        } catch {
            state = .failed(error)
        }
    }

    var exams: [Exam] {
        if case .loaded(let result) = state { return result.exams }
        return []
    }

    var courseName: String? {
        if case .loaded(let result) = state { return result.courseName }
        return nil
    }

    var prefixes: [String] {
        let all = exams.compactMap {
            $0.examName.split(separator: " ").first.map(String.init)
        }
        return Array(Set(all)).sorted()
    }

    var filteredExams: [Exam] {
        let sorted = exams.sorted { a, b in
            sortDescending ? a.examDate > b.examDate : a.examDate < b.examDate
        }
        guard !activeFilters.isEmpty else { return sorted }
        return sorted.filter { exam in
            guard let prefix = exam.examName.split(separator: " ").first else {
                return false
            }
            return activeFilters.contains(String(prefix))
        }
    }

    var examsWithSolutions: Int {
        exams.filter { $0.hasSolution }.count
    }

    var avgPassRate: Int? {
        let valid = exams.filter { $0.passRate > 0 }
        guard !valid.isEmpty else { return nil }
        let sum = valid.reduce(0.0) { $0 + $1.passRate }
        return Int((sum / Double(valid.count)).rounded())
    }

    func toggleFilter(_ prefix: String) {
        if activeFilters.contains(prefix) {
            activeFilters.remove(prefix)
        } else {
            activeFilters.insert(prefix)
        }
    }
}
