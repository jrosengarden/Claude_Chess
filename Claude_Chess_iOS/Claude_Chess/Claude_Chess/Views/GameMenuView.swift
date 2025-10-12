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
/// - New Game, Load/Save, Time Controls, Undo, Hint, Resign, etc.
struct GameMenuView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var game: ChessGame
    @State private var showingScore = false
    @State private var showingAbout = false
    @State private var showingFenSetup = false
    @State private var fenInput = ""
    @State private var fenError = ""

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Game")) {
                    Button(action: {
                        game.resetGame()
                        dismiss()
                    }) {
                        Label("New Game", systemImage: "plus.circle")
                    }

                    Button(action: {
                        // TODO: Save game action
                    }) {
                        Label("Save Game", systemImage: "square.and.arrow.down")
                    }

                    Button(action: {
                        fenInput = ""
                        fenError = ""
                        showingFenSetup = true
                    }) {
                        Label("Setup Game Board", systemImage: "square.grid.3x3")
                    }

                    NavigationLink(destination: ScoreView()) {
                        Label("Score", systemImage: "chart.bar")
                            .foregroundColor(.accentColor)
                    }

                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                            .foregroundColor(.accentColor)
                    }
                }

                Section(header: Text("Game Controls")) {
                    NavigationLink(destination: OpponentView()) {
                        Label("Opponent", systemImage: "cpu")
                            .foregroundColor(.accentColor)
                    }

                    NavigationLink(destination: TimeControlsView()) {
                        Label("Time Controls", systemImage: "clock")
                            .foregroundColor(.accentColor)
                    }

                    Button(action: {
                        // TODO: Undo move action
                    }) {
                        Label("Undo Move", systemImage: "arrow.uturn.backward")
                    }

                    NavigationLink(destination: HintView()) {
                        Label("Hint", systemImage: "lightbulb")
                            .foregroundColor(.accentColor)
                    }
                }

                Section(header: Text("Import/Export")) {
                    Button(action: {
                        // TODO: Import FEN action
                    }) {
                        Label("Import FEN", systemImage: "square.and.arrow.down.on.square")
                    }

                    Button(action: {
                        // TODO: Export FEN action
                    }) {
                        Label("Export FEN", systemImage: "square.and.arrow.up.on.square")
                    }

                    Button(action: {
                        // TODO: Import PGN action
                    }) {
                        Label("Import PGN", systemImage: "arrow.up.doc")
                    }

                    Button(action: {
                        // TODO: Export PGN action
                    }) {
                        Label("Export PGN", systemImage: "arrow.down.doc")
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
                    if game.setupFromFEN(fenInput) {
                        fenError = ""
                        dismiss()
                    } else {
                        fenError = "Invalid FEN string"
                        showingFenSetup = true
                    }
                }
                Button("Cancel", role: .cancel) {
                    fenInput = ""
                    fenError = ""
                }
            } message: {
                if fenError.isEmpty {
                    Text("Enter a valid FEN string to set up the board position")
                } else {
                    Text(fenError)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GameMenuView(game: ChessGame())
}
