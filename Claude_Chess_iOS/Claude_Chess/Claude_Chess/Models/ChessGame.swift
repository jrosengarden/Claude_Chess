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
        var isEnPassantCapture = false

        // Check for en passant capture
        if movingPiece.type == .pawn && enPassantAvailable,
           let epTarget = enPassantTarget,
           to.row == epTarget.row && to.col == epTarget.col &&
           capturedPiece.type == .empty {
            // This is an en passant capture - remove the captured pawn
            let capturedPawnRow = (movingPiece.color == .white) ? to.row + 1 : to.row - 1
            capturedPiece = getPiece(at: Position(row: capturedPawnRow, col: to.col))
            setPiece(nil, at: Position(row: capturedPawnRow, col: to.col))
            isEnPassantCapture = true
        }

        // TODO: Track captured pieces for display (Phase 3)
        // if capturedPiece.type != .empty {
        //     // Add to captured pieces array
        // }

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

        // Switch current player
        currentPlayer = currentPlayer.opposite

        // TODO: Update check status (Phase 2 - check detection)
        // game.inCheck[.white] = isInCheck(color: .white)
        // game.inCheck[.black] = isInCheck(color: .black)

        return true
    }
}
