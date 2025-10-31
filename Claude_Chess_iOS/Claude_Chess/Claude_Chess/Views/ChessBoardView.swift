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
    @AppStorage("showLastMoveHighlight") private var showLastMoveHighlight: Bool = true
    @AppStorage("showCoordinates") private var showCoordinates: Bool = false

    // Opponent settings for engine initialization
    @AppStorage("selectedEngine") private var selectedEngine = "human"
    @AppStorage("stockfishSkillLevel") private var skillLevel = 5
    @AppStorage("stockfishPlaysColor") private var stockfishPlaysColor = "black"

    // Game-ending alerts
    @State private var showingCheckmate = false
    @State private var showingStalemate = false
    @State private var showingFiftyMoveDraw = false
    @State private var showingResignation = false
    @State private var showingThreefoldRepetition = false
    @State private var showingDrawResult = false  // Generic draw result (for AI draw offers)
    @State private var showingThreefoldDrawResult = false  // Threefold repetition draw result
    @State private var winnerColor: Color?

    // Check indicator
    @State private var showingCheckAlert = false
    @State private var checkAlertPlayerName: String = ""  // Capture player name when alert triggers
    @State private var kingInCheckPosition: Position?

    // Pawn promotion
    @State private var showingPromotionPicker = false
    @State private var promotionFrom: Position?
    @State private var promotionTo: Position?
    @State private var promotionColor: Color?

    // AI move tracking (prevent concurrent AI move requests)
    @State private var aiMoveInProgress = false

    /// Check if any alert or modal is currently showing that should block AI moves
    private func isAnyAlertShowing() -> Bool {
        if showingCheckmate { return true }
        if showingStalemate { return true }
        if showingFiftyMoveDraw { return true }
        if showingResignation { return true }
        if game.threefoldAlertShowing { return true }  // Use @Published flag, not @State
        if showingDrawResult { return true }
        if showingThreefoldDrawResult { return true }
        if showingCheckAlert { return true }
        if showingAITimeoutAlert { return true }
        if showingPromotionPicker { return true }
        return false
    }

    // AI timeout handling
    @State private var showingAITimeoutAlert = false
    @State private var aiTimeoutError: String = ""

    // TEMPORARY: Blocking overlay for testing race condition
    @State private var showingWaitOverlay = false

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

    // TEMPORARY: Wait overlay view for testing
    private var waitOverlay: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.6)
                .ignoresSafeArea()
                .allowsHitTesting(true)  // Block all touches

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(2.0)
                    .progressViewStyle(CircularProgressViewStyle(tint: SwiftUI.Color.white))

                Text("Please wait...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(SwiftUI.Color.white)
            }
        }
        .allowsHitTesting(true)  // Ensure overlay captures all touch events
    }

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

    /// Compute a darker, more visible version of the dark square color for coordinate labels
    private var coordinateLabelColor: SwiftUI.Color {
        let darkColor = currentTheme.darkSquare.color

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

    /// Get display name for AI color (for timeout alert button)
    private var aiColorName: String {
        return stockfishPlaysColor == "white" ? "White" : "Black"
    }

    var body: some View {
        boardContentView
            .onAppear {
                checkGameEnd()
            }
            .onChange(of: game.currentPlayer) { _, _ in
                checkGameEnd()
            }
            .onChange(of: game.resetTrigger) { _, _ in
                resetBoardState()
            }
            .onChange(of: game.aiMoveCheckTrigger) { _, _ in
                checkGameEnd()
                if game.gameInProgress && game.isAITurn {
                    triggerAIMove()
                }
            }
            .onChange(of: game.resignationWinner) { _, newValue in
                if newValue != nil {
                    checkGameEnd()
                }
            }
            .onChange(of: showingThreefoldRepetition) { oldValue, newValue in
                if oldValue == true && newValue == false {
                    // Clear the blocking flag
                    game.threefoldAlertShowing = false

                    // Restart timer when threefold alert is dismissed
                    if game.gameInProgress && !game.gameHasEnded {
                        game.startMoveTimer()
                    }

                    // Trigger AI move if it's AI's turn
                    if !game.gameHasEnded {
                        triggerAIMove()
                    }
                }
            }
            .onChange(of: showingCheckAlert) { oldValue, newValue in
                if oldValue == true && newValue == false {
                    // Restart timer when check alert is dismissed
                    if game.gameInProgress && !game.gameHasEnded {
                        game.startMoveTimer()
                    }
                    // Trigger AI move if it's AI's turn
                    if !game.gameHasEnded && game.gameInProgress {
                        triggerAIMove()
                    }
                }
            }
            .onChange(of: game.threefoldDrawClaimed) { oldValue, newValue in
                // When Claim Draw button is pressed, show threefold draw result alert
                if newValue == true && game.gameHasEnded {
                    showingThreefoldDrawResult = true
                }
            }
    }

    private var boardContentView: some View {
        GeometryReader { geometry in
            // Calculate square size accounting for coordinate labels if shown
            // When coordinates shown, allocate ~6% for labels, leaving 94% for board
            let availableSize = min(geometry.size.width, geometry.size.height)
            let squareSize = showCoordinates ? (availableSize * 0.94) / 8 : availableSize / 8
            let labelSize = showCoordinates ? availableSize * 0.06 : 0

            ZStack {
                // Main layout: Board + Labels (labels stay in place, only board rotates)
                VStack(spacing: 0) {
                    // Top spacer for coordinate labels
                    if showCoordinates {
                        Spacer()
                            .frame(height: labelSize)
                    }

                    HStack(spacing: 0) {
                        // Left rank labels (ALWAYS on left, order reverses when flipped)
                        if showCoordinates {
                            VStack(spacing: 0) {
                                ForEach(0..<rows, id: \.self) { row in
                                    // Reverse order when flipped: unflipped = 8,7,6..1, flipped = 1,2,3..8
                                    let rank = boardFlipped ? (row + 1) : (8 - row)
                                    Text("\(rank)")
                                        .font(.system(size: squareSize * 0.25, weight: .bold))
                                        .foregroundColor(coordinateLabelColor)
                                        .frame(width: labelSize, height: squareSize)
                                }
                            }
                        }

                        // Chess board only (this gets rotated, not the labels)
                        VStack(spacing: 0) {
                            ForEach(0..<rows, id: \.self) { row in
                                HStack(spacing: 0) {
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
                                            isKingInCheck: kingInCheckPosition == position,
                                            isLastMoveOrigin: showLastMoveHighlight && game.lastMoveFrom == position,
                                            isLastMoveDestination: showLastMoveHighlight && game.lastMoveTo == position
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
                        .frame(width: squareSize * 8, height: squareSize * 8)
                        .rotationEffect(.degrees(boardFlipped ? 180 : 0))  // Only rotate the board, not labels
                    }

                    // Bottom file labels (ALWAYS on bottom, order reverses when flipped)
                    if showCoordinates {
                        HStack(spacing: 0) {
                            // Left spacer to align with rank labels
                            Spacer()
                                .frame(width: labelSize)

                            // File labels - reverse order when flipped: unflipped = a,b,c..h, flipped = h,g,f..a
                            ForEach(0..<columns, id: \.self) { col in
                                let file = boardFlipped ? String(UnicodeScalar(UInt8(104 - col))) : String(UnicodeScalar(UInt8(97 + col)))
                                Text(file)
                                    .font(.system(size: squareSize * 0.25, weight: .bold))
                                    .foregroundColor(coordinateLabelColor)
                                    .frame(width: squareSize, height: labelSize)
                            }
                        }
                    }
                }
                .frame(
                    width: showCoordinates ? (squareSize * 8) + labelSize : squareSize * 8,
                    height: showCoordinates ? (squareSize * 8) + labelSize : squareSize * 8
                )
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
                .disabled(showingWaitOverlay)  // Disable board interaction when overlay is showing

                // Dragged piece overlay
                if let draggedPos = draggedPiece {
                    let piece = game.getPiece(at: draggedPos)
                    if piece.type != .empty {
                        // Calculate the actual screen position of the dragged piece
                        // Account for coordinate labels when calculating board origin
                        let actualBoardSize = squareSize * 8
                        let totalWidth = showCoordinates ? actualBoardSize + labelSize : actualBoardSize
                        let totalHeight = showCoordinates ? actualBoardSize + labelSize : actualBoardSize

                        let boardOriginX = (geometry.size.width - totalWidth) / 2 + (showCoordinates ? labelSize : 0)
                        let boardOriginY = (geometry.size.height - totalHeight) / 2 + (showCoordinates ? labelSize : 0)

                        // When board is flipped, the visual position is inverted
                        // Unflipped: row 0 = top, col 0 = left
                        // Flipped: row 0 = bottom (visually at row 7), col 0 = right (visually at col 7)
                        let visualRow = boardFlipped ? (7 - draggedPos.row) : draggedPos.row
                        let visualCol = boardFlipped ? (7 - draggedPos.col) : draggedPos.col

                        let pieceStartX = boardOriginX + CGFloat(visualCol) * squareSize + squareSize / 2
                        let pieceStartY = boardOriginY + CGFloat(visualRow) * squareSize + squareSize / 2

                        // When board is flipped, drag offset must also be inverted (finger moves right = piece moves left in flipped view)
                        let adjustedDragWidth = boardFlipped ? -dragOffset.width : dragOffset.width
                        let adjustedDragHeight = boardFlipped ? -dragOffset.height : dragOffset.height

                        // Offset the ghost piece so it's visible (up and to the right of finger)
                        let visualOffset = squareSize * 0.6

                        Image(piece.assetName)
                            .resizable()
                            .frame(width: squareSize * 0.9, height: squareSize * 0.9)
                            // Don't rotate the piece itself - pieces stay upright regardless of board orientation
                            .position(
                                x: pieceStartX + adjustedDragWidth + visualOffset,
                                y: pieceStartY + adjustedDragHeight - visualOffset
                            )
                            .shadow(radius: 10)
                            .allowsHitTesting(false)
                    }
                }

                // TEMPORARY: Blocking overlay for testing race condition
                if showingWaitOverlay {
                    waitOverlay
                }
            }
        }
        // Custom checkmate alert with fallen king icon
        .overlay {
            if showingCheckmate, let winner = winnerColor {
                CheckmateAlertView(
                    winner: winner,
                    isPresented: $showingCheckmate,
                    onNewGame: {
                        Task {
                            await game.resetGame(selectedEngine: selectedEngine, skillLevel: skillLevel, stockfishColor: stockfishPlaysColor)
                            resetBoardState()
                        }
                    }
                )
            }
        }
        // Custom stalemate alert with both kings
        .overlay {
            if showingStalemate {
                StalemateAlertView(
                    isPresented: $showingStalemate,
                    onNewGame: {
                        Task {
                            await game.resetGame(selectedEngine: selectedEngine, skillLevel: skillLevel, stockfishColor: stockfishPlaysColor)
                            resetBoardState()
                        }
                    }
                )
            }
        }
        // Custom 50-move draw alert with both kings
        .overlay {
            if showingFiftyMoveDraw {
                FiftyMoveDrawAlertView(
                    isPresented: $showingFiftyMoveDraw,
                    onOK: {
                        // Keep game locked (gameHasEnded already true from checkGameEnd)
                    },
                    onNewGame: {
                        Task {
                            await game.resetGame(selectedEngine: selectedEngine, skillLevel: skillLevel, stockfishColor: stockfishPlaysColor)
                            resetBoardState()
                        }
                    }
                )
            }
        }
        // Custom threefold repetition alert (human player only)
        .overlay {
            if showingThreefoldRepetition {
                ThreefoldRepetitionAlertView(
                    isPresented: $showingThreefoldRepetition,
                    onClaimDraw: {
                        // Human claims draw
                        game.threefoldAlertShowing = false
                        kingInCheckPosition = nil
                        game.gameHasEnded = true
                        game.stopMoveTimer()
                        game.threefoldDrawClaimed = true
                        showingThreefoldDrawResult = true  // Show threefold-specific alert
                    },
                    onContinuePlaying: {
                        // Human continues playing
                        game.threefoldAlertShowing = false
                        game.threefoldDrawClaimed = false
                    }
                )
            }
        }
        // Custom draw result alert (for AI draw offers)
        .overlay {
            if showingDrawResult {
                DrawResultAlertView(
                    isPresented: $showingDrawResult,
                    onNewGame: {
                        Task {
                            await game.resetGame(selectedEngine: selectedEngine, skillLevel: skillLevel, stockfishColor: stockfishPlaysColor)
                            resetBoardState()
                        }
                    }
                )
            }
        }
        // Custom threefold draw result alert
        .overlay {
            if showingThreefoldDrawResult {
                ThreefoldDrawResultAlertView(
                    isPresented: $showingThreefoldDrawResult,
                    onNewGame: {
                        Task {
                            await game.resetGame(selectedEngine: selectedEngine, skillLevel: skillLevel, stockfishColor: stockfishPlaysColor)
                            resetBoardState()
                        }
                    }
                )
            }
        }
        // Spinner while AI evaluates threefold claim
        .overlay {
            if game.evaluatingThreefoldClaim {
                ZStack {
                    SwiftUI.Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))

                        Text("Evaluating draw claim...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        // Custom resignation alert with chess piece icon
        .overlay {
            if showingResignation {
                ResignationAlertView(
                    winner: game.resignationWinner ?? "White",
                    isPresented: $showingResignation,
                    onNewGame: {
                        Task {
                            await game.resetGame(selectedEngine: selectedEngine, skillLevel: skillLevel, stockfishColor: stockfishPlaysColor)
                            resetBoardState()
                        }
                    }
                )
            }
        }
        .overlay {
            if showingCheckAlert {
                CheckAlertView(
                    isPresented: $showingCheckAlert,
                    playerName: checkAlertPlayerName
                )
            }
        }
        .overlay {
            if showingAITimeoutAlert {
                AITimeoutAlertView(
                    isPresented: $showingAITimeoutAlert,
                    aiColorName: aiColorName,
                    errorMessage: aiTimeoutError,
                    onTryAgain: {
                        triggerAIMove()
                    },
                    onResign: {
                        // AI forfeits - human wins
                        let humanColor = stockfishPlaysColor == "white" ? "Black" : "White"
                        game.resignationWinner = humanColor
                        game.gameHasEnded = true

                        // Dismiss timeout alert and trigger resignation alert overlay
                        showingAITimeoutAlert = false
                        showingResignation = true
                    }
                )
            }
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
        // Prevent any moves until "Start Game" is tapped or if game has ended
        guard game.gameInProgress && !game.gameHasEnded else {
            return
        }

        // Prevent human from moving during AI's turn
        guard game.isHumanTurn else {
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
        // Account for coordinate labels
        let availableSize = min(geometry.size.width, geometry.size.height)
        let labelSize = showCoordinates ? availableSize * 0.06 : 0
        let actualBoardSize = squareSize * 8
        let totalWidth = showCoordinates ? actualBoardSize + labelSize : actualBoardSize
        let totalHeight = showCoordinates ? actualBoardSize + labelSize : actualBoardSize

        let boardOriginX = (geometry.size.width - totalWidth) / 2 + (showCoordinates ? labelSize : 0)
        let boardOriginY = (geometry.size.height - totalHeight) / 2 + (showCoordinates ? labelSize : 0)

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
                    let success = game.makeMove(from: position, to: dropPosition)
                    if success {
                        // Heavy haptic feedback for successful move
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            heavyHaptic.impactOccurred()
                        }
                        #endif

                        // Check for game-ending conditions
                        checkGameEnd()

                        // NOTE: Position evaluation NOT done here to avoid concurrent UCI requests
                        // Evaluation happens AFTER AI move completes (see triggerAIMove)

                        // Trigger AI move if playing against AI (terminal project parity)
                        // Don't trigger if any alert is showing - will trigger when dismissed
                        if !isAnyAlertShowing() {
                            triggerAIMove()
                        }
                    }
                }
            } else {
                // Invalid move - warning notification haptic
                #if os(iOS)
                if hapticFeedbackEnabled {
                    warningHaptic.notificationOccurred(.warning)
                }
                #endif
            }
        }

        // Reset drag state and clear any lingering selection
        draggedPiece = nil
        dragOffset = .zero
        selectedSquare = nil  // Clear selection to remove blue border
        legalMoveSquares = []
        capturablePositions = []
    }

    /// Handle double-tap on a square (preview mode toggle)
    private func handleDoubleTap(at position: Position) {
        // Prevent preview if game hasn't started or has ended
        guard game.gameInProgress && !game.gameHasEnded else {
            return
        }

        // Prevent preview during AI's turn (could block AI move execution)
        guard game.isHumanTurn else {
            return
        }

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
        // Prevent any moves until "Start Game" is tapped or if game has ended
        guard game.gameInProgress && !game.gameHasEnded else {
            return
        }

        // Prevent human from moving during AI's turn
        guard game.isHumanTurn else {
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
                    // Execute the move with full game state updates
                    let success = game.makeMove(from: selected, to: position)
                    if success {
                        // Heavy haptic feedback for successful move
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            heavyHaptic.impactOccurred()
                        }
                        #endif

                        clearSelection()
                        clearPreview()

                        // Check for game-ending conditions
                        checkGameEnd()

                        // NOTE: Position evaluation NOT done here to avoid concurrent UCI requests
                        // Evaluation happens AFTER AI move completes (see triggerAIMove)

                        // Trigger AI move if playing against AI (terminal project parity)
                        // Don't trigger if any alert is showing - will trigger when dismissed
                        if !isAnyAlertShowing() {
                            triggerAIMove()
                        }
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
        aiMoveInProgress = false  // Clear AI move flag

        // Clear all alert states
        showingCheckmate = false
        showingStalemate = false
        showingFiftyMoveDraw = false
        showingResignation = false
        showingThreefoldRepetition = false
        showingDrawResult = false
        showingThreefoldDrawResult = false
        showingCheckAlert = false
        showingAITimeoutAlert = false
        showingPromotionPicker = false
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

            // Check for game-ending conditions
            checkGameEnd()

            // NOTE: Position evaluation NOT done here to avoid concurrent UCI requests
            // Evaluation happens AFTER AI move completes (see triggerAIMove)

            // Trigger AI move if playing against AI (terminal project parity)
            // Don't trigger if any alert is showing - will trigger when dismissed
            if !isAnyAlertShowing() {
                triggerAIMove()
            }
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
        // Prevent concurrent AI move requests
        guard !aiMoveInProgress else {
            return
        }

        // Only trigger if playing against AI engine
        guard game.isAIOpponent else {
            return
        }

        // Only trigger if it's the AI's turn
        guard game.isAITurn else {
            return
        }

        // Check if game is in progress
        guard game.gameInProgress else {
            return
        }

        // Don't trigger AI move if threefold alert is showing to human
        guard !game.threefoldAlertShowing else {
            return
        }

        // Only trigger if game hasn't ended
        guard !GameStateChecker.isCheckmate(game: game, color: game.currentPlayer) &&
              !GameStateChecker.isStalemate(game: game, color: game.currentPlayer) &&
              !game.isFiftyMoveRuleDraw() else {
            return
        }

        // Set flag to prevent concurrent requests
        aiMoveInProgress = true

        // Request and execute AI move asynchronously
        Task {
            do {
                // Record start time to ensure minimum 1 second elapsed
                let moveStartTime = Date()

                // Get AI move from engine
                guard let uciMove = try await game.getAIMove() else {
                    print("ERROR: AI engine returned no move")
                    // Clear flag before returning
                    await MainActor.run {
                        aiMoveInProgress = false
                    }
                    return
                }

                // Calculate how long Stockfish took
                let engineElapsed = Date().timeIntervalSince(moveStartTime)

                // If less than 1 second, wait for the remainder to ensure 1 second minimum
                if engineElapsed < 1.0 {
                    let remainingTime = 1.0 - engineElapsed
                    try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
                }

                // Execute the AI move (this calls stopMoveTimer which deducts the actual elapsed time)
                let success = await game.executeAIMove(uciMove)

                if success {
                    // Heavy haptic feedback for AI move
                    await MainActor.run {
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            heavyHaptic.impactOccurred()
                        }
                        #endif

                        // DEBUG: Log before checking game end
                        NSLog("DEBUG: AI move completed, calling checkGameEnd()")

                        // Check for game-ending conditions after AI move
                        checkGameEnd()

                        NSLog("DEBUG: checkGameEnd() returned, threefoldAlertShowing = %d", game.threefoldAlertShowing)
                    }

                    // NOTE: Position evaluation NOT done automatically
                    // Evaluation only happens on-demand when user opens ScoreView (see ScoreView.swift)
                    // This prevents concurrent UCI requests that caused AI freeze bugs
                } else {
                    print("ERROR: Failed to execute AI move: \(uciMove)")
                }

                // CRITICAL: Clear flag AFTER all post-move operations complete
                // This prevents race conditions where user input during state updates
                // could trigger another AI move before the view fully stabilizes
                await MainActor.run {
                    aiMoveInProgress = false
                }
            } catch {
                // AI move request failed (likely timeout or engine error)
                await MainActor.run {
                    aiTimeoutError = error.localizedDescription
                    showingAITimeoutAlert = true
                    aiMoveInProgress = false
                }
            }
        }
    }

    /// Check for game-ending conditions (checkmate, stalemate, 50-move rule, resignation, check) after a move
    private func checkGameEnd() {
        // Check for resignation (happens when game ends but not in progress)
        if !game.gameInProgress && game.resignationWinner != nil {
            kingInCheckPosition = nil
            showingResignation = true
            return
        }

        // Only check game-ending conditions if game has been started
        // This prevents alerts when setting up positions via Setup Board
        guard game.gameInProgress else {
            // Clear all alert states when game not in progress
            kingInCheckPosition = nil
            showingCheckmate = false
            showingStalemate = false
            showingFiftyMoveDraw = false
            showingResignation = false
            return
        }

        // Check for 50-move rule draw (highest priority - automatic draw)
        if game.isFiftyMoveRuleDraw() {
            kingInCheckPosition = nil  // Clear check indicator
            game.gameHasEnded = true
            game.stopMoveTimer()  // Stop timer on draw
            showingFiftyMoveDraw = true
            return
        }

        // Check for threefold repetition
        NSLog("DEBUG: Checking threefold repetition...")
        if game.checkThreefoldRepetition() {
            NSLog("DEBUG: THREEFOLD DETECTED! isAITurn = %d", game.isAITurn)
            // Clear check alert and visual indicator since threefold takes priority
            showingCheckAlert = false
            kingInCheckPosition = nil

            // Handle based on current player
            if game.isAITurn {
                // Prevent concurrent evaluations
                guard !game.evaluatingThreefoldClaim else {
                    NSLog("DEBUG: AI threefold evaluation already in progress, skipping")
                    return
                }

                NSLog("DEBUG: AI's turn - evaluating draw claim...")
                // Set BOTH flags IMMEDIATELY to block concurrent triggers
                game.threefoldAlertShowing = true
                game.evaluatingThreefoldClaim = true  // Set BEFORE Task starts

                // Evaluate and auto-claim if losing badly (timer keeps running - evaluation is "on the clock")
                Task {
                    let aiClaimsDraw = await game.handleAIThreefoldRepetition()
                    await MainActor.run {
                        NSLog("DEBUG: AI threefold decision returned: %d", aiClaimsDraw)
                        game.threefoldDrawClaimed = aiClaimsDraw
                        if aiClaimsDraw {
                            // AI claims draw - stop timer
                            NSLog("DEBUG: AI claimed draw - ending game")
                            kingInCheckPosition = nil
                            game.gameHasEnded = true
                            game.stopMoveTimer()
                            showingThreefoldDrawResult = true  // Show threefold-specific alert
                        } else {
                            // AI continues playing - clear flag and continue (timer never stopped)
                            NSLog("DEBUG: AI declined draw - clearing flag")
                            game.threefoldAlertShowing = false
                            if game.gameInProgress && !game.gameHasEnded {
                                NSLog("DEBUG: Triggering AI move")
                                triggerAIMove()
                            }
                        }
                    }
                }
            } else {
                // Human's turn - show alert with choice (stop timer while human decides)
                NSLog("DEBUG: Human's turn - showing alert")
                game.stopMoveTimer()
                game.threefoldAlertShowing = true
                game.incrementThreefoldAlertCount()  // Increment alert count when showing to human
                showingThreefoldRepetition = true
            }
            return
        }
        NSLog("DEBUG: No threefold detected")

        // Check if current player is in checkmate
        if GameStateChecker.isCheckmate(game: game, color: game.currentPlayer) {
            winnerColor = game.currentPlayer.opposite
            game.checkmateWinner = game.currentPlayer.opposite  // Store winner in game model
            kingInCheckPosition = nil  // Clear check indicator
            game.gameHasEnded = true
            game.stopMoveTimer()  // Stop timer on checkmate
            showingCheckmate = true
            return
        }

        // Check if current player is in stalemate
        if GameStateChecker.isStalemate(game: game, color: game.currentPlayer) {
            kingInCheckPosition = nil  // Clear check indicator
            game.gameHasEnded = true
            game.stopMoveTimer()  // Stop timer on stalemate
            showingStalemate = true
            return
        }

        // Check if current player is in check
        if GameStateChecker.isInCheck(game: game, color: game.currentPlayer) {
            // Set king position for visual indicator (red border)
            kingInCheckPosition = game.currentPlayer == .white ? game.whiteKingPos : game.blackKingPos

            // Only show check alert if no other alerts are showing
            // Check alerts are informational and should never interrupt important game-ending alerts
            if !showingCheckmate && !showingStalemate && !showingFiftyMoveDraw &&
               !showingResignation && !showingThreefoldRepetition && !showingDrawResult &&
               !showingThreefoldDrawResult {
                // Capture the player name NOW before it changes
                checkAlertPlayerName = game.currentPlayer.displayName
                // Stop timer while check alert is displayed
                game.stopMoveTimer()
                showingCheckAlert = true
            }
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
    let isLastMoveOrigin: Bool
    let isLastMoveDestination: Bool

    @State private var blinkOpacity: Double = 1.0
    @AppStorage("boardFlipped") private var boardFlipped: Bool = false

    // Compute highlight color (complementary to square color)
    private var highlightColor: SwiftUI.Color {
        // For light squares, use darker highlight; for dark squares, use lighter highlight
        return isLight ? SwiftUI.Color.orange.opacity(0.5) : SwiftUI.Color.yellow.opacity(0.5)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Square background
                (isLight ? lightColor : darkColor)

                // Last move highlighting (destination square - more prominent)
                if isLastMoveDestination {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(highlightColor)

                    // Corner triangles for maximum visibility (black contrasts with all themes)
                    // Top-left triangle
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.25, y: 0))
                        path.addLine(to: CGPoint(x: 0, y: geometry.size.height * 0.25))
                        path.closeSubpath()
                    }
                    .fill(SwiftUI.Color.black)

                    // Top-right triangle
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.75, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.25))
                        path.closeSubpath()
                    }
                    .fill(SwiftUI.Color.black)

                    // Bottom-left triangle
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.25, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geometry.size.height * 0.75))
                        path.closeSubpath()
                    }
                    .fill(SwiftUI.Color.black)

                    // Bottom-right triangle
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.75, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.75))
                        path.closeSubpath()
                    }
                    .fill(SwiftUI.Color.black)
                }

                // Last move highlighting (origin square - subtle)
                if isLastMoveOrigin {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(highlightColor.opacity(0.4))

                    // Smaller corner triangles to distinguish from destination (black with opacity)
                    // Top-left triangle
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.15, y: 0))
                        path.addLine(to: CGPoint(x: 0, y: geometry.size.height * 0.15))
                        path.closeSubpath()
                    }
                    .fill(SwiftUI.Color.black.opacity(0.6))

                    // Top-right triangle
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.85, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.15))
                        path.closeSubpath()
                    }
                    .fill(SwiftUI.Color.black.opacity(0.6))

                    // Bottom-left triangle
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.15, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geometry.size.height * 0.85))
                        path.closeSubpath()
                    }
                    .fill(SwiftUI.Color.black.opacity(0.6))

                    // Bottom-right triangle
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.85, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.85))
                        path.closeSubpath()
                    }
                    .fill(SwiftUI.Color.black.opacity(0.6))
                }

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

/// Custom checkmate alert with winning king icon
struct CheckmateAlertView: View {
    let winner: Color
    @Binding var isPresented: Bool
    let onNewGame: () -> Void

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Checkmate!")
                    .font(.headline)
                    .padding(.top)

                VStack(spacing: 12) {
                    // Show winner's king standing upright (victorious)
                    Image(winner == .white ? "Chess_klt45" : "Chess_kdt45")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)

                    Text("\(winner.displayName) wins!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding()

                HStack(spacing: 12) {
                    Button("OK") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                    Button("New Game") {
                        isPresented = false
                        onNewGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
            }
            .frame(width: 300)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
    }
}

/// Custom stalemate alert with both kings
struct StalemateAlertView: View {
    @Binding var isPresented: Bool
    let onNewGame: () -> Void

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Stalemate!")
                    .font(.headline)
                    .padding(.top)

                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Image("Chess_klt45")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)

                        Image("Chess_kdt45")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }

                    Text("The game is a draw.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding()

                HStack(spacing: 12) {
                    Button("OK") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                    Button("New Game") {
                        isPresented = false
                        onNewGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
            }
            .frame(width: 300)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
    }
}

/// Custom 50-move rule draw alert with both kings
struct FiftyMoveDrawAlertView: View {
    @Binding var isPresented: Bool
    let onOK: () -> Void
    let onNewGame: () -> Void

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("50-Move Rule Draw!")
                    .font(.headline)
                    .padding(.top)

                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Image("Chess_klt45")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)

                        Image("Chess_kdt45")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }

                    Text("The game is a draw. 50 moves have been made without a pawn move or capture.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding()

                HStack(spacing: 12) {
                    Button("OK") {
                        isPresented = false
                        onOK()
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                    Button("New Game") {
                        isPresented = false
                        onNewGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
            }
            .frame(width: 300)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
    }
}

/// Custom resignation alert with chess piece icon
struct ResignationAlertView: View {
    let winner: String
    @Binding var isPresented: Bool
    let onNewGame: () -> Void

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Game Over - Resignation")
                    .font(.headline)
                    .padding(.top)

                VStack(spacing: 12) {
                    Image(winner == "White" ? "Chess_plt45" : "Chess_pdt45")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)

                    Text("\(winner) wins by resignation!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding()

                HStack(spacing: 12) {
                    Button("OK") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                    Button("New Game") {
                        isPresented = false
                        onNewGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
            }
            .frame(width: 300)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
    }
}

/// Custom time forfeit alert with chess piece icon
struct TimeForfeitAlertView: View {
    let winner: Color
    @Binding var isPresented: Bool
    let onOK: () -> Void
    let onNewGame: () -> Void

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Game Over - Time Forfeit")
                    .font(.headline)
                    .padding(.top)

                VStack(spacing: 12) {
                    Image(winner == .white ? "Chess_plt45" : "Chess_pdt45")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)

                    Text("\(winner.displayName) wins by time forfeit!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding()

                HStack(spacing: 12) {
                    Button("OK") {
                        isPresented = false
                        onOK()
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                    Button("New Game") {
                        isPresented = false
                        onNewGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
            }
            .frame(width: 300)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
    }
}

/// Custom check alert overlay
struct CheckAlertView: View {
    @Binding var isPresented: Bool
    let playerName: String

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Check!")
                    .font(.headline)
                    .padding(.top)

                Text("\(playerName) is in check!")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("OK") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .frame(width: 300)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// Custom AI timeout alert overlay
struct AITimeoutAlertView: View {
    @Binding var isPresented: Bool
    let aiColorName: String
    let errorMessage: String
    let onTryAgain: () -> Void
    let onResign: () -> Void

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("AI Engine Timeout")
                    .font(.headline)
                    .padding(.top)

                Text("Stockfish did not respond within 30 seconds. This may be due to position complexity or system resources.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("Error: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    Button("Try Again") {
                        isPresented = false
                        onTryAgain()
                    }
                    .buttonStyle(.bordered)

                    Button("Resign for \(aiColorName)") {
                        isPresented = false
                        onResign()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(.bottom)
            }
            .frame(width: 320)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// Custom draw result alert (generic draw)
struct DrawResultAlertView: View {
    @Binding var isPresented: Bool
    let onNewGame: () -> Void

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Draw!")
                    .font(.headline)
                    .padding(.top)

                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Image("Chess_klt45")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)

                        Image("Chess_kdt45")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }

                    Text("The game is a draw.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding()

                HStack(spacing: 12) {
                    Button("OK") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                    Button("New Game") {
                        isPresented = false
                        onNewGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
            }
            .frame(width: 300)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// Custom alert for AI claiming threefold repetition draw
struct ThreefoldDrawResultAlertView: View {
    @Binding var isPresented: Bool
    let onNewGame: () -> Void

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Draw!")
                    .font(.headline)
                    .padding(.top)

                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Image("Chess_klt45")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)

                        Image("Chess_kdt45")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }

                    Text("Draw by threefold repetition.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding()

                HStack(spacing: 12) {
                    Button("OK") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                    Button("New Game") {
                        isPresented = false
                        onNewGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
            }
            .frame(width: 300)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// Custom threefold repetition alert overlay for human player
struct ThreefoldRepetitionAlertView: View {
    @Binding var isPresented: Bool
    let onClaimDraw: () -> Void
    let onContinuePlaying: () -> Void

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Threefold Repetition")
                    .font(.headline)
                    .padding(.top)

                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Image("Chess_klt45")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)

                        Image("Chess_kdt45")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }

                    Text("The same position has occurred three times. You may claim a draw.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding()

                HStack(spacing: 12) {
                    Button("Continue Playing") {
                        isPresented = false
                        onContinuePlaying()
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                    Button("Claim Draw") {
                        isPresented = false
                        onClaimDraw()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
            }
            .frame(width: 300)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

// MARK: - Preview

#Preview {
    ChessBoardView(game: ChessGame())
        .frame(width: 400, height: 400)
}
