//
//  OpponentView.swift
//  Claude_Chess
//
//  Opponent selection view for choosing AI engine
//  Allows user to select between Stockfish (offline), Lichess (online),
//  and Chess.com (online) chess engines for AI opponent
//

import SwiftUI

/// Opponent selection view for choosing game mode
/// - Human: Two humans playing on same device (pass and play)
/// - Stockfish: Native offline AI engine with skill levels 0-20
/// - Lichess: Online API integration (future)
/// - Chess.com: Online API integration (future)
struct OpponentView: View {
    @AppStorage("selectedEngine") private var selectedEngine = "human"
    @ObservedObject var game: ChessGame

    /// Check if opponent selection is locked (game has started)
    private var isOpponentLockEnabled: Bool {
        return game.gameInProgress || !game.moveHistory.isEmpty
    }

    var body: some View {
        List {
            Section(header: Text("Opponent Selection")) {
                // Lock warning if game has started
                if isOpponentLockEnabled {
                    Text("Opponent cannot be changed after game has started. Start a New Game to change opponent.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.vertical, 4)
                }

                // Human vs Human option
                Button(action: {
                    if !isOpponentLockEnabled {
                        selectedEngine = "human"
                    }
                }) {
                    HStack {
                        Label("Human", systemImage: "person.2.fill")
                            .foregroundColor(.accentColor)
                        Spacer()
                        if selectedEngine == "human" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isOpponentLockEnabled)
                .opacity(isOpponentLockEnabled ? 0.5 : 1.0)
            }

            Section(header: Text("AI Engine Selection")) {
                NavigationLink(destination: StockfishSettingsView(game: game)) {
                    HStack {
                        Label("Stockfish", systemImage: "desktopcomputer")
                            .foregroundColor(.accentColor)
                        Spacer()
                        if selectedEngine == "stockfish" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .disabled(isOpponentLockEnabled)
                .opacity(isOpponentLockEnabled ? 0.5 : 1.0)

                NavigationLink(destination: ChessComSettingsView()) {
                    HStack {
                        Label("Chess.com", systemImage: "network")
                            .foregroundColor(.accentColor)
                        Spacer()
                        if selectedEngine == "chesscom" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .disabled(isOpponentLockEnabled)
                .opacity(isOpponentLockEnabled ? 0.5 : 1.0)

                NavigationLink(destination: LichessSettingsView()) {
                    HStack {
                        Label("Lichess", systemImage: "globe")
                            .foregroundColor(.accentColor)
                        Spacer()
                        if selectedEngine == "lichess" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .disabled(isOpponentLockEnabled)
                .opacity(isOpponentLockEnabled ? 0.5 : 1.0)
            }

            Section(header: Text("About Opponents")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Human")
                        .font(.headline)
                    Text("Two players on same device (pass and play). Use Flip Board to rotate the board between turns.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Stockfish")
                        .font(.headline)
                    Text("Offline chess engine with adjustable skill levels (0-20). No internet connection required.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Chess.com")
                        .font(.headline)
                    Text("Online chess platform integration. Requires internet connection. (Coming soon)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Lichess")
                        .font(.headline)
                    Text("Free and open-source chess platform integration. Requires internet connection. (Coming soon)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Opponent")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        OpponentView(game: ChessGame())
    }
}
