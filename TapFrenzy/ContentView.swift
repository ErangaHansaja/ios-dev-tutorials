//
//  ContentView.swift
//  TapFrenzy
//
//  Created by Eranga Hansaja on 2026-11-13.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 30) {
            // Timer display at the top
            Text("Time: 10")
                .font(.title)
                .fontWeight(.semibold)

            // Current score shown big and bold in the middle
            Text("0")
                .font(.system(size: 80, weight: .heavy))

            // Big circular button for the user to tap
            Button(action: {
                // Button action will be added in the next step
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
