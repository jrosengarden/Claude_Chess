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
/// - Evaluation is triggered on-demand when user opens this view
struct ScoreView: View {
    @ObservedObject var game: ChessGame
    @AppStorage("evaluationScale") private var evaluationScale = "scaled"
    @State private var isEvaluating = false

    var body: some View {
        List {
            Section(header: Text("Position Evaluation")) {
                if isEvaluating {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Evaluating position...")
                            .foregroundColor(.secondary)
                    }
                } else if let evaluation = game.positionEvaluation {
                    // Display evaluation based on selected format
                    HStack {
                        Text("Current Position:")
                        Spacer()
                        Text(formattedEvaluation(evaluation))
                            .foregroundColor(evaluationColor(evaluation))
                            .fontWeight(.bold)
                    }

                    // Show interpretation
                    Text(evaluationInterpretation(evaluation))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !game.isAIOpponent {
                    Text("Start a game against AI to see position evaluation")
                        .foregroundColor(.secondary)
                } else if !game.gameInProgress {
                    Text("Tap 'Start Game' to begin")
                        .foregroundColor(.secondary)
                } else {
                    Text("Evaluation unavailable")
                        .foregroundColor(.secondary)
                }
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
        .onAppear {
            // Trigger evaluation when view appears (on-demand only)
            // This is the ONLY place in the app that triggers evaluation
            if game.isAIOpponent && game.gameInProgress && !isEvaluating {
                Task {
                    isEvaluating = true
                    await game.updatePositionEvaluation()
                    isEvaluating = false
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
    }

    /// Format evaluation based on selected scale
    private func formattedEvaluation(_ centipawns: Int) -> String {
        switch evaluationScale {
        case "centipawns":
            // Display as +250 or -150
            if centipawns >= 0 {
                return "+\(centipawns) cp"
            } else {
                return "\(centipawns) cp"
            }
        case "scaled":
            // Display as +5 or -3 (terminal project format)
            let scaled = StockfishEngine.centipawnsToScale(centipawns)
            if scaled >= 0 {
                return "+\(scaled)"
            } else {
                return "\(scaled)"
            }
        case "percentage":
            // Convert to win probability (rough approximation)
            let probability = winProbability(centipawns: centipawns)
            return "\(probability)%"
        default:
            return "\(centipawns) cp"
        }
    }

    /// Get color for evaluation display
    private func evaluationColor(_ centipawns: Int) -> SwiftUI.Color {
        if centipawns > 50 {
            return SwiftUI.Color.green  // White advantage
        } else if centipawns < -50 {
            return SwiftUI.Color.red    // Black advantage
        } else {
            return SwiftUI.Color.primary  // Roughly equal
        }
    }

    /// Get human-readable interpretation of evaluation
    private func evaluationInterpretation(_ centipawns: Int) -> String {
        let abs_cp = abs(centipawns)

        if abs_cp >= 1000 {
            return centipawns > 0 ? "White has overwhelming advantage" : "Black has overwhelming advantage"
        } else if abs_cp >= 500 {
            return centipawns > 0 ? "White has significant advantage" : "Black has significant advantage"
        } else if abs_cp >= 200 {
            return centipawns > 0 ? "White has moderate advantage" : "Black has moderate advantage"
        } else if abs_cp >= 100 {
            return centipawns > 0 ? "White has slight advantage" : "Black has slight advantage"
        } else {
            return "Position is roughly equal"
        }
    }

    /// Convert centipawns to win probability percentage
    /// Uses sigmoid approximation: 50 + 50 * (2 / (1 + e^(-cp/400)) - 1)
    private func winProbability(centipawns: Int) -> Int {
        let cp = Double(centipawns)
        let sigmoid = 2.0 / (1.0 + exp(-cp / 400.0)) - 1.0
        let probability = 50.0 + 50.0 * sigmoid
        return Int(probability.rounded())
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ScoreView(game: ChessGame())
    }
}
