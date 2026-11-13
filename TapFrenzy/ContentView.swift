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

    var body: some View {
        VStack(spacing: 30) {
            // Timer display at the top
            Text("Time: 10")
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
    }
}

#Preview {
    ContentView()
}
