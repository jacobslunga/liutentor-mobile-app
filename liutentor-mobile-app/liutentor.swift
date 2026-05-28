//
//  liutentor.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-04-29.
//

import SwiftUI
import UIKit

@main
struct liutentor: App {
    init() {
        configureNavigationBarFonts()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .useAppFont()
        }
    }

    private func configureNavigationBarFonts() {
        let inline = UIFont(name: "CircularStd-Medium", size: 17)
            ?? .systemFont(ofSize: 17, weight: .semibold)
        let large = UIFont(name: "CircularStd-Medium", size: 34)
            ?? .systemFont(ofSize: 34, weight: .bold)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [.font: inline]
        appearance.largeTitleTextAttributes = [.font: large]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}
