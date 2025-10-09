//
//  ContentView.swift
//  Claude_Chess
//
//  Created by Jeff Rosengarden on 9/28/25.
//

import SwiftUI

struct ContentView: View {
    // Game state
    @StateObject private var game = ChessGame()

    // Sheet presentation states
    @State private var showingGameMenu = false
    @State private var showingSettings = false
    @State private var showingTimeControls = false
    @State private var showingOpponentSettings = false
    @State private var showingHint = false

    // Opponent settings
    @AppStorage("selectedEngine") private var selectedEngine = "stockfish"
    @AppStorage("stockfishSkillLevel") private var skillLevel = 5

    // Time control settings
    @AppStorage("whiteMinutes") private var whiteMinutes = 30
    @AppStorage("whiteIncrement") private var whiteIncrement = 10
    @AppStorage("blackMinutes") private var blackMinutes = 5
    @AppStorage("blackIncrement") private var blackIncrement = 0

    // Detect device type for adaptive text sizing
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Check if running on larger device (iPad/macOS)
    private var isLargeDevice: Bool {
        #if os(macOS)
        return true
        #else
        return horizontalSizeClass == .regular
        #endif
    }

    /// Dynamic font for player names (White/Black)
    private var playerNameFont: Font {
        isLargeDevice ? .title3 : .subheadline
    }

    /// Dynamic font for captured pieces labels and values
    private var capturedFont: Font {
        isLargeDevice ? .title3 : .caption
    }

    /// Dynamic font for time display
    private var timeFont: Font {
        isLargeDevice ? .title3 : .caption
    }

    /// Dynamic font for game info (Current Player, Opponent)
    private var gameInfoFont: Font {
        isLargeDevice ? .title2 : .headline
    }

    /// Dynamic font for opponent info
    private var opponentFont: Font {
        isLargeDevice ? .title3 : .subheadline
    }

    /// Dynamic size for chess piece icons
    private var pieceIconSize: CGFloat {
        isLargeDevice ? 30 : 20
    }

    var body: some View {
        VStack {
            // Header with title and action buttons
            HStack {
                Text("Claude Chess")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                // Hint button (lightbulb icon)
                Button {
                    showingHint = true
                } label: {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
                .padding(.trailing, 8)

                // Game menu button
                Button {
                    showingGameMenu = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .padding(.trailing, 8)

                // Settings button
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Captured pieces and time display (above board like terminal version)
            VStack(spacing: 4) {
                // White's info line
                HStack(spacing: 12) {
                    Image("Chess_klt45")
                        .resizable()
                        .frame(width: pieceIconSize, height: pieceIconSize)

                    Text("White")
                        .font(playerNameFont)
                        .fontWeight(.semibold)

                    Text("Captured:")
                        .font(capturedFont)
                        .foregroundColor(.secondary)

                    Text(capturedPiecesText(for: .white))
                        .font(capturedFont)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Time control display (if enabled) - tappable to open settings
                    if isTimeControlsEnabled {
                        Button(action: {
                            showingTimeControls = true
                        }) {
                            Text(formatTime(whiteMinutes * 60))
                                .font(timeFont)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Black's info line
                HStack(spacing: 12) {
                    Image("Chess_kdt45")
                        .resizable()
                        .frame(width: pieceIconSize, height: pieceIconSize)

                    Text("Black")
                        .font(playerNameFont)
                        .fontWeight(.semibold)

                    Text("Captured:")
                        .font(capturedFont)
                        .foregroundColor(.secondary)

                    Text(capturedPiecesText(for: .black))
                        .font(capturedFont)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Time control display (if enabled) - tappable to open settings
                    if isTimeControlsEnabled {
                        Button(action: {
                            showingTimeControls = true
                        }) {
                            Text(formatTime(blackMinutes * 60))
                                .font(timeFont)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Chess board with current game state
            ChessBoardView(board: game.board)
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal)
                .padding(.bottom)

            // Game info
            VStack(spacing: 8) {
                Text("Current Player: \(game.currentPlayer.displayName)")
                    .font(gameInfoFont)

                // Opponent info - tappable to open opponent settings
                Button(action: {
                    showingOpponentSettings = true
                }) {
                    Text(opponentInfoText)
                        .font(opponentFont)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top)

            Spacer()
        }
        .sheet(isPresented: $showingGameMenu) {
            GameMenuView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingTimeControls) {
            NavigationView {
                TimeControlsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingTimeControls = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingOpponentSettings) {
            NavigationView {
                // Display the appropriate opponent settings view based on selected engine
                Group {
                    switch selectedEngine {
                    case "stockfish":
                        StockfishSettingsView()
                    case "chesscom":
                        ChessComSettingsView()
                    case "lichess":
                        LichessSettingsView()
                    default:
                        StockfishSettingsView()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingOpponentSettings = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingHint) {
            NavigationView {
                HintView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingHint = false
                            }
                        }
                    }
            }
        }
    }

    /// Computed property for opponent display text
    /// Matches terminal project format: "Opponent: Stockfish (Level 5)"
    private var opponentInfoText: String {
        switch selectedEngine {
        case "stockfish":
            return "Opponent: Stockfish (Level \(skillLevel))"
        case "chesscom":
            return "Opponent: Chess.com"
        case "lichess":
            return "Opponent: Lichess"
        default:
            return "Opponent: Unknown"
        }
    }

    /// Calculate captured pieces text for a given color
    /// Returns list of captured opponent pieces (e.g., "♟♟♞♝")
    /// Matches terminal project's captured pieces calculation logic
    private func capturedPiecesText(for color: Color) -> String {
        // TODO: Implement captured pieces calculation
        // This will count pieces missing from the board for the opponent
        // For now, return placeholder
        return "None"
    }

    /// Check if time controls are enabled
    /// Time controls are disabled when both players have 0 minutes and 0 increment
    private var isTimeControlsEnabled: Bool {
        return !(whiteMinutes == 0 && whiteIncrement == 0 && blackMinutes == 0 && blackIncrement == 0)
    }

    /// Format time in seconds to MM:SS format
    /// Matches terminal project's time display format
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    ContentView()
}
