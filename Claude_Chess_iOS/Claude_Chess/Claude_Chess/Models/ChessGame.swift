//
//  ChessGame.swift
//  Claude_Chess
//
//  Complete chess game state management
//  Ported from terminal project (chess.c/chess.h)
//

import SwiftUI
import Combine

/// Complete chess game state including board position, player turn,
/// castling rights, en passant, and move counters
class ChessGame: ObservableObject {
    // MARK: - Published Properties

    /// 8x8 chess board with optional pieces
    /// Index [0][0] = a8 (top-left), [7][7] = h1 (bottom-right)
    @Published var board: [[Piece?]]

    /// Current player to move
    @Published var currentPlayer: Color

    /// Trigger for resetting UI state (increments when New Game is created)
    @Published var resetTrigger: Int = 0

    /// Last move made (for highlighting in UI)
    @Published var lastMoveFrom: Position?
    @Published var lastMoveTo: Position?

    // MARK: - Game State Properties

    /// Position of white king (for check detection)
    var whiteKingPos: Position

    /// Position of black king (for check detection)
    var blackKingPos: Position

    /// Castling rights tracking
    var whiteKingMoved: Bool = false
    var blackKingMoved: Bool = false
    var whiteRookKingsideMoved: Bool = false
    var whiteRookQueensideMoved: Bool = false
    var blackRookKingsideMoved: Bool = false
    var blackRookQueensideMoved: Bool = false

    /// En passant state
    var enPassantTarget: Position?

    /// Halfmove clock for 50-move rule (increments each move, reset on
    /// pawn move or capture)
    var halfmoveClock: Int = 0

    /// Fullmove number (increments after Black's move)
    var fullmoveNumber: Int = 1

    // MARK: - Move History

    /// Complete move history for undo and PGN generation
    @Published var moveHistory: [MoveRecord] = []

    // MARK: - Setup Board Captured Pieces

    /// Pieces captured by White before game started (from Setup Board FEN)
    /// These are preserved when calculating total captured pieces
    private var initialCapturedByWhite: [Piece] = []

    /// Pieces captured by Black before game started (from Setup Board FEN)
    /// These are preserved when calculating total captured pieces
    private var initialCapturedByBlack: [Piece] = []

    // MARK: - Time Controls

    /// Time remaining for White in seconds
    @Published var whiteTimeSeconds: Int = 0

    /// Time remaining for Black in seconds
    @Published var blackTimeSeconds: Int = 0

    /// When the current move timer started
    var moveStartTime: Date?

    /// Whether time controls are active for this game
    var timeControlsEnabled: Bool = false

    /// Whether time controls were disabled due to undo
    var timeControlsDisabledByUndo: Bool = false

    /// Time increment for White (seconds added after each move)
    var whiteIncrement: Int = 0

    /// Time increment for Black (seconds added after each move)
    var blackIncrement: Int = 0

    /// Whether the game has been explicitly started by the user
    /// Timer doesn't run until user taps "Start Game"
    @Published var gameInProgress: Bool = false

    /// Whether the game has ended (checkmate/stalemate/resignation/draw)
    /// Prevents restarting game via "Start Game" button after conclusion
    @Published var gameHasEnded: Bool = false

    /// Game result tracking for resignation
    /// Format: "White" or "Black" for winner, or nil if game still active
    @Published var resignationWinner: String?

    /// Checkmate winner tracking
    /// Format: Color of winner, or nil if no checkmate
    @Published var checkmateWinner: Color?

    /// Trigger to check if AI should make first move (after Start Game or Setup Board)
    /// Increments when we need to check for AI's turn
    @Published var aiMoveCheckTrigger: Int = 0

    /// Starting FEN position if game was initiated from Setup Board
    /// Nil if game started from standard position
    var startingFEN: String?

    // MARK: - AI Engine Integration

    /// Stockfish chess engine instance (nil if not using Stockfish)
    var engine: StockfishEngine?

    /// Selected opponent engine from settings
    var selectedEngine: String = "human"

    /// Stockfish skill level (0-20, only used when selectedEngine == "stockfish")
    var skillLevel: Int = 5

    /// Which color Stockfish is playing ("white" or "black")
    /// Default: "black" (human plays White)
    var stockfishColor: String = "black"

    /// Whether current opponent is an AI engine (not human vs human)
    var isAIOpponent: Bool {
        return selectedEngine != "human"
    }

    /// Which color the AI is playing
    private var aiColor: Color? {
        guard isAIOpponent else { return nil }
        return stockfishColor == "white" ? .white : .black
    }

    /// Whether it's currently the AI's turn to move
    /// Returns true if AI opponent is enabled and it's the AI's color turn
    var isAITurn: Bool {
        guard let aiColor = aiColor else { return false }
        return currentPlayer == aiColor
    }

    /// Whether it's currently a human player's turn to move
    /// Returns true if no AI opponent OR it's not the AI's turn
    var isHumanTurn: Bool {
        return !isAITurn
    }

    // MARK: - Position Evaluation

    /// Current position evaluation in centipawns (from Stockfish)
    /// Positive = White advantage, Negative = Black advantage
    /// nil = evaluation not yet calculated or unavailable
    @Published var positionEvaluation: Int? = nil

    // MARK: - Hint System

    /// Current hint move in UCI notation (e.g., "e2e4", "e7e8q")
    /// nil = no hint requested or hint unavailable
    @Published var currentHint: String? = nil

    // MARK: - Initialization

    /// Initialize a new chess game with standard starting position
    init() {
        // Initialize empty board
        self.board = Array(repeating: Array(repeating: nil, count: 8),
                          count: 8)
        self.currentPlayer = .white

        // Set king positions to standard starting squares
        // White king starts at e1 (row 7, col 4)
        // Black king starts at e8 (row 0, col 4)
        self.whiteKingPos = Position(row: 7, col: 4)
        self.blackKingPos = Position(row: 0, col: 4)

        // Setup standard chess starting position
        setupInitialPosition()
    }

    // MARK: - Board Setup

    /// Setup standard chess starting position
    /// Follows FEN: rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR
    private func setupInitialPosition() {
        // Clear board
        for row in 0..<8 {
            for col in 0..<8 {
                board[row][col] = nil
            }
        }

        // Black pieces (rank 8 - row 0)
        board[0][0] = Piece(type: .rook, color: .black)
        board[0][1] = Piece(type: .knight, color: .black)
        board[0][2] = Piece(type: .bishop, color: .black)
        board[0][3] = Piece(type: .queen, color: .black)
        board[0][4] = Piece(type: .king, color: .black)
        board[0][5] = Piece(type: .bishop, color: .black)
        board[0][6] = Piece(type: .knight, color: .black)
        board[0][7] = Piece(type: .rook, color: .black)

        // Black pawns (rank 7 - row 1)
        for col in 0..<8 {
            board[1][col] = Piece(type: .pawn, color: .black)
        }

        // White pawns (rank 2 - row 6)
        for col in 0..<8 {
            board[6][col] = Piece(type: .pawn, color: .white)
        }

        // White pieces (rank 1 - row 7)
        board[7][0] = Piece(type: .rook, color: .white)
        board[7][1] = Piece(type: .knight, color: .white)
        board[7][2] = Piece(type: .bishop, color: .white)
        board[7][3] = Piece(type: .queen, color: .white)
        board[7][4] = Piece(type: .king, color: .white)
        board[7][5] = Piece(type: .bishop, color: .white)
        board[7][6] = Piece(type: .knight, color: .white)
        board[7][7] = Piece(type: .rook, color: .white)

        // Set king positions
        whiteKingPos = Position(row: 7, col: 4)
        blackKingPos = Position(row: 0, col: 4)

        // Initialize game state
        currentPlayer = .white
        halfmoveClock = 0
        fullmoveNumber = 1
        enPassantTarget = nil

        // Reset castling rights
        whiteKingMoved = false
        blackKingMoved = false
        whiteRookKingsideMoved = false
        whiteRookQueensideMoved = false
        blackRookKingsideMoved = false
        blackRookQueensideMoved = false
    }

    // MARK: - Game Management

    /// Reset game to starting position and initialize AI engine if needed
    /// Clears the board and reinitializes to standard chess starting position
    /// Ported from terminal project newGame() logic
    /// - Parameters:
    ///   - selectedEngine: Engine selection from settings ("human", "stockfish", etc.)
    ///   - skillLevel: Stockfish skill level (0-20)
    ///   - stockfishColor: Which color Stockfish is playing ("white" or "black")
    func resetGame(selectedEngine: String = "human", skillLevel: Int = 5, stockfishColor: String = "black") async {
        setupInitialPosition()
        // Clear move history (captured pieces tracking)
        moveHistory.removeAll()
        // Clear initial captured pieces from Setup Board
        initialCapturedByWhite.removeAll()
        initialCapturedByBlack.removeAll()
        // Clear last move highlighting
        lastMoveFrom = nil
        lastMoveTo = nil
        // Reset timer state
        moveStartTime = nil
        timeControlsDisabledByUndo = false
        gameInProgress = false  // User must explicitly start game
        gameHasEnded = false    // Clear game-ended flag for new game
        // Clear game result tracking
        resignationWinner = nil
        checkmateWinner = nil
        // Clear starting FEN (standard position)
        startingFEN = nil
        // Increment reset trigger to notify UI to clear selection state
        resetTrigger += 1

        // Store skill level for draw evaluation
        self.skillLevel = skillLevel

        // Initialize AI engine if Stockfish is selected (terminal project parity)
        do {
            try await initializeEngine(selectedEngine: selectedEngine, skillLevel: skillLevel, stockfishColor: stockfishColor)
        } catch {
            print("ERROR: Failed to initialize engine: \(error)")
        }
    }

    /// Setup board from FEN string
    /// Ported from terminal project chess.c:setup_board_from_fen()
    /// - Parameter fen: Standard FEN notation string
    /// - Returns: True if FEN was valid and board was set up, false otherwise
    func setupFromFEN(_ fen: String) -> Bool {
        let trimmedFen = fen.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmedFen.split(separator: " ", maxSplits: 5, omittingEmptySubsequences: false)

        // FEN requires at least 6 components: pieces, player, castling, en passant, halfmove, fullmove
        guard components.count >= 6 else { return false }

        // Create temporary board to validate FEN before modifying game state
        var tempBoard: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)

        // Parse piece placement (component 0)
        let ranks = components[0].split(separator: "/")
        guard ranks.count == 8 else { return false }

        var foundWhiteKing = false
        var foundBlackKing = false
        var tempWhiteKingPos: Position?
        var tempBlackKingPos: Position?

        for (rankIndex, rankStr) in ranks.enumerated() {
            var file = 0
            for char in rankStr {
                if char.isNumber {
                    // Empty squares
                    guard let skipCount = Int(String(char)), skipCount >= 1 && skipCount <= 8 else { return false }
                    file += skipCount
                } else {
                    // Piece
                    guard file < 8 else { return false }
                    guard let piece = Piece.fromFENCharacter(char) else { return false }

                    tempBoard[rankIndex][file] = piece

                    // Track king positions
                    if piece.type == .king {
                        let kingPos = Position(row: rankIndex, col: file)
                        if piece.color == .white {
                            tempWhiteKingPos = kingPos
                            foundWhiteKing = true
                        } else {
                            tempBlackKingPos = kingPos
                            foundBlackKing = true
                        }
                    }

                    file += 1
                }
            }
            guard file == 8 else { return false } // Each rank must have exactly 8 squares
        }

        // Verify both kings are present
        guard foundWhiteKing && foundBlackKing,
              let tempWhiteKing = tempWhiteKingPos,
              let tempBlackKing = tempBlackKingPos else { return false }

        // Parse active color (component 1) into temp variable
        let tempPlayer: Color
        if components[1] == "w" {
            tempPlayer = .white
        } else if components[1] == "b" {
            tempPlayer = .black
        } else {
            return false
        }

        // Parse castling rights (component 2) into temp variables
        var tempWhiteKingMoved = true
        var tempBlackKingMoved = true
        var tempWhiteRookKingsideMoved = true
        var tempWhiteRookQueensideMoved = true
        var tempBlackRookKingsideMoved = true
        var tempBlackRookQueensideMoved = true

        if components[2] != "-" {
            for char in components[2] {
                switch char {
                case "K": tempWhiteKingMoved = false; tempWhiteRookKingsideMoved = false
                case "Q": tempWhiteKingMoved = false; tempWhiteRookQueensideMoved = false
                case "k": tempBlackKingMoved = false; tempBlackRookKingsideMoved = false
                case "q": tempBlackKingMoved = false; tempBlackRookQueensideMoved = false
                default: return false
                }
            }
        }

        // Parse en passant target (component 3) into temp variable
        let tempEnPassant: Position?
        if components[3] == "-" {
            tempEnPassant = nil
        } else {
            guard let pos = Position(algebraic: String(components[3])) else { return false }
            tempEnPassant = pos
        }

        // Parse halfmove clock (component 4) into temp variable
        guard let tempHalfmove = Int(components[4]) else { return false }

        // Parse fullmove number (component 5) into temp variable
        guard let tempFullmove = Int(components[5]) else { return false }

        // ALL VALIDATION PASSED - Now apply changes to actual game state
        board = tempBoard
        currentPlayer = tempPlayer
        whiteKingPos = tempWhiteKing
        blackKingPos = tempBlackKing
        whiteKingMoved = tempWhiteKingMoved
        blackKingMoved = tempBlackKingMoved
        whiteRookKingsideMoved = tempWhiteRookKingsideMoved
        whiteRookQueensideMoved = tempWhiteRookQueensideMoved
        blackRookKingsideMoved = tempBlackRookKingsideMoved
        blackRookQueensideMoved = tempBlackRookQueensideMoved
        enPassantTarget = tempEnPassant
        halfmoveClock = tempHalfmove
        fullmoveNumber = tempFullmove

        // Calculate and store initial captured pieces from this FEN position
        // This preserves captured piece display when moves are made after Setup Board
        initialCapturedByWhite = calculateMissingPieces(for: .black)
        initialCapturedByBlack = calculateMissingPieces(for: .white)

        // Clear last move highlighting from previous game
        lastMoveFrom = nil
        lastMoveTo = nil

        // Clear move history for new position
        moveHistory.removeAll()

        // Reset game state flags so "Start Game" button is enabled
        gameInProgress = false
        gameHasEnded = false
        resignationWinner = nil
        checkmateWinner = nil

        // Reset timer state
        moveStartTime = nil
        timeControlsDisabledByUndo = false

        // Store the starting FEN for PGN generation
        startingFEN = trimmedFen

        return true
    }

    // MARK: - Helper Methods

    /// Check if position is within board bounds
    /// - Parameter position: Position to validate
    /// - Returns: True if position is valid (0-7 for both row and col)
    func isValidPosition(_ position: Position) -> Bool {
        return position.isValid
    }

    /// Get piece at specified position (compatible with optional board)
    /// - Parameter position: Board position
    /// - Returns: Piece at position, or empty piece if square is vacant/invalid
    func getPiece(at position: Position) -> Piece {
        guard position.isValid else {
            return Piece(type: .empty, color: .white)  // Invalid position returns empty
        }
        return board[position.row][position.col] ?? Piece(type: .empty, color: .white)
    }

    /// Get optional piece at specified position
    /// - Parameter position: Board position
    /// - Returns: Piece at position, or nil if empty or invalid
    func getOptionalPiece(at position: Position) -> Piece? {
        guard position.isValid else { return nil }
        return board[position.row][position.col]
    }

    /// Set piece at specified position
    /// - Parameters:
    ///   - piece: Piece to place (nil to clear square)
    ///   - position: Board position
    func setPiece(_ piece: Piece?, at position: Position) {
        guard position.isValid else { return }
        board[position.row][position.col] = piece

        // Update king position tracking
        if let piece = piece, piece.type == .king {
            if piece.color == .white {
                whiteKingPos = position
            } else {
                blackKingPos = position
            }
        }
    }

    /// Check if en passant capture is currently available
    var enPassantAvailable: Bool {
        return enPassantTarget != nil
    }

    // MARK: - Captured Pieces

    /// Get all pieces captured by White
    /// Combines initial captures from Setup Board with captures from move history
    var capturedByWhite: [Piece] {
        // Start with any pieces that were missing when FEN was loaded (Setup Board)
        var captured = initialCapturedByWhite

        // Add captures from move history (pieces captured during actual gameplay)
        let historyCaptured = moveHistory.compactMap { record in
            // White captures when they move (player == .white)
            if record.player == .white, let capturedPiece = record.capturedPiece {
                return capturedPiece
            }
            return nil
        }

        captured.append(contentsOf: historyCaptured)
        return captured
    }

    /// Get all pieces captured by Black
    /// Combines initial captures from Setup Board with captures from move history
    var capturedByBlack: [Piece] {
        // Start with any pieces that were missing when FEN was loaded (Setup Board)
        var captured = initialCapturedByBlack

        // Add captures from move history (pieces captured during actual gameplay)
        let historyCaptured = moveHistory.compactMap { record in
            // Black captures when they move (player == .black)
            if record.player == .black, let capturedPiece = record.capturedPiece {
                return capturedPiece
            }
            return nil
        }

        captured.append(contentsOf: historyCaptured)
        return captured
    }

    /// Calculate missing pieces of a given color compared to standard starting position
    /// Used for Setup Board positions with no move history
    /// - Parameter color: Color of pieces to check
    /// - Returns: Array of pieces that are missing from standard starting position
    private func calculateMissingPieces(for color: Color) -> [Piece] {
        // Standard starting piece counts for each color
        let standardCounts: [PieceType: Int] = [
            .pawn: 8,
            .rook: 2,
            .knight: 2,
            .bishop: 2,
            .queen: 1,
            .king: 1
        ]

        // Count current pieces on board for this color
        var currentCounts: [PieceType: Int] = [
            .pawn: 0,
            .rook: 0,
            .knight: 0,
            .bishop: 0,
            .queen: 0,
            .king: 0
        ]

        // Scan board and count pieces
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = board[row][col], piece.color == color {
                    currentCounts[piece.type, default: 0] += 1
                }
            }
        }

        // Build array of missing pieces
        var missingPieces: [Piece] = []
        for (pieceType, standardCount) in standardCounts {
            let currentCount = currentCounts[pieceType] ?? 0
            let missingCount = standardCount - currentCount

            // Add missing pieces to array
            for _ in 0..<missingCount {
                missingPieces.append(Piece(type: pieceType, color: color))
            }
        }

        return missingPieces
    }

    // MARK: - Time Control Management

    /// Initialize time controls from settings
    func initializeTimeControls(whiteMinutes: Int, whiteIncrement: Int, blackMinutes: Int, blackIncrement: Int) {
        // Check if time controls are enabled (not 0/0)
        timeControlsEnabled = !(whiteMinutes == 0 && whiteIncrement == 0 && blackMinutes == 0 && blackIncrement == 0)

        if timeControlsEnabled {
            whiteTimeSeconds = whiteMinutes * 60
            blackTimeSeconds = blackMinutes * 60
            self.whiteIncrement = whiteIncrement
            self.blackIncrement = blackIncrement
            timeControlsDisabledByUndo = false
        }
    }

    /// Start the timer for the current player's move
    /// Only starts if game has been explicitly started by user
    func startMoveTimer() {
        guard timeControlsEnabled && !timeControlsDisabledByUndo && gameInProgress else { return }
        moveStartTime = Date()
    }

    /// Stop the timer and apply time deduction + increment
    /// Should be called BEFORE switching players (so currentPlayer is the player who just moved)
    func stopMoveTimer() {
        guard timeControlsEnabled && !timeControlsDisabledByUndo else { return }
        guard let startTime = moveStartTime else { return }

        // Calculate elapsed time
        let elapsed = Int(Date().timeIntervalSince(startTime))

        // Deduct time from the player who just moved (BEFORE switching)
        // and add their increment
        if currentPlayer == .white {
            whiteTimeSeconds -= elapsed
            whiteTimeSeconds += whiteIncrement
        } else {
            blackTimeSeconds -= elapsed
            blackTimeSeconds += blackIncrement
        }

        moveStartTime = nil
    }

    /// Update timer countdown (called every second)
    func updateTimer() {
        guard timeControlsEnabled && !timeControlsDisabledByUndo else { return }
        guard moveStartTime != nil else { return }

        // Trigger UI refresh to update the live countdown display
        // getCurrentTime() will calculate the current remaining time on each call
        objectWillChange.send()
    }

    /// Check if current player has run out of time
    func checkTimeForfeit() -> Bool {
        guard timeControlsEnabled && !timeControlsDisabledByUndo else { return false }
        guard let startTime = moveStartTime else { return false }

        let elapsed = Int(Date().timeIntervalSince(startTime))

        if currentPlayer == .white {
            return (whiteTimeSeconds - elapsed) <= 0
        } else {
            return (blackTimeSeconds - elapsed) <= 0
        }
    }

    /// Get current time remaining for a player (accounting for elapsed time)
    func getCurrentTime(for player: Color) -> Int {
        guard timeControlsEnabled && !timeControlsDisabledByUndo else {
            return player == .white ? whiteTimeSeconds : blackTimeSeconds
        }

        let baseTime = player == .white ? whiteTimeSeconds : blackTimeSeconds

        // If it's this player's turn and timer is running, subtract elapsed time
        if player == currentPlayer, let startTime = moveStartTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            return max(0, baseTime - elapsed)
        }

        return baseTime
    }

    // MARK: - Move Execution

    /// Execute a chess move with full game state updates
    /// Handles piece movement, captures, castling, en passant, king tracking,
    /// FEN counters, and player switching. Ported from terminal project make_move().
    /// - Parameters:
    ///   - from: Starting position of the move
    ///   - to: Destination position of the move
    /// - Returns: True if move was executed successfully, false if move is invalid
    @discardableResult
    func makeMove(from: Position, to: Position) -> Bool {
        // Validate move using MoveValidator
        guard MoveValidator.isValidMove(game: self, from: from, to: to) else {
            return false
        }

        // Get moving piece and captured piece
        let movingPiece = getPiece(at: from)
        var capturedPiece = getPiece(at: to)
        var capturedAt: Position? = nil
        var isEnPassantCapture = false
        var isCastlingMove = false

        // Check for castling move (king moves 2 squares)
        if movingPiece.type == .king && abs(to.col - from.col) == 2 {
            isCastlingMove = true
        }

        // Check for en passant capture
        if movingPiece.type == .pawn && enPassantAvailable,
           let epTarget = enPassantTarget,
           to.row == epTarget.row && to.col == epTarget.col &&
           capturedPiece.type == .empty {
            // This is an en passant capture - remove the captured pawn
            let capturedPawnRow = (movingPiece.color == .white) ? to.row + 1 : to.row - 1
            let capturedPawnPos = Position(row: capturedPawnRow, col: to.col)
            capturedPiece = getPiece(at: capturedPawnPos)
            capturedAt = capturedPawnPos
            setPiece(nil, at: capturedPawnPos)
            isEnPassantCapture = true
        }

        // Capture game state BEFORE making move (for undo and history)
        let previousState = CastlingRights(
            whiteKingMoved: whiteKingMoved,
            whiteRookKingsideMoved: whiteRookKingsideMoved,
            whiteRookQueensideMoved: whiteRookQueensideMoved,
            blackKingMoved: blackKingMoved,
            blackRookKingsideMoved: blackRookKingsideMoved,
            blackRookQueensideMoved: blackRookQueensideMoved
        )
        let previousEnPassantTarget = enPassantTarget
        let previousEnPassantAvailable = enPassantAvailable
        let previousHalfmoveClock = halfmoveClock
        let previousFullmoveNumber = fullmoveNumber

        // Determine captured piece for history (nil if empty square)
        let historyCapturedPiece = (capturedPiece.type != .empty) ? capturedPiece : nil

        // Move the piece
        setPiece(movingPiece, at: to)
        setPiece(nil, at: from)

        // Handle king moves (update flags for ANY king move)
        if movingPiece.type == .king {
            // Check if this is castling (king moves 2 squares horizontally)
            if abs(to.col - from.col) == 2 {
                // This is castling - also move the rook
                if movingPiece.color == .white {
                    if to.col == 6 {
                        // White kingside castling: move rook from h1 to f1
                        let rook = getPiece(at: Position(row: 7, col: 7))
                        setPiece(rook, at: Position(row: 7, col: 5))
                        setPiece(nil, at: Position(row: 7, col: 7))
                        whiteRookKingsideMoved = true
                    } else if to.col == 2 {
                        // White queenside castling: move rook from a1 to d1
                        let rook = getPiece(at: Position(row: 7, col: 0))
                        setPiece(rook, at: Position(row: 7, col: 3))
                        setPiece(nil, at: Position(row: 7, col: 0))
                        whiteRookQueensideMoved = true
                    }
                } else { // BLACK
                    if to.col == 6 {
                        // Black kingside castling: move rook from h8 to f8
                        let rook = getPiece(at: Position(row: 0, col: 7))
                        setPiece(rook, at: Position(row: 0, col: 5))
                        setPiece(nil, at: Position(row: 0, col: 7))
                        blackRookKingsideMoved = true
                    } else if to.col == 2 {
                        // Black queenside castling: move rook from a8 to d8
                        let rook = getPiece(at: Position(row: 0, col: 0))
                        setPiece(rook, at: Position(row: 0, col: 3))
                        setPiece(nil, at: Position(row: 0, col: 0))
                        blackRookQueensideMoved = true
                    }
                }
            }

            // Update king moved flags for ANY king move (not just castling)
            if movingPiece.color == .white {
                whiteKingMoved = true
            } else {
                blackKingMoved = true
            }
        }

        // Update rook moved flags for rook moves
        if movingPiece.type == .rook {
            if movingPiece.color == .white {
                if from.row == 7 && from.col == 0 { whiteRookQueensideMoved = true }
                if from.row == 7 && from.col == 7 { whiteRookKingsideMoved = true }
            } else {
                if from.row == 0 && from.col == 0 { blackRookQueensideMoved = true }
                if from.row == 0 && from.col == 7 { blackRookKingsideMoved = true }
            }
        }

        // Update FEN move counters according to chess rules
        let wasCapture = (capturedPiece.type != .empty || isEnPassantCapture)
        let wasPawnMove = (movingPiece.type == .pawn)

        if wasPawnMove || wasCapture {
            // Halfmove clock resets to 0 on pawn moves or captures
            halfmoveClock = 0
        } else {
            // Otherwise increment halfmove clock
            halfmoveClock += 1
        }

        // Fullmove number increments after Black's move (when switching from BLACK to WHITE)
        // Check BEFORE switching players - currentPlayer still represents who is about to move
        if currentPlayer == .black {
            fullmoveNumber += 1
        }

        // Update en passant state
        enPassantTarget = nil

        // Check if this pawn move creates an en passant opportunity
        if movingPiece.type == .pawn && abs(to.row - from.row) == 2 {
            // Pawn moved two squares, set en passant target square
            let targetRow = (from.row + to.row) / 2  // Square between from and to
            enPassantTarget = Position(row: targetRow, col: to.col)
        }

        // Stop timer for player who just moved (BEFORE switching players)
        stopMoveTimer()

        // Create move record for history (BEFORE switching player)
        let moveRecord = MoveRecord(
            from: from,
            to: to,
            piece: movingPiece,
            capturedPiece: historyCapturedPiece,
            capturedAt: capturedAt,
            wasCastling: isCastlingMove,
            wasEnPassant: isEnPassantCapture,
            wasPromotion: false,
            promotedTo: nil,
            previousCastlingRights: previousState,
            previousEnPassantTarget: previousEnPassantTarget,
            previousEnPassantAvailable: previousEnPassantAvailable,
            previousHalfmoveClock: previousHalfmoveClock,
            previousFullmoveNumber: previousFullmoveNumber,
            player: currentPlayer  // Record who made the move (before switching)
        )

        // Switch current player
        currentPlayer = currentPlayer.opposite

        // Start timer for the new player
        startMoveTimer()

        // Append to move history
        moveHistory.append(moveRecord)

        // Track last move for UI highlighting
        lastMoveFrom = from
        lastMoveTo = to

        // Check status now handled by GameStateChecker after move execution

        return true
    }

    // MARK: - Draw Rules

    /// Check if 50-move rule applies (automatic draw)
    /// Ported from terminal project chess.c:is_fifty_move_rule_draw()
    /// - Returns: True if 100 halfmoves have been made without pawn move or capture
    func isFiftyMoveRuleDraw() -> Bool {
        return halfmoveClock >= 100
    }

    // MARK: - Pawn Promotion

    /// Check if a move would result in pawn promotion
    /// Ported from terminal project chess.c:is_promotion_move()
    /// - Parameters:
    ///   - from: Starting position
    ///   - to: Destination position
    /// - Returns: True if this is a promotion move (pawn reaching opposite end)
    func isPromotionMove(from: Position, to: Position) -> Bool {
        guard let piece = board[from.row][from.col] else { return false }
        guard piece.type == .pawn else { return false }

        // White pawns promote on row 0 (rank 8)
        // Black pawns promote on row 7 (rank 1)
        let promotionRow = piece.color == .white ? 0 : 7
        return to.row == promotionRow
    }

    /// Execute pawn promotion move with specified piece
    /// Ported from terminal project chess.c:make_promotion_move()
    /// - Parameters:
    ///   - from: Starting position of pawn
    ///   - to: Destination position (promotion square)
    ///   - promotionPiece: Piece type to promote to (Queen, Rook, Bishop, or Knight)
    /// - Returns: True if promotion was executed successfully
    @discardableResult
    func makePromotionMove(from: Position, to: Position, promotionPiece: PieceType) -> Bool {
        // Validate this is actually a promotion move
        guard isPromotionMove(from: from, to: to) else {
            print("ERROR: makePromotionMove called on non-promotion move")
            return false
        }

        // Validate promotion piece (only Queen, Rook, Bishop, Knight allowed)
        guard [.queen, .rook, .bishop, .knight].contains(promotionPiece) else {
            print("ERROR: Invalid promotion piece: \(promotionPiece)")
            return false
        }

        // Validate move is legal
        guard MoveValidator.isValidMove(game: self, from: from, to: to) else {
            return false
        }

        // Get moving pawn and check for capture
        guard let movingPawn = board[from.row][from.col] else { return false }
        let capturedPiece = board[to.row][to.col]

        // Capture game state BEFORE making move (for undo and history)
        let previousState = CastlingRights(
            whiteKingMoved: whiteKingMoved,
            whiteRookKingsideMoved: whiteRookKingsideMoved,
            whiteRookQueensideMoved: whiteRookQueensideMoved,
            blackKingMoved: blackKingMoved,
            blackRookKingsideMoved: blackRookKingsideMoved,
            blackRookQueensideMoved: blackRookQueensideMoved
        )
        let previousEnPassantTarget = enPassantTarget
        let previousEnPassantAvailable = enPassantAvailable
        let previousHalfmoveClock = halfmoveClock
        let previousFullmoveNumber = fullmoveNumber

        // Move the pawn to destination
        board[to.row][to.col] = movingPawn
        board[from.row][from.col] = nil

        // Replace pawn with promoted piece
        board[to.row][to.col] = Piece(type: promotionPiece, color: movingPawn.color)

        // Update FEN counters
        // Pawn moves always reset halfmove clock
        halfmoveClock = 0

        // Fullmove number increments after Black's move
        if currentPlayer == .black {
            fullmoveNumber += 1
        }

        // Clear en passant (promotion can't create en passant)
        enPassantTarget = nil

        // Stop timer for player who just moved (BEFORE switching players)
        stopMoveTimer()

        // Create move record for history (BEFORE switching player)
        let moveRecord = MoveRecord(
            from: from,
            to: to,
            piece: movingPawn,
            capturedPiece: capturedPiece,
            capturedAt: nil,  // Promotion captures happen at destination square
            wasCastling: false,
            wasEnPassant: false,
            wasPromotion: true,
            promotedTo: promotionPiece,
            previousCastlingRights: previousState,
            previousEnPassantTarget: previousEnPassantTarget,
            previousEnPassantAvailable: previousEnPassantAvailable,
            previousHalfmoveClock: previousHalfmoveClock,
            previousFullmoveNumber: previousFullmoveNumber,
            player: currentPlayer  // Record who made the move (before switching)
        )

        // Switch current player
        currentPlayer = currentPlayer.opposite

        // Start timer for the new player
        startMoveTimer()

        // Append to move history
        moveHistory.append(moveRecord)

        // Track last move for UI highlighting
        lastMoveFrom = from
        lastMoveTo = to

        return true
    }

    // MARK: - Undo System

    /// Undo the last move, restoring complete game state
    /// Ported from terminal project undo logic
    /// - Returns: True if undo was successful, false if no moves to undo
    @discardableResult
    func undoLastMove() -> Bool {
        // Check if there are any moves to undo
        guard !moveHistory.isEmpty else {
            return false
        }

        // Disable time controls after undo (matches terminal project)
        if timeControlsEnabled && !timeControlsDisabledByUndo {
            timeControlsDisabledByUndo = true
            moveStartTime = nil
        }

        // Pop the last move from history
        let lastMove = moveHistory.removeLast()

        // Restore the moving piece to its original position
        setPiece(lastMove.piece, at: lastMove.from)

        // Handle different move types
        if lastMove.wasPromotion {
            // Promotion undo: Restore the pawn (not the promoted piece)
            setPiece(lastMove.piece, at: lastMove.from)

            // Restore captured piece if any
            if let captured = lastMove.capturedPiece {
                setPiece(captured, at: lastMove.to)
            } else {
                setPiece(nil, at: lastMove.to)
            }
        } else if lastMove.wasEnPassant {
            // En passant undo: Restore captured pawn at special location
            setPiece(nil, at: lastMove.to)  // Clear destination square
            if let capturedAt = lastMove.capturedAt, let captured = lastMove.capturedPiece {
                setPiece(captured, at: capturedAt)
            }
        } else if lastMove.wasCastling {
            // Castling undo: Also move rook back
            setPiece(nil, at: lastMove.to)  // Remove king from castled position

            // Determine which rook to move back based on king's destination
            let isKingside = lastMove.to.col > lastMove.from.col
            let rookRow = lastMove.from.row

            if isKingside {
                // Kingside castling: rook at f-file, move back to h-file
                if let rook = board[rookRow][5] {
                    setPiece(rook, at: Position(row: rookRow, col: 7))
                    setPiece(nil, at: Position(row: rookRow, col: 5))
                }
            } else {
                // Queenside castling: rook at d-file, move back to a-file
                if let rook = board[rookRow][3] {
                    setPiece(rook, at: Position(row: rookRow, col: 0))
                    setPiece(nil, at: Position(row: rookRow, col: 3))
                }
            }
        } else {
            // Normal move undo: Restore captured piece if any
            if let captured = lastMove.capturedPiece {
                setPiece(captured, at: lastMove.to)
            } else {
                setPiece(nil, at: lastMove.to)
            }
        }

        // Restore all game state from the move record
        whiteKingMoved = lastMove.previousCastlingRights.whiteKingMoved
        whiteRookKingsideMoved = lastMove.previousCastlingRights.whiteRookKingsideMoved
        whiteRookQueensideMoved = lastMove.previousCastlingRights.whiteRookQueensideMoved
        blackKingMoved = lastMove.previousCastlingRights.blackKingMoved
        blackRookKingsideMoved = lastMove.previousCastlingRights.blackRookKingsideMoved
        blackRookQueensideMoved = lastMove.previousCastlingRights.blackRookQueensideMoved

        enPassantTarget = lastMove.previousEnPassantTarget
        halfmoveClock = lastMove.previousHalfmoveClock
        fullmoveNumber = lastMove.previousFullmoveNumber

        // Restore current player (switch back to who made the move)
        currentPlayer = lastMove.player

        // Update king positions manually (setPiece might not be called if king didn't move)
        updateKingPositions()

        return true
    }

    /// Update king position tracking by scanning the board
    /// Used after undo operations to ensure king positions are accurate
    private func updateKingPositions() {
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = board[row][col], piece.type == .king {
                    let pos = Position(row: row, col: col)
                    if piece.color == .white {
                        whiteKingPos = pos
                    } else {
                        blackKingPos = pos
                    }
                }
            }
        }
    }

    // MARK: - AI Engine Management

    /// Initialize Stockfish engine with skill level from settings
    /// Ported from terminal project stockfish.c logic
    /// - Parameters:
    ///   - selectedEngine: Engine selection from settings ("human", "stockfish", etc.)
    ///   - skillLevel: Stockfish skill level (0-20)
    ///   - stockfishColor: Which color Stockfish is playing ("white" or "black")
    /// - Throws: Engine initialization errors
    func initializeEngine(selectedEngine: String, skillLevel: Int, stockfishColor: String = "black") async throws {
        // Store selected engine, skill level, and color
        self.selectedEngine = selectedEngine
        self.skillLevel = skillLevel
        self.stockfishColor = stockfishColor

        // Only initialize if Stockfish is selected
        guard selectedEngine == "stockfish" else {
            engine = nil
            return
        }

        // Shutdown any existing engine first
        await shutdownEngine()

        // Use shared Stockfish engine instance (singleton pattern)
        let sharedEngine = StockfishEngine.shared
        try await sharedEngine.initialize()
        try await sharedEngine.setSkillLevel(skillLevel)

        // Store engine reference
        engine = sharedEngine
    }

    /// Shutdown Stockfish engine with proper cleanup
    /// Ported from terminal project cleanup logic
    func shutdownEngine() async {
        guard let engine = engine else { return }

        await engine.shutdown()
        self.engine = nil
    }

    /// Get AI move from Stockfish engine
    /// Ported from terminal project stockfish.c:get_best_move()
    /// - Returns: UCI move string (e.g., "e2e4", "e7e8q" for promotion) or nil if no move available
    /// - Throws: Engine communication errors
    func getAIMove() async throws -> String? {
        guard let engine = engine else {
            print("ERROR: getAIMove called but engine is nil")
            return nil
        }

        // Convert current board to FEN string
        let fen = boardToFEN()

        // Determine time limit based on time controls
        let timeLimit: Int?
        if timeControlsEnabled && !timeControlsDisabledByUndo {
            // Time-based search: use ~1/20th of remaining time (terminal project behavior)
            let timeRemaining = getCurrentTime(for: currentPlayer)
            var moveTime = (timeRemaining * 1000) / 20  // Convert to milliseconds

            // Clamp between 500ms and 10000ms (terminal project limits)
            if moveTime < 500 { moveTime = 500 }
            if moveTime > 10000 { moveTime = 10000 }

            timeLimit = moveTime
        } else {
            // Depth-based search when time controls disabled
            timeLimit = nil
        }

        // Request best move from engine
        let move = try await engine.getBestMove(position: fen, timeLimit: timeLimit)
        return move
    }

    /// Convert current board state to FEN string
    /// Ported from terminal project stockfish.c:board_to_fen()
    /// - Returns: Complete FEN string with all 6 components
    func boardToFEN() -> String {
        var fen = ""

        // 1. Piece placement (rank by rank from rank 8 to rank 1)
        for row in 0..<8 {
            var emptyCount = 0

            for col in 0..<8 {
                if let piece = board[row][col] {
                    // Output any accumulated empty squares
                    if emptyCount > 0 {
                        fen += "\(emptyCount)"
                        emptyCount = 0
                    }

                    // Output piece character
                    fen += String(piece.fenCharacter)
                } else {
                    emptyCount += 1
                }
            }

            // Output remaining empty squares for this rank
            if emptyCount > 0 {
                fen += "\(emptyCount)"
            }

            // Add rank separator (except after rank 1)
            if row < 7 {
                fen += "/"
            }
        }

        // 2. Active color
        fen += " \(currentPlayer == .white ? "w" : "b")"

        // 3. Castling rights
        var castling = ""
        if !whiteKingMoved {
            if !whiteRookKingsideMoved { castling += "K" }
            if !whiteRookQueensideMoved { castling += "Q" }
        }
        if !blackKingMoved {
            if !blackRookKingsideMoved { castling += "k" }
            if !blackRookQueensideMoved { castling += "q" }
        }
        fen += " \(castling.isEmpty ? "-" : castling)"

        // 4. En passant target
        if let epTarget = enPassantTarget {
            fen += " \(epTarget.algebraic)"
        } else {
            fen += " -"
        }

        // 5. Halfmove clock
        fen += " \(halfmoveClock)"

        // 6. Fullmove number
        fen += " \(fullmoveNumber)"

        return fen
    }

    /// Generate PGN (Portable Game Notation) string from move history
    /// - Returns: Complete PGN with headers and move list
    func generatePGN() -> String {
        guard !moveHistory.isEmpty else {
            return "No moves played yet."
        }

        var pgn = ""

        // Add PGN headers
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let today = dateFormatter.string(from: Date())

        pgn += "[Event \"iPhone Game\"]\n"
        pgn += "[Site \"Claude Chess iOS\"]\n"
        pgn += "[Date \"\(today)\"]\n"
        pgn += "[Round \"1\"]\n"

        // Determine player names based on opponent
        let whiteName: String
        let blackName: String
        if selectedEngine == "stockfish" {
            if stockfishColor == "white" {
                whiteName = "Stockfish (Level \(skillLevel))"
                blackName = "Player"
            } else {
                whiteName = "Player"
                blackName = "Stockfish (Level \(skillLevel))"
            }
        } else {
            whiteName = "White"
            blackName = "Black"
        }

        pgn += "[White \"\(whiteName)\"]\n"
        pgn += "[Black \"\(blackName)\"]\n"

        // Game result
        let result: String
        if let winner = resignationWinner {
            // Resignation
            result = winner == "White" ? "1-0" : "0-1"
        } else if let winner = checkmateWinner {
            // Checkmate
            result = winner == .white ? "1-0" : "0-1"
        } else if gameHasEnded {
            // Draw (stalemate, 50-move rule, etc.)
            result = "1/2-1/2"
        } else {
            // Game in progress
            result = "*"
        }
        pgn += "[Result \"\(result)\"]\n"

        // Add FEN headers if game started from custom position (PGN standard)
        if let startFEN = startingFEN {
            pgn += "[SetUp \"1\"]\n"
            pgn += "[FEN \"\(startFEN)\"]\n"
        }

        pgn += "\n"

        // Add move list
        var moveNumber = 1
        for (index, move) in moveHistory.enumerated() {
            if index % 2 == 0 {
                // White's move
                pgn += "\(moveNumber). \(move.notation) "
            } else {
                // Black's move
                pgn += "\(move.notation) "
                moveNumber += 1
            }
        }

        // Add result at end
        pgn += result

        return pgn
    }

    /// Update position evaluation using Stockfish engine
    /// Ported from terminal project stockfish.c:get_position_evaluation()
    /// - Note: Sets positionEvaluation to nil if engine unavailable or evaluation fails
    func updatePositionEvaluation() async {
        // Only evaluate if Stockfish engine is available
        guard let engine = engine else {
            positionEvaluation = nil
            return
        }

        do {
            // Convert current board to FEN
            let fen = boardToFEN()

            // Request evaluation from engine (depth 15 like terminal project)
            if let eval = try await engine.evaluatePosition(position: fen) {
                positionEvaluation = eval
            } else {
                positionEvaluation = nil
            }
        } catch {
            print("ERROR: Position evaluation failed: \(error)")
            positionEvaluation = nil
        }
    }

    /// Request hint move from Stockfish engine
    /// Ported from terminal project stockfish.c:get_hint_move()
    /// Uses fast depth-based search to avoid consuming user's time during hints
    /// - Note: Sets currentHint to nil if engine unavailable or hint fails
    func requestHint() async {
        // Only provide hints if Stockfish engine is available
        guard let engine = engine else {
            currentHint = nil
            return
        }

        do {
            // Convert current board to FEN
            let fen = boardToFEN()

            // Request hint from engine (fast search, no time limit - depth-based)
            // Terminal project uses depth-based search for hints to avoid burning user time
            if let hint = try await engine.getHint(position: fen) {
                currentHint = hint
            } else {
                currentHint = nil
            }
        } catch {
            print("ERROR: Hint request failed: \(error)")
            currentHint = nil
        }
    }

    /// Offer draw to AI opponent and get response based on position evaluation
    /// AI accepts draw only when losing badly, declines when equal or better
    /// Threshold scales with skill level: weaker AI more willing to accept draws when losing
    /// - Returns: True if AI accepts draw, false if AI declines
    func offerDraw() async -> Bool {
        // Only offer draw if playing against AI
        guard let engine = engine else {
            return false
        }

        do {
            // Get current position evaluation from Stockfish
            let fen = boardToFEN()

            guard let evaluation = try await engine.evaluatePosition(position: fen) else {
                return false
            }

            // UCI evaluations are always from White's perspective
            // Stockfish plays Black, so flip the sign to get Black's perspective
            // Positive White eval = Negative Black eval (Black losing)
            // Negative White eval = Positive Black eval (Black winning)
            let blackEvaluation = -evaluation

            // Skill-aware threshold: lower skill = more willing to accept draws when losing
            // Skill 5 = -150cp (losing by ~1.5 pawns), Skill 20 = -300cp (losing by ~3 pawns)
            let acceptThreshold = -(100 + (skillLevel * 10))

            // Accept draw ONLY if Stockfish (Black) is losing badly (negative evaluation below threshold)
            // Examples:
            //   White eval = +575cp → Black eval = -575cp → ACCEPT (Black losing badly)
            //   White eval = -575cp → Black eval = +575cp → DECLINE (Black winning)
            //   White eval = 0cp → Black eval = 0cp → DECLINE (equal, not losing badly)
            //   White eval = +100cp → Black eval = -100cp → DECLINE for skill 5 (not losing badly enough)
            return blackEvaluation < acceptThreshold
        } catch {
            print("ERROR: Draw offer evaluation failed: \(error)")
            return false
        }
    }

    /// Parse UCI move string and execute on board
    /// Ported from terminal project stockfish.c:parse_move_string()
    /// - Parameter uciMove: UCI move string (e.g., "e2e4", "e7e8q" for promotion)
    /// - Returns: True if move was successfully parsed and executed
    @discardableResult
    func executeAIMove(_ uciMove: String) async -> Bool {
        guard uciMove.count >= 4 else {
            print("ERROR: Invalid UCI move string: \(uciMove)")
            return false
        }

        // Parse from/to positions
        let fromAlg = String(uciMove.prefix(2))
        let toAlg = String(uciMove.dropFirst(2).prefix(2))

        guard let from = Position(algebraic: fromAlg),
              let to = Position(algebraic: toAlg) else {
            print("ERROR: Could not parse UCI positions: \(fromAlg) to \(toAlg)")
            return false
        }

        // Check for promotion (5-character move like "e7e8q")
        if uciMove.count == 5 {
            let promotionChar = uciMove.last!

            // Map UCI promotion character to PieceType
            let promotionPiece: PieceType
            switch promotionChar.lowercased() {
            case "q": promotionPiece = .queen
            case "r": promotionPiece = .rook
            case "b": promotionPiece = .bishop
            case "n": promotionPiece = .knight
            default:
                print("ERROR: Invalid promotion character: \(promotionChar)")
                return false
            }

            // Execute promotion move (AI doesn't show picker)
            return makePromotionMove(from: from, to: to, promotionPiece: promotionPiece)
        } else {
            // Regular move
            return makeMove(from: from, to: to)
        }
    }
}
