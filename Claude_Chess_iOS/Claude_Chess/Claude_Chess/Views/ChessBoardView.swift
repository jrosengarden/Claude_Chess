//
//  ChessBoardView.swift
//  Claude_Chess
//
//  Chess board visual representation with 8x8 grid
//

import SwiftUI

/// Visual representation of a chess board with alternating light/dark squares
/// and piece placement. Handles touch interaction for move selection and preview.
struct ChessBoardView: View {
    // Chess board dimensions
    private let rows = 8
    private let columns = 8

    // Board state and game reference
    @ObservedObject var game: ChessGame

    // Interaction state
    @State private var selectedSquare: Position?           // Single-tap selection
    @State private var previewSquare: Position?             // Double-tap preview
    @State private var legalMoveSquares: [Position] = []    // Empty squares piece can move to
    @State private var capturablePositions: [Position] = [] // Enemy pieces that can be captured

    // User preferences
    @AppStorage("showPossibleMoves") private var showPossibleMoves: Bool = true

    // Color theme (persisted via AppStorage)
    @AppStorage("boardThemeId") private var boardThemeId = "classic"

    // Custom color storage
    @AppStorage("customLightRed") private var customLightRed: Double = 0.93
    @AppStorage("customLightGreen") private var customLightGreen: Double = 0.85
    @AppStorage("customLightBlue") private var customLightBlue: Double = 0.71
    @AppStorage("customDarkRed") private var customDarkRed: Double = 0.72
    @AppStorage("customDarkGreen") private var customDarkGreen: Double = 0.53
    @AppStorage("customDarkBlue") private var customDarkBlue: Double = 0.30

    private var currentTheme: BoardColorTheme {
        if boardThemeId == "custom" {
            let lightComponents = BoardColorTheme.ColorComponents(
                red: customLightRed, green: customLightGreen, blue: customLightBlue
            )
            let darkComponents = BoardColorTheme.ColorComponents(
                red: customDarkRed, green: customDarkGreen, blue: customDarkBlue
            )
            return BoardColorTheme.theme(withId: boardThemeId,
                                        customLight: lightComponents,
                                        customDark: darkComponents)
        }
        return BoardColorTheme.theme(withId: boardThemeId)
    }

    var body: some View {
        GeometryReader { geometry in
            // Calculate square size to fit the board in available space
            let squareSize = min(geometry.size.width, geometry.size.height) / 8

            VStack(spacing: 0) {
                // Iterate through rows (rank 8 to rank 1)
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        // Iterate through columns (file a to file h)
                        ForEach(0..<columns, id: \.self) { col in
                            let position = Position(row: row, col: col)
                            ChessSquareView(
                                position: position,
                                piece: game.board[row][col],
                                isLight: isLightSquare(row: row, col: col),
                                lightColor: currentTheme.lightSquare.color,
                                darkColor: currentTheme.darkSquare.color,
                                isSelected: selectedSquare == position,
                                isPreviewed: previewSquare == position,
                                isLegalMove: legalMoveSquares.contains(position),
                                isCapturable: capturablePositions.contains(position)
                            )
                            .frame(width: squareSize, height: squareSize)
                            .onTapGesture(count: 2) {
                                handleDoubleTap(at: position)
                            }
                            .onTapGesture(count: 1) {
                                handleSingleTap(at: position)
                            }
                        }
                    }
                }
            }
            .frame(
                width: squareSize * CGFloat(columns),
                height: squareSize * CGFloat(rows)
            )
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
        }
    }

    /// Determine if a square should be light colored based on chess board
    /// pattern
    /// - Parameters:
    ///   - row: Row index (0-7)
    ///   - col: Column index (0-7)
    /// - Returns: true if square is light colored, false if dark
    private func isLightSquare(row: Int, col: Int) -> Bool {
        return (row + col) % 2 == 0
    }

    // MARK: - Gesture Handlers

    /// Handle double-tap on a square (preview mode toggle)
    private func handleDoubleTap(at position: Position) {
        // If single-tap selection is active, ignore double-taps completely
        if selectedSquare != nil {
            return
        }

        let piece = game.getPiece(at: position)

        // Ignore double-tap on empty squares
        guard piece.type != .empty else { return }

        // Toggle preview: if already previewing this piece, clear it
        if previewSquare == position {
            clearPreview()
        } else {
            showPreview(for: position)
        }
    }

    /// Handle single-tap on a square (selection/move)
    private func handleSingleTap(at position: Position) {
        // If preview mode is active, ignore single-taps completely
        if previewSquare != nil {
            return
        }

        let piece = game.getPiece(at: position)

        // If we have a selected piece, try to move it
        if let selected = selectedSquare {
            // Tapping same piece again deselects it
            if selected == position {
                clearSelection()
                return
            }

            // Check if this is a legal move (validate against actual game rules, not just visual arrays)
            if MoveValidator.isValidMove(game: game, from: selected, to: position) {
                // Check if this is a capture for display purposes
                let targetPiece = game.getPiece(at: position)
                let isCapture = targetPiece.type != .empty

                // Execute the move with full game state updates
                let success = game.makeMove(from: selected, to: position)
                if success {
                    let moveNotation = isCapture ? "\(selected.algebraic) x \(position.algebraic)" : "\(selected.algebraic) to \(position.algebraic)"
                    print("Move executed: \(moveNotation)")
                    print("  Halfmove clock: \(game.halfmoveClock), Fullmove: \(game.fullmoveNumber)")
                    print("  White King: \(game.whiteKingPos.algebraic), Black King: \(game.blackKingPos.algebraic)")
                    print("  Current player: \(game.currentPlayer.displayName)")
                    clearSelection()
                    clearPreview()
                } else {
                    print("Move execution failed: \(selected.algebraic) to \(position.algebraic)")
                }
            } else {
                // Invalid move attempted
                // If tapped another piece of same color, switch selection
                if piece.type != .empty && piece.color == game.currentPlayer {
                    selectPiece(at: position)
                } else {
                    // Tapped empty square or opponent piece (illegal move)
                    print("Illegal move: \(selected.algebraic) to \(position.algebraic)")
                    clearSelection()
                }
            }
        } else {
            // No piece selected yet - select this piece if it belongs to current player
            if piece.type != .empty && piece.color == game.currentPlayer {
                selectPiece(at: position)
            }
        }
    }

    /// Show preview for a piece (double-tap mode)
    private func showPreview(for position: Position) {
        previewSquare = position
        updateLegalMoves(for: position)
    }

    /// Select a piece for movement (single-tap mode)
    private func selectPiece(at position: Position) {
        selectedSquare = position

        // Only show moves if setting is enabled
        if showPossibleMoves {
            updateLegalMoves(for: position)
        } else {
            legalMoveSquares = []
            capturablePositions = []
        }
    }

    /// Update legal moves and capturable positions for a piece
    private func updateLegalMoves(for position: Position) {
        let moves = MoveValidator.getPossibleMovesWithCaptures(game: game, from: position)

        legalMoveSquares = moves.filter { !$0.isCapture }.map { $0.destination }
        capturablePositions = moves.filter { $0.isCapture }.map { $0.destination }
    }

    /// Clear preview mode
    private func clearPreview() {
        previewSquare = nil
        legalMoveSquares = []
        capturablePositions = []
    }

    /// Clear selection mode
    private func clearSelection() {
        selectedSquare = nil
        legalMoveSquares = []
        capturablePositions = []
    }
}

/// Individual chess board square with optional piece
struct ChessSquareView: View {
    let position: Position
    let piece: Piece?
    let isLight: Bool
    let lightColor: SwiftUI.Color
    let darkColor: SwiftUI.Color
    let isSelected: Bool
    let isPreviewed: Bool
    let isLegalMove: Bool
    let isCapturable: Bool

    @State private var blinkOpacity: Double = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Square background
                (isLight ? lightColor : darkColor)

                // Legal move indicator (green circle on empty squares)
                if isLegalMove && piece == nil {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .foregroundColor(.green.opacity(0.5))
                        .frame(width: geometry.size.width * 0.2,
                               height: geometry.size.height * 0.2)
                }

                // Piece (if present)
                if let piece = piece {
                    Image(piece.assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(geometry.size.width * 0.1)
                        .opacity(isCapturable ? blinkOpacity : 1.0)
                        .onAppear {
                            if isCapturable {
                                startBlinking()
                            }
                        }
                        .onChange(of: isCapturable) { oldValue, newValue in
                            if newValue {
                                startBlinking()
                            } else {
                                blinkOpacity = 1.0
                            }
                        }
                }

                // Dual-layer border for selected/previewed pieces
                if isSelected {
                    RoundedRectangle(cornerRadius: 0)
                        .strokeBorder(SwiftUI.Color.white, lineWidth: 6)
                    RoundedRectangle(cornerRadius: 0)
                        .strokeBorder(SwiftUI.Color.blue, lineWidth: 3)
                        .padding(3)
                } else if isPreviewed {
                    RoundedRectangle(cornerRadius: 0)
                        .strokeBorder(SwiftUI.Color.white, lineWidth: 6)
                    RoundedRectangle(cornerRadius: 0)
                        .strokeBorder(SwiftUI.Color.yellow, lineWidth: 3)
                        .padding(3)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Start blinking animation for capturable pieces
    private func startBlinking() {
        withAnimation(
            Animation.easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
        ) {
            blinkOpacity = 0.3
        }
    }
}

// MARK: - Preview

#Preview {
    ChessBoardView(game: ChessGame())
        .frame(width: 400, height: 400)
}
