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
    // MARK: - Haptic Feedback Generators

    #if os(iOS)
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let warningHaptic = UINotificationFeedbackGenerator()
    #endif
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

    // Drag state
    @State private var draggedPiece: Position?              // Position of piece being dragged
    @State private var dragOffset: CGSize = .zero           // Current drag offset from original position

    // User preferences
    @AppStorage("showPossibleMoves") private var showPossibleMoves: Bool = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true

    // Opponent settings for engine initialization
    @AppStorage("selectedEngine") private var selectedEngine = "human"
    @AppStorage("stockfishSkillLevel") private var skillLevel = 5

    // Game-ending alerts
    @State private var showingCheckmate = false
    @State private var showingStalemate = false
    @State private var showingFiftyMoveDraw = false
    @State private var winnerColor: Color?

    // Check indicator
    @State private var showingCheckAlert = false
    @State private var kingInCheckPosition: Position?

    // Pawn promotion
    @State private var showingPromotionPicker = false
    @State private var promotionFrom: Position?
    @State private var promotionTo: Position?
    @State private var promotionColor: Color?

    // Board orientation (persisted via AppStorage)
    @AppStorage("boardFlipped") private var boardFlipped: Bool = false

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

            ZStack {
                // Chess board
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
                                    isCapturable: capturablePositions.contains(position),
                                    isDragging: draggedPiece == position,
                                    isKingInCheck: kingInCheckPosition == position
                                )
                                .frame(width: squareSize, height: squareSize)
                                .onTapGesture(count: 2) {
                                    handleDoubleTap(at: position)
                                }
                                .onTapGesture(count: 1) {
                                    handleSingleTap(at: position)
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            handleDragChanged(at: position, translation: value.translation, squareSize: squareSize)
                                        }
                                        .onEnded { value in
                                            handleDragEnded(at: position, translation: value.translation, squareSize: squareSize, geometry: geometry)
                                        }
                                )
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

                // Dragged piece overlay
                if let draggedPos = draggedPiece {
                    let piece = game.getPiece(at: draggedPos)
                    if piece.type != .empty {
                        // Calculate the actual screen position of the dragged piece
                        let boardSize = squareSize * 8
                        let boardOriginX = (geometry.size.width - boardSize) / 2
                        let boardOriginY = (geometry.size.height - boardSize) / 2
                        let pieceStartX = boardOriginX + CGFloat(draggedPos.col) * squareSize + squareSize / 2
                        let pieceStartY = boardOriginY + CGFloat(draggedPos.row) * squareSize + squareSize / 2

                        // Offset the ghost piece so it's visible (up and to the right of finger)
                        let visualOffset = squareSize * 0.6

                        Image(piece.assetName)
                            .resizable()
                            .frame(width: squareSize * 0.9, height: squareSize * 0.9)
                            .rotationEffect(.degrees(boardFlipped ? 180 : 0))
                            .position(
                                x: pieceStartX + dragOffset.width + visualOffset,
                                y: pieceStartY + dragOffset.height - visualOffset
                            )
                            .shadow(radius: 10)
                            .allowsHitTesting(false)
                    }
                }
            }
            .rotationEffect(.degrees(boardFlipped ? 180 : 0))
        }
        .onAppear {
            // Check game state when view first appears (handles FEN setup scenarios)
            checkGameEnd()
        }
        .onChange(of: game.currentPlayer) { oldValue, newValue in
            // Also check game state whenever the current player changes (handles FEN setup)
            checkGameEnd()
        }
        .onChange(of: game.resetTrigger) { oldValue, newValue in
            // Clear UI state when New Game is created
            resetBoardState()
        }
        .alert("Checkmate!", isPresented: $showingCheckmate) {
            Button("New Game") {
                Task {
                    await game.resetGame(selectedEngine: selectedEngine, skillLevel: skillLevel)
                    resetBoardState()
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            if let winner = winnerColor {
                Text("\(winner.displayName) wins!")
            }
        }
        .alert("Stalemate!", isPresented: $showingStalemate) {
            Button("New Game") {
                Task {
                    await game.resetGame(selectedEngine: selectedEngine, skillLevel: skillLevel)
                    resetBoardState()
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("The game is a draw.")
        }
        .alert("50-Move Rule Draw!", isPresented: $showingFiftyMoveDraw) {
            Button("New Game") {
                Task {
                    await game.resetGame(selectedEngine: selectedEngine, skillLevel: skillLevel)
                    resetBoardState()
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("The game is a draw. 50 moves have been made without a pawn move or capture.")
        }
        .alert("Check!", isPresented: $showingCheckAlert) {
            Button("OK", role: .cancel) {
                // Keep king highlighted for visual feedback
            }
        } message: {
            Text("\(game.currentPlayer.displayName) is in check!")
        }
        .overlay {
            if showingPromotionPicker,
               let from = promotionFrom,
               let to = promotionTo,
               let color = promotionColor {
                ZStack {
                    // Semi-transparent background
                    SwiftUI.Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // Prevent dismissing by tapping background
                            // User must make a choice
                        }

                    // Promotion picker dialog
                    PromotionPiecePickerView(color: color) { selectedPiece in
                        handlePromotionSelection(from: from, to: to, piece: selectedPiece)
                    }
                }
            }
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

    /// Handle drag gesture started/changed
    private func handleDragChanged(at position: Position, translation: CGSize, squareSize: CGFloat) {
        // Prevent any moves until "Start Game" is tapped
        guard game.gameInProgress else {
            return
        }

        let piece = game.getPiece(at: position)

        // Only allow dragging current player's pieces
        guard piece.type != .empty && piece.color == game.currentPlayer else {
            return
        }

        // If this is the first drag movement, start the drag
        if draggedPiece == nil {
            draggedPiece = position

            // Light haptic feedback when starting drag
            #if os(iOS)
            if hapticFeedbackEnabled {
                lightHaptic.impactOccurred()
            }
            #endif

            // Show legal moves if enabled
            if showPossibleMoves {
                updateLegalMoves(for: position)
            }
        }

        // Update drag offset if we're dragging this piece
        if draggedPiece == position {
            dragOffset = translation
        }
    }

    /// Handle drag gesture ended
    private func handleDragEnded(at position: Position, translation: CGSize, squareSize: CGFloat, geometry: GeometryProxy) {
        guard draggedPiece == position else { return }

        // Calculate which square the piece was dropped on
        let boardSize = squareSize * 8
        let boardOriginX = (geometry.size.width - boardSize) / 2
        let boardOriginY = (geometry.size.height - boardSize) / 2

        // Calculate starting position of dragged piece
        let startX = boardOriginX + CGFloat(position.col) * squareSize + squareSize / 2
        let startY = boardOriginY + CGFloat(position.row) * squareSize + squareSize / 2

        // Calculate drop position
        let dropX = startX + translation.width
        let dropY = startY + translation.height

        // Convert to board coordinates
        let dropCol = Int((dropX - boardOriginX) / squareSize)
        let dropRow = Int((dropY - boardOriginY) / squareSize)

        // Check if dropped on valid square
        if dropRow >= 0 && dropRow < 8 && dropCol >= 0 && dropCol < 8 {
            let dropPosition = Position(row: dropRow, col: dropCol)

            // Attempt to execute the move
            if MoveValidator.isValidMove(game: game, from: position, to: dropPosition) {
                // Check if this is a promotion move
                if game.isPromotionMove(from: position, to: dropPosition) {
                    // Show promotion picker instead of executing move immediately
                    let movingPiece = game.getPiece(at: position)
                    promotionFrom = position
                    promotionTo = dropPosition
                    promotionColor = movingPiece.color
                    showingPromotionPicker = true
                } else {
                    // Regular move execution
                    let targetPiece = game.getPiece(at: dropPosition)
                    let isCapture = targetPiece.type != .empty

                    let success = game.makeMove(from: position, to: dropPosition)
                    if success {
                        // Heavy haptic feedback for successful move
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            heavyHaptic.impactOccurred()
                        }
                        #endif

                        let moveNotation = isCapture ? "\(position.algebraic) x \(dropPosition.algebraic)" : "\(position.algebraic) to \(dropPosition.algebraic)"
                        print("Move executed (drag): \(moveNotation)")

                        // Check for game-ending conditions
                        checkGameEnd()

                        // Trigger AI move if playing against AI (terminal project parity)
                        triggerAIMove()
                    }
                }
            } else {
                // Invalid move - warning notification haptic
                #if os(iOS)
                if hapticFeedbackEnabled {
                    warningHaptic.notificationOccurred(.warning)
                }
                #endif
                print("Invalid drag move: \(position.algebraic) to \(dropPosition.algebraic)")
            }
        }

        // Reset drag state
        draggedPiece = nil
        dragOffset = .zero
        legalMoveSquares = []
        capturablePositions = []
    }

    /// Handle double-tap on a square (preview mode toggle)
    private func handleDoubleTap(at position: Position) {
        // If single-tap selection is active, ignore double-taps completely
        if selectedSquare != nil {
            return
        }

        let piece = game.getPiece(at: position)

        // Ignore double-tap on empty squares
        guard piece.type != .empty else { return }

        // Medium haptic feedback for double-tap preview
        #if os(iOS)
        if hapticFeedbackEnabled {
            mediumHaptic.impactOccurred()
        }
        #endif

        // Toggle preview: if already previewing this piece, clear it
        if previewSquare == position {
            clearPreview()
        } else {
            showPreview(for: position)
        }
    }

    /// Handle single-tap on a square (selection/move)
    private func handleSingleTap(at position: Position) {
        // Prevent any moves until "Start Game" is tapped
        guard game.gameInProgress else {
            return
        }

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
                // Check if this is a promotion move
                if game.isPromotionMove(from: selected, to: position) {
                    // Show promotion picker instead of executing move immediately
                    let movingPiece = game.getPiece(at: selected)
                    promotionFrom = selected
                    promotionTo = position
                    promotionColor = movingPiece.color
                    showingPromotionPicker = true
                    clearSelection()
                    clearPreview()
                } else {
                    // Regular move execution
                    // Check if this is a capture for display purposes
                    let targetPiece = game.getPiece(at: position)
                    let isCapture = targetPiece.type != .empty

                    // Execute the move with full game state updates
                    let success = game.makeMove(from: selected, to: position)
                    if success {
                        // Heavy haptic feedback for successful move
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            heavyHaptic.impactOccurred()
                        }
                        #endif

                        let moveNotation = isCapture ? "\(selected.algebraic) x \(position.algebraic)" : "\(selected.algebraic) to \(position.algebraic)"
                        print("Move executed: \(moveNotation)")
                        print("  Halfmove clock: \(game.halfmoveClock), Fullmove: \(game.fullmoveNumber)")
                        print("  White King: \(game.whiteKingPos.algebraic), Black King: \(game.blackKingPos.algebraic)")
                        print("  Current player: \(game.currentPlayer.displayName)")
                        clearSelection()
                        clearPreview()

                        // Check for game-ending conditions
                        checkGameEnd()

                        // Trigger AI move if playing against AI (terminal project parity)
                        triggerAIMove()
                    } else {
                        print("Move execution failed: \(selected.algebraic) to \(position.algebraic)")
                    }
                }
            } else {
                // Invalid move attempted
                // If tapped another piece of same color, switch selection
                if piece.type != .empty && piece.color == game.currentPlayer {
                    selectPiece(at: position)
                } else {
                    // Tapped empty square or opponent piece (illegal move)
                    // Warning notification haptic for invalid move
                    #if os(iOS)
                    if hapticFeedbackEnabled {
                        warningHaptic.notificationOccurred(.warning)
                    }
                    #endif

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
        // Light haptic feedback for piece selection
        #if os(iOS)
        if hapticFeedbackEnabled {
            lightHaptic.impactOccurred()
        }
        #endif

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
    /// Only shows moves that are truly legal (don't leave king in check)
    private func updateLegalMoves(for position: Position) {
        let pseudoLegalMoves = MoveValidator.getPossibleMovesWithCaptures(game: game, from: position)

        // Filter to only show moves that are actually legal (don't leave king in check)
        let legalMoves = pseudoLegalMoves.filter { moveInfo in
            MoveValidator.isValidMove(game: game, from: position, to: moveInfo.destination)
        }

        legalMoveSquares = legalMoves.filter { !$0.isCapture }.map { $0.destination }
        capturablePositions = legalMoves.filter { $0.isCapture }.map { $0.destination }
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

    /// Reset all board UI state (called when starting new game)
    private func resetBoardState() {
        selectedSquare = nil
        previewSquare = nil
        legalMoveSquares = []
        capturablePositions = []
        draggedPiece = nil
        dragOffset = .zero
        kingInCheckPosition = nil
        winnerColor = nil
    }

    // MARK: - Pawn Promotion Handler

    /// Handle promotion piece selection
    /// Ported from terminal project chess.c:make_promotion_move()
    private func handlePromotionSelection(from: Position, to: Position, piece: PieceType) {
        // Execute the promotion move
        let success = game.makePromotionMove(from: from, to: to, promotionPiece: piece)

        if success {
            // Heavy haptic feedback for promotion
            #if os(iOS)
            if hapticFeedbackEnabled {
                heavyHaptic.impactOccurred()
            }
            #endif

            print("Promotion executed: \(from.algebraic) to \(to.algebraic), promoted to \(piece.displayName)")

            // Check for game-ending conditions
            checkGameEnd()

            // Trigger AI move if playing against AI (terminal project parity)
            triggerAIMove()
        } else {
            print("Promotion execution failed")
        }

        // Dismiss promotion picker
        showingPromotionPicker = false
        promotionFrom = nil
        promotionTo = nil
        promotionColor = nil
    }

    /// Trigger AI move response after human move
    /// Ported from terminal project's AI move automation logic
    private func triggerAIMove() {
        // Debug output
        print("DEBUG: triggerAIMove() called")
        print("  game.selectedEngine = \(game.selectedEngine)")
        print("  game.isAIOpponent = \(game.isAIOpponent)")
        print("  game.engine = \(game.engine != nil ? "initialized" : "nil")")

        // Only trigger if playing against AI engine
        guard game.isAIOpponent else {
            print("  SKIP: Not AI opponent")
            return
        }

        // Only trigger if game is still in progress (not checkmate/stalemate)
        guard !GameStateChecker.isCheckmate(game: game, color: game.currentPlayer) &&
              !GameStateChecker.isStalemate(game: game, color: game.currentPlayer) &&
              !game.isFiftyMoveRuleDraw() else {
            print("  SKIP: Game ended")
            return
        }

        // Request and execute AI move asynchronously
        Task {
            do {
                // Get AI move from engine
                guard let uciMove = try await game.getAIMove() else {
                    print("ERROR: AI engine returned no move")
                    return
                }

                print("AI selected move: \(uciMove)")

                // Execute the AI move
                let success = await game.executeAIMove(uciMove)

                if success {
                    print("AI move executed successfully")

                    // Check for game-ending conditions after AI move
                    await MainActor.run {
                        checkGameEnd()
                    }
                } else {
                    print("ERROR: Failed to execute AI move: \(uciMove)")
                }
            } catch {
                print("ERROR: AI move request failed: \(error)")
            }
        }
    }

    /// Check for game-ending conditions (checkmate, stalemate, 50-move rule, check) after a move
    private func checkGameEnd() {
        // Check for 50-move rule draw (highest priority - automatic draw)
        if game.isFiftyMoveRuleDraw() {
            kingInCheckPosition = nil  // Clear check indicator
            showingFiftyMoveDraw = true
            return
        }

        // Check if current player is in checkmate
        if GameStateChecker.isCheckmate(game: game, color: game.currentPlayer) {
            winnerColor = game.currentPlayer.opposite
            kingInCheckPosition = nil  // Clear check indicator
            showingCheckmate = true
            return
        }

        // Check if current player is in stalemate
        if GameStateChecker.isStalemate(game: game, color: game.currentPlayer) {
            kingInCheckPosition = nil  // Clear check indicator
            showingStalemate = true
            return
        }

        // Check if current player is in check
        if GameStateChecker.isInCheck(game: game, color: game.currentPlayer) {
            // Set king position for visual indicator (red border)
            kingInCheckPosition = game.currentPlayer == .white ? game.whiteKingPos : game.blackKingPos
            showingCheckAlert = true
        } else {
            // Clear check indicator if not in check
            kingInCheckPosition = nil
        }
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
    let isDragging: Bool
    let isKingInCheck: Bool

    @State private var blinkOpacity: Double = 1.0
    @AppStorage("boardFlipped") private var boardFlipped: Bool = false

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

                // Piece (if present) - hide if being dragged
                if let piece = piece, !isDragging {
                    Image(piece.assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(geometry.size.width * 0.1)
                        .rotationEffect(.degrees(boardFlipped ? 180 : 0))
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

                // Dual-layer border for selected/previewed/check pieces
                // Priority: Check indicator (red) > Selected (blue) > Previewed (yellow)
                if isKingInCheck {
                    // Red border for king in check (highest priority - always shows)
                    RoundedRectangle(cornerRadius: 0)
                        .strokeBorder(SwiftUI.Color.white, lineWidth: 6)
                    RoundedRectangle(cornerRadius: 0)
                        .strokeBorder(SwiftUI.Color.red, lineWidth: 3)
                        .padding(3)
                } else if isSelected {
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
