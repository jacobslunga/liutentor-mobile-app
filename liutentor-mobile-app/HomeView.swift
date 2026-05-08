//
//  ContentView.swift
//  liutentor-mobile-app
//
//  Created by Jacob Slunga on 2026-04-29.
//

import SwiftUI

struct HomeView: View {
    
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            LandingView { courseCode in
                navPath.append(courseCode)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { courseCode in
                CourseDetailView(courseCode: courseCode)
            }
        }
    }
}

struct LandingView: View {
    var onSelect: (String) -> Void

    @State private var searchText = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                LogoHeader()
                Spacer()
            }

            FloatingSearchBar(
                text: $searchText,
                onSubmit: { code in
                    searchText = ""
                    onSelect(code)
                }
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

struct LogoHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Logo(logoSize: 72, showText: false)
            Text("LiU Tentor")
                .font(.custom("GTSuperTxtTrial-Md", size: 36))
                .tracking(-1)
        }
    }
}

struct FloatingSearchBar: View {
    @Binding var text: String
    var onSubmit: (String) -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            TextField("Sök kurskod...", text: $text)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .font(.system(.body))
                .tint(.liutentorPrimary)
                .padding(8)
                .onChange(of: text) { _, newValue in
                    text = newValue.uppercased()
                }
                .onSubmit {
                    if !text.isEmpty { onSubmit(text) }
                }

            Button {
                if !text.isEmpty { onSubmit(text) }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle().fill(
                            text.isEmpty
                                ? Color.secondary.opacity(0.4)
                                : .liutentorPrimary
                        )
                    )
            }
            .disabled(text.isEmpty)
            .animation(
                .spring(response: 0.25, dampingFraction: 0.7),
                value: text.isEmpty
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            Capsule()
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                }
        }
        .onAppear {
            isFocused = true
        }
    }
}
