//
//  ContentView.swift
//  TapFrenzy
//
//  Created by Eranga Hansaja on 2026-11-13.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // NavigationView with .stack style is required for iOS 15 compatibility
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Arcade Mini Games")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Choose a game to play")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Game selection buttons
                VStack(spacing: 16) {
                    NavigationLink(destination: TapFrenzyView()) {
                        gameCard(
                            title: "Tap Frenzy",
                            subtitle: "Tap fast, avoid the red trap",
                            color: .blue
                        )
                    }

                    NavigationLink(destination: LightItUpView()) {
                        gameCard(
                            title: "Light It Up",
                            subtitle: "Hit the glowing cards before they fade",
                            color: .orange
                        )
                    }
                }
                .frame(maxWidth: 360)
            }
            .padding()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Keeps single-column navigation on iPhone Plus models in landscape
        .navigationViewStyle(.stack)
    }

    // Builds a large, friendly NavigationLink card button
    private func gameCard(title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.subheadline)
                .opacity(0.9)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
        )
    }
}

#Preview {
    ContentView()
}
