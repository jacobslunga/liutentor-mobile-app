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
        .navigationBarTitleDisplayMode(.inline)
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
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            VStack(spacing: 4) {
                Text("Inga tentor hittades")
                    .font(.system(.subheadline, weight: .medium))
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
                .font(.system(size: 32))
                .foregroundStyle(.orange)
            Text("Något gick fel")
                .font(.system(.subheadline, weight: .medium))
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

    @State private var selectedExam: ExamRoute?

    var body: some View {
        List {
            if let name = viewModel.courseName, !name.isEmpty {
                Text(name)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .listRowSeparator(.hidden)
                    .listRowInsets(
                        EdgeInsets(
                            top: 12,
                            leading: 16,
                            bottom: 8,
                            trailing: 16
                        )
                    )
            }

            if viewModel.filteredExams.isEmpty {
                ContentUnavailableView(
                    "Inga tentor",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Ändra filtret för att visa tentor.")
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(viewModel.filteredExams) { exam in
                    Button {
                        selectedExam = ExamRoute(
                            courseCode: courseCode,
                            examId: exam.id,
                            examDate: exam.examDate
                        )
                    } label: {
                        ExamRow(exam: exam)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.plain)
        .fullScreenCover(item: $selectedExam) { route in
            NavigationStack {
                ExamDetailView(
                    examId: route.examId,
                    courseCode: courseCode,
                    examDate: route.examDate
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            selectedExam = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .frame(width: 28, height: 28)

                        }
                    }
                }
            }
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
}

private struct ExamRow: View {
    let exam: Exam

    private var examPrefix: String? {
        exam.examName.split(separator: " ").first.map(String.init)
    }

    private var passColor: Color {
        if exam.passRate >= 50 { return .green }
        if exam.passRate >= 30 { return .orange }
        return .red
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exam.examName)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(exam.examDate)
                    .font(.system(.subheadline))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if let prefix = examPrefix {
                Text(prefix)
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .strokeBorder(
                                Color.primary.opacity(0.15),
                                lineWidth: 1
                            )
                    )
            }

            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    exam.hasSolution ? .green : Color.primary.opacity(0.15)
                )
                .frame(width: 18)

            if exam.passRate > 0 {
                Text(String(format: "%.1f%%", exam.passRate))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(passColor)
                    .monospacedDigit()
                    .frame(minWidth: 56, alignment: .trailing)
            } else {
                Text("—")
                    .font(.system(.subheadline))
                    .foregroundStyle(.tertiary)
                    .frame(minWidth: 56, alignment: .trailing)
            }
        }
        .padding(.vertical, 6)
    }
}

struct ExamRoute: Hashable, Identifiable {
    let courseCode: String
    let examId: Int
    let examDate: String

    var id: Int { examId }
}
