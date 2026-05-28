//
//  Font+Extension.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-05-28.
//

import SwiftUI

extension Font {
    static func app(
        _ style: Font.TextStyle = .body,
        weight: Font.Weight = .regular
    ) -> Font {
        .custom(circularName(for: weight), size: style.defaultSize, relativeTo: style)
    }

    static func app(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(circularName(for: weight), size: size)
    }

    private static func circularName(for weight: Font.Weight) -> String {
        switch weight {
        case .medium, .semibold, .bold, .heavy, .black:
            return "CircularStd-Medium"
        default:
            return "CircularStd-Book"
        }
    }
}

extension Font.TextStyle {
    var defaultSize: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        default: return 17
        }
    }
}

struct AppFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.environment(\.font, .app())
    }
}

extension View {
    func useAppFont() -> some View { modifier(AppFontModifier()) }
}
