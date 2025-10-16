//
//  StockfishSettingsView.swift
//  Claude_Chess
//
//  Stockfish engine configuration view
//  Allows user to configure Stockfish-specific settings including
//  skill level (0-20) matching terminal project implementation
//

import SwiftUI

/// Stockfish engine settings view
/// - Skill level configuration (0-20)
/// - Default skill level: 5 (matches terminal project)
struct StockfishSettingsView: View {
    @AppStorage("selectedEngine") private var selectedEngine = "stockfish"
    @AppStorage("stockfishSkillLevel") private var skillLevel = 5
    @ObservedObject var game: ChessGame

    /// Check if skill level selection is locked (game has started)
    private var isSkillLevelLockEnabled: Bool {
        return game.gameInProgress || !game.moveHistory.isEmpty
    }

    var body: some View {
        List {
            Section(header: Text("Engine Selection")) {
                // Lock warning if game has started
                if isSkillLevelLockEnabled {
                    Text("Opponent and skill level cannot be changed after game has started. Start a New Game to change settings.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.vertical, 4)
                }

                Button(action: {
                    if !isSkillLevelLockEnabled {
                        selectedEngine = "stockfish"
                    }
                }) {
                    HStack {
                        Text("Use Stockfish")
                        Spacer()
                        if selectedEngine == "stockfish" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isSkillLevelLockEnabled)
                .opacity(isSkillLevelLockEnabled ? 0.5 : 1.0)
            }

            Section(header: Text("Skill Level")) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Level: \(skillLevel)")
                            .font(.headline)
                        Spacer()
                        Text(skillLevelDescription(skillLevel))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(skillLevel) },
                        set: { skillLevel = Int($0) }
                    ), in: 0...20, step: 1)
                    .disabled(isSkillLevelLockEnabled)
                    .opacity(isSkillLevelLockEnabled ? 0.5 : 1.0)

                    // Informational text
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Skill level 0 = beginner, 20 = maximum strength.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Skill level cannot be changed after the game starts.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 8)
                }
            }

            Section(header: Text("About Stockfish")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stockfish is a free, open-source chess engine and one of the strongest in the world.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Skill level allows you to adjust the playing strength from beginner (0) to world-class (20).")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("This implementation matches the terminal project's Stockfish integration with UCI protocol support.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("License")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stockfish License")
                        .font(.headline)

                    Text("Stockfish is free software licensed under the GNU General Public License version 3 (GPLv3).")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Copyright © 2004-2024 The Stockfish developers (see AUTHORS file)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Website: https://stockfishchess.org")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Stockfish")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Returns human-readable description of skill level
    private func skillLevelDescription(_ level: Int) -> String {
        switch level {
        case 0...3:
            return "Beginner"
        case 4...7:
            return "Casual"
        case 8...12:
            return "Intermediate"
        case 13...16:
            return "Advanced"
        case 17...19:
            return "Expert"
        case 20:
            return "Maximum"
        default:
            return "Unknown"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        StockfishSettingsView(game: ChessGame())
    }
}
