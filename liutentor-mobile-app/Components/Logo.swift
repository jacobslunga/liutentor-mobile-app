//
//  Logo.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-04-29.
//

import SwiftUI

struct Logo: View {
    var logoSize: CGFloat
    var showText: Bool

    init(logoSize: CGFloat = 50, showText: Bool = true) {
        self.logoSize = logoSize
        self.showText = showText
    }

    var body: some View {
        HStack(spacing: 8) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: logoSize, height: logoSize)

            if showText {
                Text("LiU Tentor")
                    .font(
                        Font.custom("GTSuperTxtTrial-Md", size: logoSize * 0.7)
                    ).foregroundStyle(.liutentorPrimary)
            }
        }
    }
}
