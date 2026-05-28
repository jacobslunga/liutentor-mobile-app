//
//  MarkdownMessage.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import SwiftUI

struct MarkdownMessage: View {
    let content: String

    @Environment(\.colorScheme) private var colorScheme
    @State private var webViewHeight: CGFloat = 40

    var body: some View {
        MathContentWebView(
            markdownContent: content,
            isDark: colorScheme == .dark,
            contentHeight: $webViewHeight
        )
        .frame(height: webViewHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
