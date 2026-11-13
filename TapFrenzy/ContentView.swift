//
//  ContentView.swift
//  TapFrenzy
//
//  Created by Eranga Hansaja on 2026-11-13.
//

import SwiftUI

struct ContentView: View {
    // Stores the player's current tap score
    @State private var score = 0

    // Number of seconds left in the game round
    @State private var timeRemaining = 10

    // Timer that fires every 1 second on the main thread
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 30) {
            // Timer display at the top
            Text("Time: \(timeRemaining)")
                .font(.title)
                .fontWeight(.semibold)

            // Current score shown big and bold in the middle
            Text("\(score)")
                .font(.system(size: 80, weight: .heavy))

            // Big circular button for the user to tap
            Button(action: {
                // Add 1 to the score on every tap
                score += 1
            }) {
                Text("TAP")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 200)
                    .background(Circle().fill(Color.blue))
            }
        }
        .padding()
        // Decrement the timer every second
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
}

#Preview {
    ContentView()
}
