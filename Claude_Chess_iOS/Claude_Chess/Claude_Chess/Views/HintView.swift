//
//  HintView.swift
//  Claude_Chess
//
//  Created by Jeff Rosengarden on 10/9/25.
//

import SwiftUI

/// View for displaying move hints from the AI engine
/// Matches terminal project's HINT command functionality
struct HintView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header icon
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .padding(.top, 40)

            Text("Move Hint")
                .font(.largeTitle)
                .fontWeight(.bold)

            Divider()
                .padding(.horizontal)

            // Placeholder content
            VStack(spacing: 16) {
                Text("AI analysis will suggest the best move for the current position.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // TODO: Phase 2 - Implement actual hint functionality
                // - Request hint from selected engine (Stockfish/Lichess/Chess.com)
                // - Display suggested move in algebraic notation
                // - Show brief explanation or evaluation
                // - Highlight suggested move on board preview
                // - Match terminal project's fast depth-based hint system

                Text("Coming in Phase 2")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(SwiftUI.Color.blue.opacity(0.1))
                    )
            }
            .padding()

            Spacer()
        }
        .navigationTitle("Hint")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        HintView()
    }
}
