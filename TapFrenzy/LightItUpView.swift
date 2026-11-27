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

// Defines the 4 difficulty stages inside each 60-second round
enum Level: Int, CaseIterable {
    case l1 = 1
    case l2
    case l3
    case l4

    var label: String {
        "L\(rawValue)"
    }

    // Number of cards shown in the grid at this level
    var gridCount: Int {
        switch self {
        case .l1: return 3
        case .l2: return 4
        case .l3: return 6
        case .l4: return 9
        }
    }

    // How long each lit card stays active before expiring
    var litWindow: TimeInterval {
        switch self {
        case .l1: return 1.5
        case .l2: return 1.2
        case .l3: return 1.0
        case .l4: return 0.8
        }
    }

    // L4 allows up to 2 cards lit simultaneously
    var maxLitCount: Int {
        self == .l4 ? 2 : 1
    }

    // Interval between new card lights (faster in L4 so 2 cards can overlap)
    var spawnInterval: TimeInterval {
        self == .l4 ? 0.45 : litWindow
    }

    // Maps elapsed round time (0–60s) to the active level
    static func forElapsed(_ elapsed: TimeInterval) -> Level {
        switch elapsed {
        case ..<15: return .l1
        case ..<30: return .l2
        case ..<45: return .l3
        default: return .l4
        }
    }
}

struct LightItUpView: View {
    private enum RoundPhase {
        case idle
        case playing
        case over
    }

    // Tracks whether the round is waiting to start, running, or finished
    @State private var phase: RoundPhase = .idle

    // Current player score (clamped at 0 minimum)
    @State private var score = 0

    // Persists Light It Up's best score independently of Tap Frenzy
    @AppStorage("lightItUpHighScore") private var highScore = 0

    // Current level inside the 60-second round
    @State private var currentLevel: Level = .l1

    // Cards displayed in the grid
    @State private var cards: [Card] = (0..<Level.l1.gridCount).map { Card(id: $0) }

    // Seconds left in the 60-second round
    @State private var timeRemaining = 60

    // Timestamps used to run the 60s clock and card lighting windows accurately
    @State private var roundStartDate = Date()
    @State private var nextSpawnDate = Date()
    @State private var litDeadlines: [Int: Date] = [:]

    // Brief green/red feedback state when tapping a card
    @State private var flashedCardID: Int?
    @State private var flashColor: Color?
    @State private var flashID = 0

    // Adapts column count and card height for portrait vs landscape
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // 0.1s tick timer drives the countdown, level transitions, lighting, and expiration
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private let roundDuration = 60

    // Flexible grid columns so cards adapt cleanly across screen sizes and orientations
    private var columns: [GridItem] {
        let count: Int
        if verticalSizeClass == .compact {
            // Landscape: wider rows keep all cards visible without scrolling
            switch currentLevel {
            case .l1: count = 3
            case .l2: count = 4
            case .l3: count = 3
            case .l4: count = 5
            }
        } else {
            // Portrait: 2x2 for 4 cards, 3 columns otherwise
            count = currentLevel == .l2 ? 2 : 3
        }
        return Array(repeating: GridItem(.flexible(), spacing: 14), count: count)
    }

    var body: some View {
        VStack(spacing: 20) {
            // HUD bar showing score, best score, level, and remaining time
            HStack {
                hudStat(title: "Score", value: "\(score)")
                Spacer()
                hudStat(title: "Best", value: "\(highScore)")
                Spacer()
                hudStat(title: "Level", value: currentLevel.label)
                Spacer()
                hudStat(title: "Time", value: "\(timeRemaining)s")
            }
            .padding(.horizontal, 4)

            Spacer()

            switch phase {
            case .idle:
                VStack(spacing: 16) {
                    Text("Light It Up")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Tap glowing cards before they fade.\n4 levels over 60 seconds!")
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
                // Responsive grid of tappable cards
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(cards) { card in
                        Button(action: {
                            handleTap(on: card)
                        }) {
                            cardView(for: card)
                        }
                        .buttonStyle(.plain)
                    }
                }

            case .over:
                VStack(spacing: 16) {
                    Text("Time's Up!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Score: \(score)")
                        .font(.title)

                    Text("Best: \(highScore)")
                        .font(.title2)
                        .foregroundColor(.secondary)

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

    // Small helper view for consistent HUD labels
    private func hudStat(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
    }

    // Draws a single card with lit highlight, tap feedback flash, and scale animation
    private func cardView(for card: Card) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(cardFillColor(for: card))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(cardStrokeColor(for: card), lineWidth: 2)
            )
            .frame(height: verticalSizeClass == .compact ? 84 : 104)
            .scaleEffect(card.isLit ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: card.isLit)
    }

    private func cardFillColor(for card: Card) -> Color {
        if flashedCardID == card.id, let flashColor {
            return flashColor.opacity(0.8)
        }
        return card.isLit ? Color.yellow : Color.secondary.opacity(0.2)
    }

    private func cardStrokeColor(for card: Card) -> Color {
        if flashedCardID == card.id, let flashColor {
            return flashColor
        }
        return card.isLit ? Color.orange : Color.secondary.opacity(0.35)
    }

    // Starts a fresh 60-second round from Level 1
    private func startGame() {
        let now = Date()
        score = 0
        currentLevel = .l1
        cards = (0..<Level.l1.gridCount).map { Card(id: $0) }
        timeRemaining = roundDuration
        roundStartDate = now
        nextSpawnDate = now
        litDeadlines = [:]
        clearFlash()
        phase = .playing
    }

    // Stops the round cleanly when leaving the screen
    private func stopGame() {
        litDeadlines = [:]
        clearFlash()
        for index in cards.indices {
            cards[index].isLit = false
        }
        phase = .idle
    }

    // Handles player taps on lit vs unlit cards
    private func handleTap(on card: Card) {
        guard phase == .playing,
              let index = cards.firstIndex(where: { $0.id == card.id }) else {
            return
        }

        if cards[index].isLit {
            // Hit: award 1 point, turn off the card, and flash green
            score += 1
            cards[index].isLit = false
            litDeadlines.removeValue(forKey: card.id)
            triggerFlash(.green, on: card.id)
        } else {
            // Miss tap: apply 1-point penalty (minimum 0) and flash red
            score = max(0, score - 1)
            triggerFlash(.red, on: card.id)
        }
    }

    // Briefly flashes green or red on the tapped card using withAnimation
    private func triggerFlash(_ color: Color, on cardID: Int) {
        flashID += 1
        let activeFlash = flashID

        withAnimation(.easeInOut(duration: 0.15)) {
            flashedCardID = cardID
            flashColor = color
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard flashID == activeFlash else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                flashedCardID = nil
                flashColor = nil
            }
        }
    }

    private func clearFlash() {
        flashID += 1
        flashedCardID = nil
        flashColor = nil
    }

    // Updates clock, level progression, expired cards, and new card lights
    private func updateRound(at now: Date) {
        let elapsed = now.timeIntervalSince(roundStartDate)
        timeRemaining = max(0, roundDuration - Int(elapsed))

        if timeRemaining == 0 {
            endGame()
            return
        }

        // Advance level every 15 seconds and expand grid while preserving active lit cards
        let level = Level.forElapsed(elapsed)
        if level != currentLevel {
            currentLevel = level
            withAnimation(.easeInOut(duration: 0.25)) {
                for id in cards.count..<level.gridCount {
                    cards.append(Card(id: id))
                }
            }
        }

        // Turn off expired cards and apply miss penalty
        for index in cards.indices where cards[index].isLit {
            if let deadline = litDeadlines[cards[index].id], now >= deadline {
                cards[index].isLit = false
                litDeadlines.removeValue(forKey: cards[index].id)
                score = max(0, score - 1)
            }
        }

        // Light a random unlit card at the current level's cadence
        if now >= nextSpawnDate {
            lightRandomCard(for: currentLevel, at: now)
            nextSpawnDate = now.addingTimeInterval(currentLevel.spawnInterval)
        }
    }

    // Picks a random unlit card when below the level's simultaneous lit limit
    private func lightRandomCard(for level: Level, at now: Date) {
        let alreadyLitCount = cards.filter(\.isLit).count
        guard alreadyLitCount < level.maxLitCount else { return }

        let unlitIndices = cards.indices.filter { !cards[$0].isLit }
        guard let randomIndex = unlitIndices.randomElement() else { return }

        cards[randomIndex].isLit = true
        litDeadlines[cards[randomIndex].id] = now.addingTimeInterval(level.litWindow)
    }

    private func endGame() {
        if score > highScore {
            highScore = score
        }
        litDeadlines = [:]
        clearFlash()
        for index in cards.indices {
            cards[index].isLit = false
        }
        phase = .over
    }
}

#Preview {
    NavigationView {
        LightItUpView()
    }
    .navigationViewStyle(.stack)
}
