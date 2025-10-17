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
    @ObservedObject var game: ChessGame
    @State private var isLoading = false

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

            // Hint content
            VStack(spacing: 16) {
                if !game.gameInProgress {
                    // Game not started yet
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)

                        Text("Game Not Started")
                            .font(.headline)

                        Text("Tap \"Start Game\" in the Quick Menu before requesting hints.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if isLoading {
                    // Loading state
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Analyzing position...")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else if let hint = game.currentHint {
                    // Display hint
                    Text("Suggested Move:")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(formatHintMove(hint))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(SwiftUI.Color.blue.opacity(0.1))
                        )

                    Text(hintDescription(hint))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if game.engine == nil {
                    // No AI engine available
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)

                        Text("Hints Unavailable")
                            .font(.headline)

                        Text("Hints require an AI engine. Select Stockfish, Lichess, or Chess.com in the Opponent settings to enable hints.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    // Engine available but no hint yet
                    Text("Tap \"Request Hint\" to get the AI's suggested move for the current position.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        Task {
                            isLoading = true
                            await game.requestHint()
                            isLoading = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "lightbulb")
                            Text("Request Hint")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(SwiftUI.Color.yellow.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .padding()

            Spacer()
        }
        .navigationTitle("Hint")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Clear previous hint when view appears
            game.currentHint = nil
        }
    }

    /// Format UCI move notation for display
    /// - Parameter uciMove: UCI move string (e.g., "e2e4", "e7e8q")
    /// - Returns: Human-readable move notation
    private func formatHintMove(_ uciMove: String) -> String {
        guard uciMove.count >= 4 else { return uciMove }

        let from = String(uciMove.prefix(2))
        let to = String(uciMove.dropFirst(2).prefix(2))

        // Check for promotion
        if uciMove.count == 5 {
            let promotionChar = uciMove.last!
            let pieceName: String
            switch promotionChar.lowercased() {
            case "q": pieceName = "Queen"
            case "r": pieceName = "Rook"
            case "b": pieceName = "Bishop"
            case "n": pieceName = "Knight"
            default: pieceName = "?"
            }
            return "\(from) → \(to) (=\(pieceName))"
        }

        return "\(from) → \(to)"
    }

    /// Get descriptive text for hint move
    /// - Parameter uciMove: UCI move string
    /// - Returns: Description of the move
    private func hintDescription(_ uciMove: String) -> String {
        guard uciMove.count >= 4 else { return "" }

        let from = uciMove.prefix(2).uppercased()
        let to = uciMove.dropFirst(2).prefix(2).uppercased()

        if uciMove.count == 5 {
            return "Move your piece from \(from) to \(to) and promote"
        } else {
            return "Move your piece from \(from) to \(to)"
        }
    }
}

#Preview {
    NavigationView {
        HintView(game: ChessGame())
    }
}
