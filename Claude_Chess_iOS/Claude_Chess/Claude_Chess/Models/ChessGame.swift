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

    /// Reset game to starting position
    /// Clears the board and reinitializes to standard chess starting position
    func resetGame() {
        setupInitialPosition()
        // Increment reset trigger to notify UI to clear selection state
        resetTrigger += 1
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

    /// Get all pieces captured by White (from move history)
    var capturedByWhite: [Piece] {
        return moveHistory.compactMap { record in
            // White captures when they move (player == .white)
            if record.player == .white, let captured = record.capturedPiece {
                return captured
            }
            return nil
        }
    }

    /// Get all pieces captured by Black (from move history)
    var capturedByBlack: [Piece] {
        return moveHistory.compactMap { record in
            // Black captures when they move (player == .black)
            if record.player == .black, let captured = record.capturedPiece {
                return captured
            }
            return nil
        }
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

        // Append to move history
        moveHistory.append(moveRecord)

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
        let isCapture = capturedPiece != nil

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

        // Append to move history
        moveHistory.append(moveRecord)

        print("Promotion: \(movingPawn.color.displayName) pawn at \(from.algebraic) promoted to \(promotionPiece.displayName) at \(to.algebraic)")
        if isCapture {
            print("  Captured: \(capturedPiece?.type.displayName ?? "unknown")")
        }

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
}
