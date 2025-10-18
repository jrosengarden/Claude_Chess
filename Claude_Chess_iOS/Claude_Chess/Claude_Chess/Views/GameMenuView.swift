//
//  GameMenuView.swift
//  Claude_Chess
//
//  Game menu for chess-specific commands and features
//  This menu provides access to game controls, time settings, and chess features
//  that differ from app-level settings (which are in SettingsView)
//

import SwiftUI

/// Game menu providing access to chess-specific commands and features
/// - New Game, Setup Board, Import Games, Time Controls, Undo, Hint, Resign, etc.
struct GameMenuView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var game: ChessGame
    @State private var showingScore = false
    @State private var showingAbout = false
    @State private var showingFenSetup = false
    @State private var showingFenError = false
    @State private var showingSavePrompt = false
    @State private var fenInput = ""
    @State private var fenError = ""
    @State private var validatedFenString = ""  // Store valid FEN for save prompt flow

    // Opponent settings from @AppStorage for engine initialization
    @AppStorage("selectedEngine") private var selectedEngine = "human"
    @AppStorage("stockfishSkillLevel") private var skillLevel = 5

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Game")) {
                    Button(action: {
                        Task {
                            await game.resetGame(selectedEngine: selectedEngine, skillLevel: skillLevel)
                            dismiss()
                        }
                    }) {
                        Label("New Game", systemImage: "plus.circle")
                    }

                    // Note: Manual save removed - replaced by auto-save on game end (Settings toggles)
                    // and Share Game for mid-game sharing

                    Button(action: {
                        fenInput = ""
                        fenError = ""
                        showingFenSetup = true
                    }) {
                        Label("Setup Game Board", systemImage: "square.grid.3x3")
                    }

                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                            .foregroundColor(.accentColor)
                    }
                }

                Section(header: Text("Game Controls")) {
                    NavigationLink(destination: OpponentView(game: game)) {
                        Label("Opponent", systemImage: "cpu")
                            .foregroundColor(.accentColor)
                    }

                    NavigationLink(destination: TimeControlsView(game: game)) {
                        Label("Time Controls", systemImage: "clock")
                            .foregroundColor(.accentColor)
                    }
                }

                Section(header: Text("Import Games")) {
                    Button(action: {
                        // TODO: Import FEN action (load .fen files with position navigation + save prompt)
                    }) {
                        Label("Import FEN", systemImage: "square.and.arrow.down.on.square")
                    }

                    Button(action: {
                        // TODO: Import PGN action (load .pgn files with move-by-move navigation + save prompt)
                    }) {
                        Label("Import PGN", systemImage: "arrow.up.doc")
                    }

                    Button(action: {
                        // TODO: Share Game action (mid-game sharing via iOS share sheet)
                    }) {
                        Label("Share Game", systemImage: "square.and.arrow.up")
                    }
                }

                Section(header: Text("Actions")) {
                    Button(role: .destructive, action: {
                        // TODO: Resign action
                    }) {
                        Label("Resign", systemImage: "flag")
                    }
                }
            }
            .navigationTitle("Game Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Setup Game Board", isPresented: $showingFenSetup) {
                TextField("Paste FEN string", text: $fenInput)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Button("Setup") {
                    // Step 1: Validate FEN string first (don't proceed if invalid)
                    // Create a temporary game to test FEN validity without modifying current game
                    let testGame = ChessGame()
                    if testGame.setupFromFEN(fenInput) {
                        // FEN is valid - store it for later use
                        validatedFenString = fenInput
                        fenError = ""

                        // Step 2: Check if game is in progress - if so, prompt to save
                        if game.gameInProgress {
                            showingSavePrompt = true
                        } else {
                            // No game in progress - apply setup immediately
                            applySetupBoard()
                        }
                    } else {
                        // FEN is invalid - show error and stop
                        fenError = "Invalid FEN string entered. Please check the format and try again."
                        showingFenError = true
                    }
                }
                Button("Cancel", role: .cancel) {
                    fenInput = ""
                    fenError = ""
                }
            } message: {
                Text("Enter a valid FEN string to set up the board position")
            }
            .alert("Save Current Game?", isPresented: $showingSavePrompt) {
                Button("Yes") {
                    // TODO: Save current game to file (Phase 3 - file operations)
                    // For now, just proceed with setup
                    applySetupBoard()
                }
                Button("No") {
                    // Don't save - just proceed with setup
                    applySetupBoard()
                }
                Button("Cancel", role: .cancel) {
                    // User changed their mind - return to game menu
                    validatedFenString = ""
                    fenInput = ""
                }
            } message: {
                Text("Do you want to save the current game before setting up a new board position?")
            }
            .alert("Invalid FEN String", isPresented: $showingFenError) {
                Button("OK") {
                    // Return to Game Menu (dismiss is called automatically)
                }
            } message: {
                Text(fenError)
            }
        }
    }

    // MARK: - Helper Functions

    /// Apply Setup Board with validated FEN string
    /// Resets game state and loads FEN position
    private func applySetupBoard() {
        // Reset game state (timers, move history, gameInProgress)
        game.moveHistory.removeAll()
        game.gameInProgress = false
        game.moveStartTime = nil
        game.timeControlsDisabledByUndo = false

        // Load the validated FEN position
        let success = game.setupFromFEN(validatedFenString)

        if success {
            // Increment reset trigger to clear UI state in ChessBoardView
            game.resetTrigger += 1

            // Clear saved FEN and input
            validatedFenString = ""
            fenInput = ""

            // Dismiss menu
            dismiss()
        } else {
            // This shouldn't happen since we validated before, but handle it just in case
            fenError = "Unexpected error applying FEN setup"
            showingFenError = true
        }
    }
}

// MARK: - Preview

#Preview {
    GameMenuView(game: ChessGame())
}
