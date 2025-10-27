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
    @AppStorage("stockfishPlaysColor") private var stockfishPlaysColor = "black" // "white" or "black"
    @AppStorage("boardFlipped") private var boardFlipped: Bool = false

    // Time control settings (need to swap when color changes)
    @AppStorage("whiteMinutes") private var whiteMinutes = 30
    @AppStorage("whiteIncrement") private var whiteIncrement = 10
    @AppStorage("blackMinutes") private var blackMinutes = 5
    @AppStorage("blackIncrement") private var blackIncrement = 0

    @ObservedObject var game: ChessGame

    // Engine test state
    @State private var showingEngineTest = false
    @State private var engineTestResults = ""
    @State private var isRunningEngineTest = false

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

            Section(header: Text("Stockfish Plays")) {
                Picker("Stockfish Plays", selection: $stockfishPlaysColor) {
                    Text("White").tag("white")
                    Text("Black").tag("black")
                }
                .pickerStyle(SegmentedPickerStyle())
                .disabled(isSkillLevelLockEnabled)
                .opacity(isSkillLevelLockEnabled ? 0.5 : 1.0)
                .onChange(of: stockfishPlaysColor) { oldValue, newValue in
                    // Auto-flip board when Stockfish plays White (human plays Black)
                    // Board normal orientation when Stockfish plays Black (human plays White)
                    boardFlipped = (newValue == "white")

                    // Swap time controls so user always gets the "White" time allocation
                    // When Stockfish plays White: human plays Black, so give human the White time
                    // When Stockfish plays Black: human plays White, keep normal allocation
                    let tempWhiteMin = whiteMinutes
                    let tempWhiteInc = whiteIncrement
                    let tempBlackMin = blackMinutes
                    let tempBlackInc = blackIncrement

                    whiteMinutes = tempBlackMin
                    whiteIncrement = tempBlackInc
                    blackMinutes = tempWhiteMin
                    blackIncrement = tempWhiteInc
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(stockfishPlaysColor == "white" ? "You are playing Black" : "You are playing White")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Color selection cannot be changed after the game starts.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.top, 8)
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

            Section(header: Text("Diagnostics")) {
                Button {
                    isRunningEngineTest = true
                    Task {
                        engineTestResults = await EngineTest.runEngineTest()
                        isRunningEngineTest = false
                        showingEngineTest = true
                    }
                } label: {
                    HStack {
                        if isRunningEngineTest {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        Text("Run Integration Tests")
                    }
                }
                .disabled(isRunningEngineTest)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Verify Stockfish engine is working correctly on this device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Stockfish")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEngineTest) {
            NavigationView {
                EngineTestResultsView(results: engineTestResults)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingEngineTest = false
                            }
                        }
                    }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
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

/// Engine test results display view
struct EngineTestResultsView: View {
    let results: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(results)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
        }
        .navigationTitle("Stockfish Test Results")
        .navigationBarTitleDisplayMode(.inline)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        StockfishSettingsView(game: ChessGame())
    }
}
