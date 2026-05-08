//
//  MarkdownMessage.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import LaTeXSwiftUI
import SwiftUI
import MarkdownUI

struct MarkdownMessage: View {
    let content: String

    var body: some View {
        Markdown(content)
            .markdownTheme(.gitHub)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
