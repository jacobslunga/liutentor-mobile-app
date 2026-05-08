//
//  PDFkitView.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import PDFKit
import SwiftUI

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.usePageViewController(false)
        view.backgroundColor = .systemBackground
        view.pageShadowsEnabled = false
        Task { await loadDocument(into: view) }
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        if view.document?.documentURL != url {
            Task { await loadDocument(into: view) }
        }
    }

    private func loadDocument(into view: PDFView) async {
        let document = await Task.detached(priority: .userInitiated) {
            PDFDocument(url: url)
        }.value
        await MainActor.run {
            view.document = document
        }
    }
}

struct PDFLoaderView: View {
    let urlString: String

    var body: some View {
        Group {
            if let url = URL(string: urlString) {
                PDFKitView(url: url)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.questionmark")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("Ogiltig PDF-länk")
                        .font(.system(.subheadline))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
