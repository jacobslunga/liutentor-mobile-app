//
//  MarkdownParser.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Foundation

enum MarkdownBlock {
    case paragraph(String)
    case heading(level: Int, text: String)
    case displayMath(String)
    case codeBlock(code: String, language: String?)
    case listItem(text: String, ordered: Bool, number: Int)
    case quote(String)
}

enum MarkdownParser {
    static func parse(_ source: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = source.components(separatedBy: "\n")
        var i = 0
        var orderedCounter = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("$$") {
                if let endIndex = findClosingDisplayMath(
                    lines: lines,
                    startIndex: i
                ) {
                    let mathLines = lines[(i + 1)..<endIndex]
                    let math = mathLines.joined(separator: "\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    blocks.append(.displayMath(math))
                    i = endIndex + 1
                    orderedCounter = 0
                    continue
                } else if trimmed.hasSuffix("$$") && trimmed.count > 4 {
                    let math = String(trimmed.dropFirst(2).dropLast(2))
                        .trimmingCharacters(in: .whitespaces)
                    blocks.append(.displayMath(math))
                    i += 1
                    orderedCounter = 0
                    continue
                }
            }

            if trimmed.hasPrefix("```") {
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
                blocks.append(heading)
                i += 1
                orderedCounter = 0
                continue
            }

            if trimmed.hasPrefix("> ") {
                let text = String(trimmed.dropFirst(2))
                blocks.append(.quote(text))
                i += 1
                orderedCounter = 0
                continue
            }

            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                let text = String(trimmed.dropFirst(2))
                blocks.append(.listItem(text: text, ordered: false, number: 0))
                i += 1
                orderedCounter = 0
                continue
            }

            if let orderedMatch = parseOrderedListItem(trimmed) {
                orderedCounter += 1
                blocks.append(
                    .listItem(
                        text: orderedMatch,
                        ordered: true,
                        number: orderedCounter
                    )
                )
                i += 1
                continue
            }

            if !trimmed.isEmpty {
                blocks.append(.paragraph(trimmed))
            }
            i += 1
            orderedCounter = 0
        }

        return blocks
    }

    private static func findClosingDisplayMath(lines: [String], startIndex: Int)
        -> Int?
    {
        let opener = lines[startIndex].trimmingCharacters(in: .whitespaces)
        if opener == "$$" {
            for k in (startIndex + 1)..<lines.count {
                if lines[k].trimmingCharacters(in: .whitespaces) == "$$" {
                    return k
                }
            }
        }
        return nil
    }

    private static func parseHeading(_ line: String) -> MarkdownBlock? {
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
