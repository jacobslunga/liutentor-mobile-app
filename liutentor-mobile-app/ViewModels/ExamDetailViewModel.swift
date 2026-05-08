//
//  ExamDetailViewModel.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Foundation
import Combine

@MainActor
final class ExamDetailViewModel: ObservableObject {
    enum LoadState {
        case idle
        case loading
        case loaded(ExamDetail)
        case failed(Error)
    }

    @Published private(set) var state: LoadState = .idle

    private let service: ExamServiceProtocol

    init(service: ExamServiceProtocol = ExamService()) {
        self.service = service
    }

    func load(examId: Int) async {
        state = .loading
        do {
            let detail = try await service.fetchExam(by: examId)
            state = .loaded(detail)
        } catch {
            state = .failed(error)
        }
    }
}
