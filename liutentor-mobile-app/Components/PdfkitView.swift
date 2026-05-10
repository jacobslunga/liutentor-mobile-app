//
//  PDFkitView.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-08.
//

import Foundation
import PDFKit
import SwiftUI

struct PDFKitView: UIViewRepresentable {
    let url: URL
    let scrollToTopRequest: Int
    @Binding var showsScrollToTopButton: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(
            scrollToTopRequest: scrollToTopRequest,
            showsScrollToTopButton: $showsScrollToTopButton
        )
    }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.usePageViewController(false)
        configureBackground(for: view)
        view.pageShadowsEnabled = false
        Task { await loadDocument(into: view, coordinator: context.coordinator) }
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        configureBackground(for: view)
        configureScrollTracking(in: view, context: context)

        if view.document?.documentURL != url {
            Task {
                await loadDocument(
                    into: view,
                    coordinator: context.coordinator
                )
            }
        }

        if context.coordinator.scrollToTopRequest != scrollToTopRequest {
            context.coordinator.scrollToTopRequest = scrollToTopRequest
            scrollToTop(in: view, animated: true)
            context.coordinator.setShowsScrollToTopButton(false)
        }
    }

    private func loadDocument(
        into view: PDFView,
        coordinator: Coordinator
    ) async {
        let document = await Task.detached(priority: .userInitiated) {
            PDFDocument(url: url)
        }.value
        await MainActor.run {
            view.document = document
            scrollToTop(in: view, animated: false)
            coordinator.setShowsScrollToTopButton(false)
            configureBackground(for: view)
            DispatchQueue.main.async {
                configureBackground(for: view)
                if let scrollView = findScrollView(in: view) {
                    coordinator.startTracking(scrollView)
                }
            }
        }
    }

    private func configureBackground(for view: PDFView) {
        view.backgroundColor = .clear
        view.isOpaque = false
        clearBackgrounds(in: view)
    }

    private func clearBackgrounds(in view: UIView) {
        view.backgroundColor = .clear
        view.isOpaque = false

        for subview in view.subviews {
            clearBackgrounds(in: subview)
        }
    }

    private func scrollToTop(in view: PDFView, animated: Bool) {
        if animated, let scrollView = findScrollView(in: view) {
            let topOffset = CGPoint(
                x: scrollView.contentOffset.x,
                y: -scrollView.adjustedContentInset.top
            )
            scrollView.setContentOffset(topOffset, animated: true)
            return
        }

        guard let firstPage = view.document?.page(at: 0) else { return }
        view.go(to: firstPage)
    }

    private func configureScrollTracking(
        in view: PDFView,
        context: Context
    ) {
        guard let scrollView = findScrollView(in: view) else { return }
        context.coordinator.startTracking(scrollView)
    }

    private func findScrollView(in view: UIView) -> UIScrollView? {
        scrollViews(in: view).max {
            $0.contentSize.height < $1.contentSize.height
        }
    }

    private func scrollViews(in view: UIView) -> [UIScrollView] {
        let nested = view.subviews.flatMap { scrollViews(in: $0) }
        guard let scrollView = view as? UIScrollView else { return nested }
        return [scrollView] + nested
    }

    final class Coordinator: NSObject {
        private let visibilityThreshold: CGFloat = 300
        private var showsScrollToTopButton: Binding<Bool>
        private var contentOffsetObservation: NSKeyValueObservation?
        var scrollToTopRequest: Int
        weak var scrollView: UIScrollView?

        init(
            scrollToTopRequest: Int,
            showsScrollToTopButton: Binding<Bool>
        ) {
            self.scrollToTopRequest = scrollToTopRequest
            self.showsScrollToTopButton = showsScrollToTopButton
        }

        func startTracking(_ scrollView: UIScrollView) {
            guard self.scrollView !== scrollView else {
                updateVisibility(for: scrollView)
                return
            }

            self.scrollView = scrollView
            contentOffsetObservation = scrollView.observe(
                \.contentOffset,
                options: [.initial, .new]
            ) { [weak self, weak scrollView] _, _ in
                guard let self, let scrollView else { return }
                self.updateVisibility(for: scrollView)
            }
        }

        func updateVisibility(for scrollView: UIScrollView) {
            let topOffset = -scrollView.adjustedContentInset.top
            let isPastThreshold =
                scrollView.contentOffset.y - topOffset > visibilityThreshold

            setShowsScrollToTopButton(isPastThreshold)
        }

        func setShowsScrollToTopButton(_ isVisible: Bool) {
            DispatchQueue.main.async {
                if self.showsScrollToTopButton.wrappedValue != isVisible {
                    withAnimation(
                        .spring(response: 0.25, dampingFraction: 0.85)
                    ) {
                        self.showsScrollToTopButton.wrappedValue =
                            isVisible
                    }
                }
            }
        }
    }
}

struct PDFLoaderView: View {
    let urlString: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var scrollToTopRequest = 0
    @State private var showsScrollToTopButton = false

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            if let url = URL(string: urlString) {
                PDFKitView(
                    url: url,
                    scrollToTopRequest: scrollToTopRequest,
                    showsScrollToTopButton: $showsScrollToTopButton
                )
                    .modifier(PDFDarkModeModifier(isEnabled: colorScheme == .dark))
                    .background(backgroundColor)

                if showsScrollToTopButton {
                    VStack {
                        Spacer()
                        Button {
                            withAnimation(
                                .spring(response: 0.25, dampingFraction: 0.85)
                            ) {
                                scrollToTopRequest += 1
                                showsScrollToTopButton = false
                            }
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 44, height: 44)
                                .background {
                                    Circle()
                                        .fill(controlBackground)
                                        .background(.ultraThinMaterial, in: Circle())
                                        .overlay {
                                            Circle()
                                                .strokeBorder(
                                                    Color.primary.opacity(0.12),
                                                    lineWidth: 1
                                                )
                                        }
                                }
                        }
                        .accessibilityLabel("Scrolla till toppen")
                        .padding(.bottom, 16)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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
        .animation(
            .spring(response: 0.25, dampingFraction: 0.85),
            value: showsScrollToTopButton
        )
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }

    private var controlBackground: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.72)
            : Color.white.opacity(0.86)
    }
}

private struct PDFDarkModeModifier: ViewModifier {
    let isEnabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.colorInvert()
        } else {
            content
        }
    }
}
