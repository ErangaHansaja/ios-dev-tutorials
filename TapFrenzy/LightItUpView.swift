//
//  LightItUpView.swift
//  TapFrenzy
//

import SwiftUI

// Represents a single card tile in the Light It Up grid
struct Card: Identifiable {
    let id: Int
    var isLit = false
}

struct LightItUpView: View {
    private enum RoundPhase {
        case idle
        case playing
        case over
    }

    // Tracks whether the round is waiting to start, running, or finished
    @State private var phase: RoundPhase = .idle

    // Cards displayed in the grid
    @State private var cards: [Card] = (0..<3).map { Card(id: $0) }

    // Seconds left in the 60-second round
    @State private var timeRemaining = 60

    // Timestamps used to run the 60s clock and card lighting windows accurately
    @State private var roundStartDate = Date()
    @State private var nextSpawnDate = Date()
    @State private var litDeadlines: [Int: Date] = [:]

    // Adapts column count and card height for portrait vs landscape
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // 0.1s tick timer drives the countdown, lighting, and auto turn-off
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private let roundDuration = 60
    private let defaultLitWindow: TimeInterval = 1.5

    // Flexible grid columns so cards adapt cleanly across screen sizes and orientations
    private var columns: [GridItem] {
        let count = verticalSizeClass == .compact ? 3 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 14), count: count)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Simple HUD bar showing remaining time
            HStack {
                Text("Time: \(timeRemaining)s")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 4)

            Spacer()

            switch phase {
            case .idle:
                VStack(spacing: 16) {
                    Text("Light It Up")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Tap cards as soon as they light up!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Start Game") {
                        startGame()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.large)
                }

            case .playing:
                // Responsive grid of cards
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(cards) { card in
                        cardView(for: card)
                    }
                }

            case .over:
                VStack(spacing: 16) {
                    Text("Time's Up!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Button("Play Again") {
                        startGame()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.large)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Light It Up")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            stopGame()
        }
        .onReceive(timer) { _ in
            guard phase == .playing else { return }
            updateRound(at: Date())
        }
    }

    // Draws a single card with highlight color and smooth scale animation when lit
    private func cardView(for card: Card) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(card.isLit ? Color.yellow : Color.secondary.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(card.isLit ? Color.orange : Color.secondary.opacity(0.35), lineWidth: 2)
            )
            .frame(height: verticalSizeClass == .compact ? 84 : 110)
            .scaleEffect(card.isLit ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: card.isLit)
    }

    // Starts a fresh 60-second round
    private func startGame() {
        let now = Date()
        cards = (0..<3).map { Card(id: $0) }
        timeRemaining = roundDuration
        roundStartDate = now
        nextSpawnDate = now
        litDeadlines = [:]
        phase = .playing
    }

    // Stops the game if the user navigates back to Home
    private func stopGame() {
        litDeadlines = [:]
        for index in cards.indices {
            cards[index].isLit = false
        }
        phase = .idle
    }

    // Updates clock, expires timed-out cards, and lights a new random card
    private func updateRound(at now: Date) {
        let elapsed = now.timeIntervalSince(roundStartDate)
        timeRemaining = max(0, roundDuration - Int(elapsed))

        if timeRemaining == 0 {
            litDeadlines = [:]
            for index in cards.indices {
                cards[index].isLit = false
            }
            phase = .over
            return
        }

        // Turn off any card whose lit window has expired
        for index in cards.indices where cards[index].isLit {
            if let deadline = litDeadlines[cards[index].id], now >= deadline {
                cards[index].isLit = false
                litDeadlines.removeValue(forKey: cards[index].id)
            }
        }

        // Light up one random unlit card on each interval
        if now >= nextSpawnDate {
            lightRandomCard(at: now)
            nextSpawnDate = now.addingTimeInterval(defaultLitWindow)
        }
    }

    // Picks a random unlit card and turns it on for the lit window
    private func lightRandomCard(at now: Date) {
        let alreadyLitCount = cards.filter(\.isLit).count
        guard alreadyLitCount < 1 else { return }

        let unlitIndices = cards.indices.filter { !cards[$0].isLit }
        guard let randomIndex = unlitIndices.randomElement() else { return }

        cards[randomIndex].isLit = true
        litDeadlines[cards[randomIndex].id] = now.addingTimeInterval(defaultLitWindow)
    }
}

#Preview {
    NavigationView {
        LightItUpView()
    }
    .navigationViewStyle(.stack)
}
