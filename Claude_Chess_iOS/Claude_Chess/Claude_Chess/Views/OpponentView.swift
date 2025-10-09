//
//  OpponentView.swift
//  Claude_Chess
//
//  Opponent selection view for choosing AI engine
//  Allows user to select between Stockfish (offline), Lichess (online),
//  and Chess.com (online) chess engines for AI opponent
//

import SwiftUI

/// Opponent selection view for choosing AI chess engine
/// - Stockfish: Native offline engine with skill levels 0-20
/// - Lichess: Online API integration (future)
/// - Chess.com: Online API integration (future)
struct OpponentView: View {
    @AppStorage("selectedEngine") private var selectedEngine = "stockfish"

    var body: some View {
        List {
            Section(header: Text("AI Engine Selection")) {
                NavigationLink(destination: StockfishSettingsView()) {
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
            }

            Section(header: Text("About Engines")) {
                VStack(alignment: .leading, spacing: 12) {
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
        OpponentView()
    }
}
