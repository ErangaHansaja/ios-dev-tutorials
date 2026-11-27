//
//  LightItUpView.swift
//  TapFrenzy
//

import SwiftUI

struct LightItUpView: View {
    var body: some View {
        Text("Light It Up")
            .font(.title)
            .navigationTitle("Light It Up")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        LightItUpView()
    }
    .navigationViewStyle(.stack)
}
