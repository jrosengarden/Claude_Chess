//
//  ContentView.swift
//  Claude_Chess
//
//  Created by Jeff Rosengarden on 9/28/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    // Game state
    @StateObject private var game = ChessGame()

    // Sheet presentation states
    @State private var showingQuickGame = false
    @State private var showingGameMenu = false
    @State private var showingSettings = false
    @State private var showingTimeControls = false
    @State private var showingOpponentSettings = false
    @State private var showingWhiteCaptured = false
    @State private var showingBlackCaptured = false

    // Timer for countdown updates
    @State private var timerCancellable: AnyCancellable?

    // Track if time forfeit alert is showing
    @State private var showingTimeForfeitAlert = false
    @State private var timeForfeitWinner: Color?

    // Hint system state
    @State private var showingHintAlert = false
    @State private var isRequestingHint = false

    // Opponent settings
    @AppStorage("selectedEngine") private var selectedEngine = "human"
    @AppStorage("stockfishSkillLevel") private var skillLevel = 5

    // Time control settings
    @AppStorage("whiteMinutes") private var whiteMinutes = 30
    @AppStorage("whiteIncrement") private var whiteIncrement = 10
    @AppStorage("blackMinutes") private var blackMinutes = 5
    @AppStorage("blackIncrement") private var blackIncrement = 0

    // Haptic feedback
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    #if os(iOS)
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    #endif

    // Board theme for dynamic button colors
    @AppStorage("boardThemeId") private var boardThemeId = "classic"
    @AppStorage("customLightRed") private var customLightRed = 0.93
    @AppStorage("customLightGreen") private var customLightGreen = 0.87
    @AppStorage("customLightBlue") private var customLightBlue = 0.73
    @AppStorage("customDarkRed") private var customDarkRed = 0.72
    @AppStorage("customDarkGreen") private var customDarkGreen = 0.53
    @AppStorage("customDarkBlue") private var customDarkBlue = 0.31

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

    /// Dynamic font for header action buttons (Quick Game, Menu, Settings)
    private var headerButtonFont: Font {
        isLargeDevice ? .system(size: 32) : .title2
    }

    /// Dynamic font for app title
    private var titleFont: Font {
        isLargeDevice ? .largeTitle : .title2
    }

    /// Get the dark square color from current board theme
    private var boardDarkColor: SwiftUI.Color {
        let customLight = BoardColorTheme.ColorComponents(red: customLightRed, green: customLightGreen, blue: customLightBlue)
        let customDark = BoardColorTheme.ColorComponents(red: customDarkRed, green: customDarkGreen, blue: customDarkBlue)
        let theme = BoardColorTheme.theme(withId: boardThemeId, customLight: customLight, customDark: customDark)
        return SwiftUI.Color(red: theme.darkSquare.red, green: theme.darkSquare.green, blue: theme.darkSquare.blue)
    }

    /// Compute a darker, more visible version of the dark square color for text labels
    /// Matches ChessBoardView coordinate label color for UI consistency
    private var coordinateLabelColor: SwiftUI.Color {
        let darkColor = boardDarkColor

        // Extract color components and darken them by 40% for better visibility
        #if os(iOS)
        let uiColor = UIColor(darkColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Darken by multiplying by 0.6 (making it 40% darker)
        return SwiftUI.Color(red: red * 0.6, green: green * 0.6, blue: blue * 0.6)
        #else
        let nsColor = NSColor(darkColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return SwiftUI.Color(red: red * 0.6, green: green * 0.6, blue: blue * 0.6)
        #endif
    }

    var body: some View {
        VStack {
            // Header with title and action buttons
            HStack {
                Text("Claude Chess")
                    .font(titleFont)
                    .fontWeight(.bold)
                    .foregroundColor(coordinateLabelColor)

                Spacer()

                // Scrollable action buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Undo button (always visible, disabled when no moves to undo)
                        Button {
                            #if os(iOS)
                            if hapticFeedbackEnabled {
                                lightHaptic.impactOccurred()
                            }
                            #endif
                            game.undoLastMove()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(headerButtonFont)
                                .foregroundColor(boardDarkColor)
                        }
                        .disabled(game.moveHistory.isEmpty)
                        .opacity(game.moveHistory.isEmpty ? 0.3 : 1.0)

                        // Hint button (lightbulb icon - disabled until game starts and engine available)
                        Button {
                            #if os(iOS)
                            if hapticFeedbackEnabled {
                                lightHaptic.impactOccurred()
                            }
                            #endif
                            requestHintAndShowAlert()
                        } label: {
                            Image(systemName: isRequestingHint ? "hourglass" : "lightbulb.fill")
                                .font(headerButtonFont)
                                .foregroundColor(.yellow)
                        }
                        .disabled(isRequestingHint || !game.gameInProgress || game.engine == nil)
                        .opacity((isRequestingHint || !game.gameInProgress || game.engine == nil) ? 0.3 : 1.0)

                        // Quick Game button (lightning bolt icon)
                        Button {
                            #if os(iOS)
                            if hapticFeedbackEnabled {
                                lightHaptic.impactOccurred()
                            }
                            #endif
                            showingQuickGame = true
                        } label: {
                            Image(systemName: "bolt.fill")
                                .font(headerButtonFont)
                                .foregroundColor(boardDarkColor)
                        }

                        // Game menu button (hamburger)
                        Button {
                            #if os(iOS)
                            if hapticFeedbackEnabled {
                                lightHaptic.impactOccurred()
                            }
                            #endif
                            showingGameMenu = true
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(headerButtonFont)
                                .foregroundColor(.primary)
                        }
                    }
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
                        .foregroundColor(coordinateLabelColor)
                        .frame(width: isLargeDevice ? 70 : 60, alignment: .leading)

                    // Captured pieces count - tappable to show details
                    Button(action: {
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            lightHaptic.impactOccurred()
                        }
                        #endif
                        showingWhiteCaptured = true
                    }) {
                        Text("Captured: \(game.capturedByWhite.count)")
                            .font(capturedFont)
                            .foregroundColor(coordinateLabelColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(coordinateLabelColor.opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(coordinateLabelColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Time control display (if enabled) - tappable to open settings
                    if isTimeControlsEnabled {
                        Button(action: {
                            #if os(iOS)
                            if hapticFeedbackEnabled {
                                lightHaptic.impactOccurred()
                            }
                            #endif
                            showingTimeControls = true
                        }) {
                            Text(formatTime(game.getCurrentTime(for: .white)))
                                .font(timeFont)
                                .fontWeight(.semibold)
                                .foregroundColor(coordinateLabelColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(coordinateLabelColor.opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(coordinateLabelColor.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
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
                        .foregroundColor(coordinateLabelColor)
                        .frame(width: isLargeDevice ? 70 : 60, alignment: .leading)

                    // Captured pieces count - tappable to show details
                    Button(action: {
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            lightHaptic.impactOccurred()
                        }
                        #endif
                        showingBlackCaptured = true
                    }) {
                        Text("Captured: \(game.capturedByBlack.count)")
                            .font(capturedFont)
                            .foregroundColor(coordinateLabelColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(coordinateLabelColor.opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(coordinateLabelColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Time control display (if enabled) - tappable to open settings
                    if isTimeControlsEnabled {
                        Button(action: {
                            #if os(iOS)
                            if hapticFeedbackEnabled {
                                lightHaptic.impactOccurred()
                            }
                            #endif
                            showingTimeControls = true
                        }) {
                            Text(formatTime(game.getCurrentTime(for: .black)))
                                .font(timeFont)
                                .fontWeight(.semibold)
                                .foregroundColor(coordinateLabelColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(coordinateLabelColor.opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(coordinateLabelColor.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Chess board with current game state
            ChessBoardView(game: game)
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal)
                .padding(.bottom)

            // Game info
            VStack(spacing: 8) {
                Text("Current Player: \(game.currentPlayer.displayName)")
                    .font(gameInfoFont)
                    .foregroundColor(coordinateLabelColor)

                // Opponent info - tappable to open opponent settings
                Button(action: {
                    #if os(iOS)
                    if hapticFeedbackEnabled {
                        lightHaptic.impactOccurred()
                    }
                    #endif
                    showingOpponentSettings = true
                }) {
                    Text(opponentInfoText)
                        .font(opponentFont)
                        .foregroundColor(coordinateLabelColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(coordinateLabelColor.opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(coordinateLabelColor.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top)

            Spacer()
        }
        .overlay {
            // Captured pieces overlay (positioned at top, covering White/Black info lines)
            if showingWhiteCaptured || showingBlackCaptured {
                VStack {
                    CapturedPiecesOverlay(
                        player: showingWhiteCaptured ? .white : .black,
                        capturedPieces: showingWhiteCaptured ?
                            capturedPiecesArray(for: .white) :
                            capturedPiecesArray(for: .black),
                        isPresented: showingWhiteCaptured ? $showingWhiteCaptured : $showingBlackCaptured
                    )
                    .padding(.top, 8)

                    Spacer()
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
        .sheet(isPresented: $showingQuickGame) {
            QuickGameMenuView(game: game)
        }
        .sheet(isPresented: $showingGameMenu) {
            GameMenuView(game: game)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingTimeControls) {
            NavigationView {
                TimeControlsView(game: game)
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
                    case "human":
                        OpponentView(game: game)
                    case "stockfish":
                        StockfishSettingsView(game: game)
                    case "chesscom":
                        ChessComSettingsView()
                    case "lichess":
                        LichessSettingsView()
                    default:
                        OpponentView(game: game)
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
        .onAppear {
            // Initialize time controls from settings on app start
            initializeTimeControls()

            // Timer doesn't start automatically - user must tap "Start Game" in Quick Menu

            // Start timer publisher for live countdown display
            timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    // Update timer every second
                    game.updateTimer()

                    // Check for time forfeit (only if game hasn't ended and alert not already showing)
                    if !game.gameHasEnded && !showingTimeForfeitAlert && game.checkTimeForfeit() {
                        // Mark game as ended
                        game.gameHasEnded = true

                        // Determine winner (opposite of current player who ran out of time)
                        let winner = game.currentPlayer == .white ? Color.black : Color.white
                        timeForfeitWinner = winner

                        // Store winner in game for PGN generation
                        game.timeForfeitWinner = winner == .white ? "White" : "Black"

                        showingTimeForfeitAlert = true
                    }
                }
        }
        .onChange(of: game.resetTrigger) { oldValue, newValue in
            // Re-initialize time controls whenever game is reset
            initializeTimeControls()
        }
        .onChange(of: whiteMinutes) { oldValue, newValue in
            // Re-initialize time controls when settings change
            initializeTimeControls()
        }
        .onChange(of: whiteIncrement) { oldValue, newValue in
            // Re-initialize time controls when settings change
            initializeTimeControls()
        }
        .onChange(of: blackMinutes) { oldValue, newValue in
            // Re-initialize time controls when settings change
            initializeTimeControls()
        }
        .onChange(of: blackIncrement) { oldValue, newValue in
            // Re-initialize time controls when settings change
            initializeTimeControls()
        }
        // Custom time forfeit alert with chess piece icon
        .overlay {
            if showingTimeForfeitAlert, let winner = timeForfeitWinner {
                TimeForfeitAlertView(
                    winner: winner,
                    isPresented: $showingTimeForfeitAlert,
                    onNewGame: {
                        Task {
                            await game.resetGame(selectedEngine: selectedEngine, skillLevel: skillLevel)
                        }
                    }
                )
            }
        }
        .alert(hintAlertTitle(), isPresented: $showingHintAlert) {
            Button("OK") {
                showingHintAlert = false
            }
        } message: {
            Text(hintAlertMessage())
        }
    }

    /// Computed property for opponent display text
    /// Displays current game mode (Human vs Human or AI opponent)
    private var opponentInfoText: String {
        switch selectedEngine {
        case "human":
            return "Mode: Human vs Human"
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

    /// Calculate captured pieces array for a given color
    /// Returns list of captured opponent pieces as Piece objects for display
    /// Matches terminal project's captured pieces calculation logic
    private func capturedPiecesArray(for color: Color) -> [Piece] {
        // Get captured pieces from game's move history
        let capturedPieces = (color == .white) ? game.capturedByWhite : game.capturedByBlack

        // Sort pieces by value for consistent display (Queen, Rook, Bishop, Knight, Pawn)
        return capturedPieces.sorted { piece1, piece2 in
            let order: [PieceType] = [.queen, .rook, .bishop, .knight, .pawn]
            let index1 = order.firstIndex(of: piece1.type) ?? 99
            let index2 = order.firstIndex(of: piece2.type) ?? 99
            return index1 < index2
        }
    }

    /// Check if time controls are enabled and should be displayed
    /// Time controls are disabled when:
    /// - Both players have 0 minutes and 0 increment (disabled in settings)
    /// - OR user has used Undo which disables them for remainder of game
    private var isTimeControlsEnabled: Bool {
        let settingsEnabled = !(whiteMinutes == 0 && whiteIncrement == 0 && blackMinutes == 0 && blackIncrement == 0)
        return settingsEnabled && game.timeControlsEnabled && !game.timeControlsDisabledByUndo
    }

    /// Format time in seconds to MM:SS format
    /// Matches terminal project's time display format
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    /// Initialize time controls from current settings
    private func initializeTimeControls() {
        game.initializeTimeControls(
            whiteMinutes: whiteMinutes,
            whiteIncrement: whiteIncrement,
            blackMinutes: blackMinutes,
            blackIncrement: blackIncrement
        )
    }

    // MARK: - Hint System

    /// Request hint from AI and show alert with result
    /// Note: Button is disabled when game not in progress or engine unavailable
    private func requestHintAndShowAlert() {
        // Request hint (button is disabled if preconditions not met)
        isRequestingHint = true
        Task {
            await game.requestHint()
            await MainActor.run {
                isRequestingHint = false
                showingHintAlert = true
            }
        }
    }

    /// Title for hint alert
    private func hintAlertTitle() -> String {
        return game.currentHint != nil ? "💡 Move Hint" : "Hint"
    }

    /// Message for hint alert
    private func hintAlertMessage() -> String {
        if let hint = game.currentHint {
            return formatHintForAlert(hint)
        }
        return "No hint available."
    }

    /// Format UCI move notation for alert display
    /// - Parameter uciMove: UCI move string (e.g., "e2e4", "e7e8q")
    /// - Returns: Human-readable move notation
    private func formatHintForAlert(_ uciMove: String) -> String {
        guard uciMove.count >= 4 else { return uciMove }

        let from = String(uciMove.prefix(2)).uppercased()
        let to = String(uciMove.dropFirst(2).prefix(2)).uppercased()

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
            return "\(from) → \(to) (promote to \(pieceName))\n\nMove your piece from \(from) to \(to) and select \(pieceName) for promotion."
        }

        return "\(from) → \(to)\n\nMove your piece from \(from) to \(to)."
    }
}

#Preview {
    ContentView()
}
