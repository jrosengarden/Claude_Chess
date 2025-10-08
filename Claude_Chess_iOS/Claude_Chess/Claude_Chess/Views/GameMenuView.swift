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

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Game")) {
                    Button(action: {
                        // TODO: New game action
                    }) {
                        Label("New Game", systemImage: "plus.circle")
                    }

                    Button(action: {
                        // TODO: Save game action
                    }) {
                        Label("Save Game", systemImage: "square.and.arrow.down")
                    }

                    Button(action: {
                        // TODO: Load game action
                    }) {
                        Label("Load Game", systemImage: "square.and.arrow.up")
                    }
                }

                Section(header: Text("Game Controls")) {
                    Button(action: {
                        // TODO: Time controls action
                    }) {
                        Label("Time Controls", systemImage: "clock")
                    }

                    Button(action: {
                        // TODO: Undo move action
                    }) {
                        Label("Undo Move", systemImage: "arrow.uturn.backward")
                    }

                    Button(action: {
                        // TODO: Hint action
                    }) {
                        Label("Hint", systemImage: "lightbulb")
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
                        Label("Import PGN", systemImage: "doc.badge.arrow.up")
                    }

                    Button(action: {
                        // TODO: Export PGN action
                    }) {
                        Label("Export PGN", systemImage: "doc.badge.arrow.up")
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
        }
    }
}

// MARK: - Preview

#Preview {
    GameMenuView()
}
