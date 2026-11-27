//
//  TapFrenzyView.swift
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

struct TapFrenzyView: View {
    // Current game phase: idle, playing, or over
    @State private var phase: GamePhase = .idle

    // Stores the player's current tap score
    @State private var score = 0

    // Number of seconds left in the game round
    @State private var timeRemaining = 10

    // Current width and height of the button, starts at 200 and shrinks with each tap
    @State private var buttonSize: CGFloat = 200

    // Indicates whether the button is currently flashing red as a trap
    @State private var isTrap = false

    // Identifies the active round so timers from previous rounds are safely ignored
    @State private var roundID = 0

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
                    // First tap starts the game and trap timer
                    if phase == .idle {
                        phase = .playing
                        scheduleTrap(for: roundID)
                    }

                    // Handle tap scoring
                    if phase == .playing {
                        if isTrap {
                            // Penalty tap: deduct 1 point (minimum 0)
                            score = max(0, score - 1)
                        } else {
                            // Normal tap: shrink button and add 1 point
                            buttonSize = max(90, buttonSize - 5)
                            score += 1
                        }
                    }
                }) {
                    Text("TAP")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: buttonSize, height: buttonSize)
                        .background(Circle().fill(isTrap ? Color.red : Color.blue))
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
                    resetRound()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .navigationTitle("Tap Frenzy")
        .navigationBarTitleDisplayMode(.inline)
        // Reset active round timers if the player navigates back to Home
        .onDisappear {
            resetRound()
        }
        // Handle the countdown timer
        .onReceive(timer) { _ in
            guard phase == .playing else { return }

            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Save new high score if beaten, reset trap, and end game
                if score > highScore {
                    highScore = score
                }
                isTrap = false
                phase = .over
            }
        }
    }

    // Resets all game state and invalidates pending trap callbacks
    private func resetRound() {
        roundID += 1
        isTrap = false
        buttonSize = 200
        score = 0
        timeRemaining = 10
        phase = .idle
    }

    // Schedules periodic red trap flashes every ~2 seconds while playing
    private func scheduleTrap(for currentRound: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Only trigger if still playing and in the same round
            guard phase == .playing, roundID == currentRound else { return }

            // Turn button red
            isTrap = true

            // Keep it red for 0.5 seconds, then turn back to blue
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard roundID == currentRound else { return }
                isTrap = false

                // Continue the trap cycle if the round is still active
                if phase == .playing {
                    scheduleTrap(for: currentRound)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        TapFrenzyView()
    }
    .navigationViewStyle(.stack)
}
