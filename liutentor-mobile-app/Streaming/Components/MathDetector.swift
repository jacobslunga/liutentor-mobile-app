//
//  MathDetector.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-28.
//

import Foundation

enum MathDetector {
    /// Returns true when the text contains LaTeX math delimiters likely to require KaTeX rendering.
    static func containsMath(_ text: String) -> Bool {
        // Display math $$...$$ is the most common case from LLM output
        if text.contains("$$") { return true }
        // Inline math: $...$ — require a letter or backslash immediately after $
        // to avoid false positives on prices like "$5.99"
        if text.range(
            of: #"\$[a-zA-Z\\{][^$\n]{0,400}\$"#,
            options: .regularExpression
        ) != nil {
            return true
        }
        // LaTeX bracket delimiters \[...\] and \(...\)
        if text.contains("\\[") || text.contains("\\(") { return true }
        return false
    }
}
