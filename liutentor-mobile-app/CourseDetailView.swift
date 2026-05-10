//
//  CourseDetailView.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-04-29.
//

import SwiftUI

struct CourseDetailView: View {
    let courseCode: String

    @StateObject private var viewModel = CourseDetailViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingState()
            case .empty:
                EmptyState(courseCode: courseCode)
            case .failed(let error):
                ErrorState(error: error) {
                    Task { await viewModel.load(courseCode: courseCode) }
                }
            case .loaded:
                LoadedContent(courseCode: courseCode, viewModel: viewModel)
            }
        }
        .navigationTitle(courseCode)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load(courseCode: courseCode)
        }
    }
}

private struct LoadingState: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .controlSize(.regular)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct EmptyState: View {
    let courseCode: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.secondary)
            VStack(spacing: 4) {
                Text("Inga tentor hittades")
                    .font(.system(.subheadline))
                    .fontWeight(.medium)
                Text("Var den första att ladda upp tentor för \(courseCode)!")
                    .font(.system(.caption))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}

private struct ErrorState: View {
    let error: Error
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
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
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}

private struct LoadedContent: View {
    let courseCode: String
    @ObservedObject var viewModel: CourseDetailViewModel

    var body: some View {
        List {
            CourseSummarySection(
                courseName: viewModel.courseName,
                examCount: viewModel.exams.count,
                examsWithSolutions: viewModel.examsWithSolutions,
                avgPassRate: viewModel.avgPassRate
            )

            Section {
                if viewModel.filteredExams.isEmpty {
                    ContentUnavailableView(
                        "Inga tentor",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Ändra filtret för att visa tentor.")
                    )
                } else {
                    ForEach(viewModel.filteredExams) { exam in
                        NavigationLink(
                            value: ExamRoute(
                                courseCode: courseCode,
                                examId: exam.id,
                                examDate: exam.examDate
                            )
                        ) {
                            NativeExamRow(exam: exam)
                        }
                    }
                }
            } header: {
                Text(examSectionTitle)
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: ExamRoute.self) { route in
            ExamDetailView(
                examId: route.examId,
                courseCode: route.courseCode,
                examDate: route.examDate
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    viewModel.sortDescending.toggle()
                } label: {
                    Image(
                        systemName: viewModel.sortDescending
                            ? "arrow.down" : "arrow.up"
                    )
                }
                .accessibilityLabel("Sortera tentor")

                if viewModel.prefixes.count > 1 {
                    Menu {
                        ForEach(viewModel.prefixes, id: \.self) { prefix in
                            Button {
                                viewModel.toggleFilter(prefix)
                            } label: {
                                Label(
                                    prefix,
                                    systemImage: viewModel.activeFilters
                                        .contains(prefix)
                                        ? "checkmark.circle.fill" : "circle"
                                )
                            }
                        }

                        if !viewModel.activeFilters.isEmpty {
                            Divider()

                            Button("Rensa filter") {
                                viewModel.activeFilters.removeAll()
                            }
                        }
                    } label: {
                        Image(
                            systemName: viewModel.activeFilters.isEmpty
                                ? "line.3.horizontal.decrease.circle"
                                : "line.3.horizontal.decrease.circle.fill"
                        )
                    }
                    .accessibilityLabel("Filtrera tentor")
                }
            }
        }
    }

    private var examSectionTitle: String {
        guard !viewModel.activeFilters.isEmpty else { return "Tentor" }
        return
            "Tentor: \(viewModel.activeFilters.sorted().joined(separator: ", "))"
    }
}

private struct CourseSummarySection: View {
    let courseName: String?
    let examCount: Int
    let examsWithSolutions: Int
    let avgPassRate: Int?

    var body: some View {
        Section {
            if let courseName, !courseName.isEmpty {
                Text(courseName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LabeledContent("Antal tentor", value: "\(examCount)")
            LabeledContent("Med facit", value: "\(examsWithSolutions)")

            if let avgPassRate {
                LabeledContent("Genomsnitt godkända", value: "\(avgPassRate)%")
            }
        }
    }
}

private struct NativeExamRow: View {
    let exam: Exam

    var passColor: Color {
        if exam.passRate >= 50 { return .green }
        if exam.passRate >= 30 { return .orange }
        return .red
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exam.examName)
                    .font(.body)
                    .lineLimit(2)
                Text(exam.examDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if exam.passRate > 0 {
                    Text("\(Int(exam.passRate.rounded()))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(passColor)
                        .monospacedDigit()
                }

                if exam.hasSolution {
                    Label("Facit", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .labelStyle(.titleAndIcon)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ExamRoute: Hashable {
    let courseCode: String
    let examId: Int
    let examDate: String
}
