//
//  ScoreView.swift
//  Claude_Chess
//
//  Score display view showing position evaluation and game score
//  This view displays the current position evaluation from the chess engine
//  and provides access to scale settings for the evaluation display
//

import SwiftUI

/// Score view displaying position evaluation and game score
/// - Shows current position evaluation from chess engine
/// - Provides access to scale settings for evaluation display
struct ScoreView: View {
    @State private var showingScale = false

    var body: some View {
        List {
            Section(header: Text("Position Evaluation")) {
                // TODO: Display current position evaluation
                // This will show the engine's assessment of the current position
                // (e.g., +2.5 for White advantage, -1.2 for Black advantage)
                Text("Position evaluation will appear here")
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Game Statistics")) {
                // TODO: Display game statistics
                // Move count, captures, time remaining, etc.
                Text("Game statistics will appear here")
                    .foregroundColor(.secondary)
            }

            Section {
                NavigationLink(destination: ScaleView()) {
                    Label("Scale", systemImage: "slider.horizontal.3")
                }
            }
        }
        .navigationTitle("Score")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ScoreView()
    }
}
