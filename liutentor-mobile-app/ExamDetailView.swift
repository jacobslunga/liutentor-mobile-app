//
//  ExamDetailView.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import SwiftUI

struct ExamDetailView: View {
    let examId: Int
    let courseCode: String
    let examDate: String

    @StateObject private var viewModel = ExamDetailViewModel()
    @State private var showSolution = false
    @State private var showChat = false

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failed(let error):
                ExamErrorView(error: error) {
                    Task { await viewModel.load(examId: examId) }
                }

            case .loaded(let detail):
                LoadedExamView(
                    detail: detail,
                    courseCode: courseCode,
                    examDate: examDate,
                    showSolution: $showSolution,
                    showChat: $showChat
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(examDate)
                        .font(.system(.subheadline))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(courseCode)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showChat = true
                } label: {
                    Image(systemName: "captions.bubble")
                        .font(.system(size: 15, weight: .semibold))
                }

                if case .loaded(let detail) = viewModel.state,
                    detail.solution != nil
                {
                    Button {
                        showSolution = true
                    } label: {
                        Image(systemName: "book")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
        }
        .tint(.primary)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await viewModel.load(examId: examId)
        }
    }
}

private struct LoadedExamView: View {
    let detail: ExamDetail
    let courseCode: String
    let examDate: String
    @Binding var showSolution: Bool
    @Binding var showChat: Bool
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var chatViewModel: ChatViewModel

    init(
        detail: ExamDetail,
        courseCode: String,
        examDate: String,
        showSolution: Binding<Bool>,
        showChat: Binding<Bool>
    ) {
        self.detail = detail
        self.courseCode = courseCode
        self.examDate = examDate
        self._showSolution = showSolution
        self._showChat = showChat

        self._chatViewModel = StateObject(
            wrappedValue: ChatViewModel(
                examId: detail.exam.id,
                courseCode: courseCode,
                examURL: detail.exam.pdfURL,
                solutionURL: detail.solution?.pdfURL
            )
        )
    }

    var body: some View {
        PDFLoaderView(urlString: detail.exam.pdfURL)
            .background(pdfBackground.ignoresSafeArea(edges: .bottom))
            .sheet(isPresented: $showSolution) {
                if let solutionURL = solutionPDFURL {
                    SolutionSheet(
                        pdfURL: solutionURL,
                        courseCode: courseCode,
                        examDate: examDate
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(
                        .enabled(upThrough: .medium)
                    )
                    .presentationContentInteraction(.scrolls)
                }
            }
            .fullScreenCover(isPresented: $showChat) {
                ChatView(
                    viewModel: chatViewModel
                )
            }
    }

    private var pdfBackground: Color {
        colorScheme == .dark ? .black : .white
    }

    private var solutionPDFURL: String? {
        guard let pdfURL = detail.solution?.pdfURL, !pdfURL.isEmpty else {
            return nil
        }
        return pdfURL
    }
}

private struct SolutionSheet: View {
    let pdfURL: String
    let courseCode: String
    let examDate: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            PDFLoaderView(urlString: pdfURL)
                .navigationTitle("Facit")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text("Facit")
                                .font(.system(.subheadline))
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text("\(courseCode) · \(examDate)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                        }
                    }
                }
                .tint(.primary)
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationBackground(sheetBackground)
    }

    private var sheetBackground: Color {
        colorScheme == .dark ? .black : Color(.systemBackground)
    }
}

private struct ExamErrorView: View {
    let error: Error
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.orange)
            Text("Något gick fel")
                .font(.system(.subheadline))
                .fontWeight(.medium)
            Text(error.localizedDescription)
                .font(.system(.caption))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Försök igen", action: onRetry)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}
