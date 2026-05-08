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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CourseHeader(
                    courseCode: courseCode,
                    courseName: viewModel.courseName ?? "",
                    examCount: viewModel.exams.count,
                    examsWithSolutions: viewModel.examsWithSolutions,
                    avgPassRate: viewModel.avgPassRate
                )

                if viewModel.prefixes.count > 1 {
                    FilterRow(
                        prefixes: viewModel.prefixes,
                        activeFilters: viewModel.activeFilters,
                        onToggle: viewModel.toggleFilter
                    )
                }

                ExamTable(
                    exams: viewModel.filteredExams,
                    sortDescending: $viewModel.sortDescending,
                    courseCode: courseCode
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

private struct CourseHeader: View {
    let courseCode: String
    let courseName: String
    let examCount: Int
    let examsWithSolutions: Int
    let avgPassRate: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Text(courseCode)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text("/")
                    .foregroundStyle(.tertiary)
                Text("Tentor")
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)
            }

            Text(courseName)
                .font(.system(.title2))
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                StatBadge(
                    icon: "doc.text",
                    value: "\(examCount)",
                    label: "tentor"
                )
                StatBadge(
                    icon: "checkmark.circle",
                    value: "\(examsWithSolutions)",
                    label: "med facit"
                )
                if let rate = avgPassRate {
                    StatBadge(
                        icon: "chart.line.uptrend.xyaxis",
                        value: "\(rate)%",
                        label: "snitt godkänd",
                        valueColor: passColor(rate)
                    )
                }
            }
        }
    }

    private func passColor(_ rate: Int) -> Color {
        if rate >= 50 { return .green }
        if rate >= 30 { return .orange }
        return .red
    }
}

private struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.caption))
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
            Text(label)
                .font(.system(.caption))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct FilterRow: View {
    let prefixes: [String]
    let activeFilters: Set<String>
    let onToggle: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(prefixes, id: \.self) { prefix in
                    let isActive = activeFilters.contains(prefix)
                    Button {
                        onToggle(prefix)
                    } label: {
                        Text(prefix)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 6,
                                    style: .continuous
                                )
                                .fill(isActive ? Color.primary : Color.clear)
                                .overlay(
                                    RoundedRectangle(
                                        cornerRadius: 6,
                                        style: .continuous
                                    )
                                    .strokeBorder(
                                        isActive
                                            ? Color.primary
                                            : Color.primary.opacity(0.15),
                                        lineWidth: 1
                                    )
                                )
                            )
                            .foregroundStyle(
                                isActive ? Color(.systemBackground) : .secondary
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(
                        .spring(response: 0.25, dampingFraction: 0.8),
                        value: isActive
                    )
                }
            }
        }
    }
}

private struct ExamTable: View {
    let exams: [Exam]
    @Binding var sortDescending: Bool
    let courseCode: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    sortDescending.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Text("Tentamen")
                            .font(.system(.caption))
                            .foregroundStyle(.secondary)
                        Image(
                            systemName: sortDescending
                                ? "arrow.down" : "arrow.up"
                        )
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Facit")
                    .font(.system(.caption))
                    .foregroundStyle(.secondary)
                    .frame(width: 50)

                Text("Godkänd")
                    .font(.system(.caption))
                    .foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.03))

            ForEach(Array(exams.enumerated()), id: \.element.id) {
                index,
                exam in
                NavigationLink(
                    value: ExamRoute(
                        courseCode: courseCode,
                        examId: exam.id,
                        examDate: exam.examDate
                    )
                ) {
                    ExamRow(exam: exam)
                }
                .buttonStyle(.plain)

                if index < exams.count - 1 {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .navigationDestination(for: ExamRoute.self) { route in
            ExamDetailView(
                examId: route.examId,
                courseCode: route.courseCode,
                examDate: route.examDate
            )
        }
    }
}

private struct ExamRow: View {
    let exam: Exam

    var prefix: String {
        String(exam.examName.split(separator: " ").first ?? "")
    }

    var passColor: Color {
        if exam.passRate >= 50 { return .green }
        if exam.passRate >= 30 { return .orange }
        return .red
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exam.examName)
                    .font(.system(.subheadline))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(exam.examDate)
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Group {
                if exam.hasSolution {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(width: 50)

            Text(exam.passRate > 0 ? "\(Int(exam.passRate.rounded()))%" : "—")
                .font(.system(.caption))
                .fontWeight(.medium)
                .foregroundStyle(exam.passRate > 0 ? passColor : .secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

struct ExamRoute: Hashable {
    let courseCode: String
    let examId: Int
    let examDate: String
}
