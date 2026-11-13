//
//  ContentView.swift
//  TapFrenzy
//
//  Created by Eranga Hansaja on 2026-11-13.
//

import SwiftUI

// Defines the different states of the game
enum GamePhase {
    case idle
    case playing
    case over
}

struct ContentView: View {
    // Current game phase: idle, playing, or over
    @State private var phase: GamePhase = .idle

    // Stores the player's current tap score
    @State private var score = 0

    // Number of seconds left in the game round
    @State private var timeRemaining = 10

    // Saves the highest score on the device so it persists across launches
    @AppStorage("highScore") private var highScore = 0

    // Timer that fires every 1 second on the main thread
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 30) {
            // Show different UI depending on the current game phase
            switch phase {
            case .idle, .playing:
                // Timer display at the top
                Text("Time: \(timeRemaining)")
                    .font(.title)
                    .fontWeight(.semibold)

                // Current score shown big and bold in the middle
                Text("\(score)")
                    .font(.system(size: 80, weight: .heavy))

                // Big circular button for the user to tap
                Button(action: {
                    // First tap starts the game
                    if phase == .idle {
                        phase = .playing
                    }
                    // Tap immediately scores a point
                    if phase == .playing {
                        score += 1
                    }
                }) {
                    Text("TAP")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 200)
                        .background(Circle().fill(Color.blue))
                }

                // Helpful hint shown only before the game starts
                if phase == .idle {
                    Text("Tap to start!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

            case .over:
                // Game over summary screen
                Text("Game Over!")
                    .font(.largeTitle)
                    .bold()

                Text("Score: \(score)")
                    .font(.title)

                Text("Best: \(highScore)")
                    .font(.title2)
                    .foregroundColor(.secondary)

                // Reset button to play another round
                Button("Play Again") {
                    score = 0
                    timeRemaining = 10
                    phase = .idle
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        // Handle the countdown timer
        .onReceive(timer) { _ in
            guard phase == .playing else { return }

            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Save new high score if beaten, then end game
                if score > highScore {
                    highScore = score
                }
                phase = .over
            }
        }
    }
}

#Preview {
    ContentView()
}
