//
//  MarkdownMessage.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import LaTeXSwiftUI
import SwiftUI

struct MarkdownMessage: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var blocks: [Block] {
        BlockParser.parse(content)
    }

    @ViewBuilder
    private func renderBlock(_ block: Block) -> some View {
        switch block {
        case .heading(let level, let text):
            InlineLine(
                text: text,
                baseFont: headingFont(level),
                weight: .semibold
            )
            .padding(.top, level == 1 ? 6 : 2)

        case .paragraph(let text):
            InlineLine(text: text, baseFont: .system(.body))

        case .displayMath(let latex):
            ScrollView(.horizontal, showsIndicators: false) {
                LaTeX("$$" + latex + "$$")
                    .parsingMode(.onlyEquations)
                    .errorMode(.original)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )

        case .codeBlock(let code, let language):
            CodeBlockView(code: code, language: language)

        case .listItem(let text, let ordered, let number):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(ordered ? "\(number)." : "•")
                    .font(.system(.body))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, alignment: .leading)
                InlineLine(
                    text: text,
                    baseFont: .system(.body)
                )
            }
            .padding(.leading, 4)

        case .quote(let text):
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 3)
                InlineLine(
                    text: text,
                    baseFont: .system(.body)
                )
                .foregroundStyle(.secondary)
                .italic()
            }
            .padding(.vertical, 2)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .system(.title2)
        case 2: return .system(.title3)
        case 3: return .system(.headline)
        default: return .system(.subheadline)
        }
    }
}

private struct InlineLine: View {
    let text: String
    let baseFont: Font
    var weight: Font.Weight = .regular

    var body: some View {
        let segments = InlineSegmenter.segment(text)

        if segments.allSatisfy({
            if case .text = $0 { return true } else { return false }
        }) {
            renderTextOnly(segments)
        } else {
            renderMixed(segments)
        }
    }

    private func renderTextOnly(_ segments: [InlineSegment]) -> Text {
        let combined = segments.compactMap { seg -> String? in
            if case .text(let str) = seg { return str }
            return nil
        }.joined()

        if let attributed = try? AttributedString(
            markdown: combined,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attributed).font(baseFont).fontWeight(weight)
        }
        return Text(combined).font(baseFont).fontWeight(weight)
    }

    @ViewBuilder
    private func renderMixed(_ segments: [InlineSegment]) -> some View {
        FlowingText(segments: segments, baseFont: baseFont, weight: weight)
    }
}

private struct FlowingText: View {
    let segments: [InlineSegment]
    let baseFont: Font
    let weight: Font.Weight

    var body: some View {
        WrappingHStack(
            alignment: .leading,
            horizontalSpacing: 2,
            verticalSpacing: 4
        ) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                switch seg {
                case .text(let str):
                    ForEach(
                        Array(splitIntoTokens(str).enumerated()),
                        id: \.offset
                    ) { _, token in
                        if let attributed = try? AttributedString(
                            markdown: token,
                            options: .init(
                                interpretedSyntax:
                                    .inlineOnlyPreservingWhitespace
                            )
                        ) {
                            Text(attributed).font(baseFont).fontWeight(weight)
                        } else {
                            Text(token).font(baseFont).fontWeight(weight)
                        }
                    }
                case .inlineMath(let latex):
                    LaTeX("$" + latex + "$")
                        .parsingMode(.onlyEquations)
                        .errorMode(.original)
                        .font(baseFont)
                }
            }
        }
    }

    private func splitIntoTokens(_ str: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        for char in str {
            if char == " " {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                tokens.append(" ")
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens.filter { !$0.isEmpty }
    }
}

private struct WrappingHStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let content: () -> Content

    init(
        alignment: HorizontalAlignment = .leading,
        horizontalSpacing: CGFloat = 4,
        verticalSpacing: CGFloat = 4,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content
    }

    var body: some View {
        FlowLayout(
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        ) {
            content()
        }
    }
}

private struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let result = computeLayout(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews
        )
        return result.size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = computeLayout(in: bounds.width, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + frame.minX,
                    y: bounds.minY + frame.minY
                ),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func computeLayout(in maxWidth: CGFloat, subviews: Subviews) -> (
        size: CGSize, frames: [CGRect]
    ) {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
            maxRowWidth = max(maxRowWidth, x - horizontalSpacing)
        }

        return (CGSize(width: maxRowWidth, height: y + rowHeight), frames)
    }
}

enum InlineSegment {
    case text(String)
    case inlineMath(String)
}

enum InlineSegmenter {
    static func segment(_ input: String) -> [InlineSegment] {
        var segments: [InlineSegment] = []
        var current = ""
        var i = input.startIndex

        while i < input.endIndex {
            let char = input[i]
            if char == "$" {
                if let closeIndex = findClosingDollar(in: input, after: i) {
                    if !current.isEmpty {
                        segments.append(.text(current))
                        current = ""
                    }
                    let mathStart = input.index(after: i)
                    let math = String(input[mathStart..<closeIndex])
                    segments.append(.inlineMath(math))
                    i = input.index(after: closeIndex)
                    continue
                }
            }
            current.append(char)
            i = input.index(after: i)
        }

        if !current.isEmpty {
            segments.append(.text(current))
        }
        return segments
    }

    private static func findClosingDollar(
        in input: String,
        after openIndex: String.Index
    ) -> String.Index? {
        var i = input.index(after: openIndex)
        while i < input.endIndex {
            let char = input[i]
            if char == "$" {
                let between = input[input.index(after: openIndex)..<i]
                if !between.isEmpty && !between.contains("\n") {
                    return i
                }
                return nil
            }
            i = input.index(after: i)
        }
        return nil
    }
}

private struct CodeBlockView: View {
    let code: String
    let language: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let lang = language, !lang.isEmpty {
                Text(lang)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.callout, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }
}

enum Block {
    case heading(level: Int, text: String)
    case paragraph(String)
    case displayMath(String)
    case codeBlock(code: String, language: String?)
    case listItem(text: String, ordered: Bool, number: Int)
    case quote(String)
}

enum BlockParser {
    static func parse(_ source: String) -> [Block] {
        var blocks: [Block] = []
        let lines = source.components(separatedBy: "\n")
        var i = 0
        var orderedCounter = 0
        var paragraphBuffer: [String] = []

        func flushParagraph() {
            if !paragraphBuffer.isEmpty {
                let text = paragraphBuffer.joined(separator: " ")
                    .trimmingCharacters(in: .whitespaces)
                if !text.isEmpty {
                    blocks.append(.paragraph(text))
                }
                paragraphBuffer.removeAll()
            }
        }

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                flushParagraph()
                orderedCounter = 0
                i += 1
                continue
            }

            if trimmed == "$$" {
                flushParagraph()
                var mathLines: [String] = []
                var j = i + 1
                while j < lines.count
                    && lines[j].trimmingCharacters(in: .whitespaces) != "$$"
                {
                    mathLines.append(lines[j])
                    j += 1
                }
                blocks.append(
                    .displayMath(
                        mathLines.joined(separator: "\n").trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    )
                )
                i = j + 1
                orderedCounter = 0
                continue
            }

            if trimmed.hasPrefix("$$") && trimmed.hasSuffix("$$")
                && trimmed.count > 4
            {
                flushParagraph()
                let math = String(trimmed.dropFirst(2).dropLast(2))
                    .trimmingCharacters(in: .whitespaces)
                blocks.append(.displayMath(math))
                i += 1
                orderedCounter = 0
                continue
            }

            if trimmed.hasPrefix("```") {
                flushParagraph()
                let language = String(trimmed.dropFirst(3)).trimmingCharacters(
                    in: .whitespaces
                )
                var codeLines: [String] = []
                var j = i + 1
                while j < lines.count
                    && !lines[j].trimmingCharacters(in: .whitespaces).hasPrefix(
                        "```"
                    )
                {
                    codeLines.append(lines[j])
                    j += 1
                }
                blocks.append(
                    .codeBlock(
                        code: codeLines.joined(separator: "\n"),
                        language: language.isEmpty ? nil : language
                    )
                )
                i = j + 1
                orderedCounter = 0
                continue
            }

            if let heading = parseHeading(trimmed) {
                flushParagraph()
                blocks.append(heading)
                i += 1
                orderedCounter = 0
                continue
            }

            if trimmed.hasPrefix("> ") {
                flushParagraph()
                blocks.append(.quote(String(trimmed.dropFirst(2))))
                i += 1
                orderedCounter = 0
                continue
            }

            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                flushParagraph()
                blocks.append(
                    .listItem(
                        text: String(trimmed.dropFirst(2)),
                        ordered: false,
                        number: 0
                    )
                )
                i += 1
                orderedCounter = 0
                continue
            }

            if let orderedText = parseOrderedListItem(trimmed) {
                flushParagraph()
                orderedCounter += 1
                blocks.append(
                    .listItem(
                        text: orderedText,
                        ordered: true,
                        number: orderedCounter
                    )
                )
                i += 1
                continue
            }

            paragraphBuffer.append(trimmed)
            i += 1
        }

        flushParagraph()
        return blocks
    }

    private static func parseHeading(_ line: String) -> Block? {
        let prefixes = [("# ", 1), ("## ", 2), ("### ", 3), ("#### ", 4)]
        for (prefix, level) in prefixes {
            if line.hasPrefix(prefix) {
                return .heading(
                    level: level,
                    text: String(line.dropFirst(prefix.count))
                )
            }
        }
        return nil
    }

    private static func parseOrderedListItem(_ line: String) -> String? {
        guard let firstSpace = line.firstIndex(of: " ") else { return nil }
        let prefix = line[..<firstSpace]
        guard prefix.hasSuffix("."), Int(prefix.dropLast()) != nil else {
            return nil
        }
        return String(line[line.index(after: firstSpace)...])
    }
}
