//
//  MoveValidator.swift
//  Claude_Chess
//
//  Move generation and validation logic
//  Ported from terminal project's chess.c move generation functions
//

import Foundation

/// Information about a possible move including capture status
struct MoveInfo {
    let destination: Position
    let isCapture: Bool
    let capturedPiece: Piece?
}

/// Move validation and generation system
/// Ports the core chess logic from the terminal project
class MoveValidator {

    // MARK: - Public Interface

    /// Get all legal moves for a piece at the given position
    /// - Parameters:
    ///   - game: Current game state
    ///   - from: Position of piece to analyze
    /// - Returns: Array of MoveInfo describing all legal moves
    static func getPossibleMovesWithCaptures(game: ChessGame, from: Position) -> [MoveInfo] {
        guard game.isValidPosition(from) else { return [] }

        let piece = game.getPiece(at: from)
        guard piece.type != .empty else { return [] }

        var moves: [Position] = []

        // Generate moves based on piece type
        switch piece.type {
        case .pawn:
            moves = getPawnMoves(game: game, from: from)
        case .rook:
            moves = getRookMoves(game: game, from: from)
        case .bishop:
            moves = getBishopMoves(game: game, from: from)
        case .knight:
            moves = getKnightMoves(game: game, from: from)
        case .queen:
            moves = getQueenMoves(game: game, from: from)
        case .king:
            moves = getKingMoves(game: game, from: from)
        case .empty:
            break
        }

        // Convert to MoveInfo with capture detection
        return moves.map { destination in
            let targetPiece = game.getPiece(at: destination)
            let isCapture = targetPiece.type != .empty
            return MoveInfo(
                destination: destination,
                isCapture: isCapture,
                capturedPiece: isCapture ? targetPiece : nil
            )
        }
    }

    /// Check if a specific move is valid
    /// - Parameters:
    ///   - game: Current game state
    ///   - from: Starting position
    ///   - to: Destination position
    /// - Returns: True if move is legal (doesn't leave own king in check)
    /// Ported from terminal project chess.c:876-887
    static func isValidMove(game: ChessGame, from: Position, to: Position) -> Bool {
        // First check if the move is pseudo-legal (valid piece movement)
        let possibleMoves = getPossibleMovesWithCaptures(game: game, from: from)
        guard possibleMoves.contains(where: { $0.destination == to }) else {
            return false
        }

        // Check if move would leave king in check
        return !wouldBeInCheckAfterMove(game: game, from: from, to: to)
    }

    /// Simulate a move and check if it would leave the moving player's king in check
    /// Ported from terminal project chess.c:834-863
    ///
    /// NOTE: This creates a temporary test board to avoid triggering @Published updates
    /// on the original game during validation loops
    private static func wouldBeInCheckAfterMove(game: ChessGame, from: Position, to: Position) -> Bool {
        let movingPiece = game.getPiece(at: from)

        // Create a temporary copy of the board for testing
        var testBoard = game.board
        var testWhiteKingPos = game.whiteKingPos
        var testBlackKingPos = game.blackKingPos

        // Simulate the move on the test board
        testBoard[to.row][to.col] = movingPiece
        testBoard[from.row][from.col] = Piece(type: .empty, color: .white)

        // Update king position if king moved
        if movingPiece.type == .king {
            if movingPiece.color == .white {
                testWhiteKingPos = to
            } else {
                testBlackKingPos = to
            }
        }

        // Check if this leaves the king in check by temporarily creating a test game state
        // We need to check without modifying the original game's @Published properties
        let testGame = ChessGame()
        testGame.board = testBoard
        testGame.whiteKingPos = testWhiteKingPos
        testGame.blackKingPos = testBlackKingPos
        testGame.currentPlayer = game.currentPlayer

        let inCheck = GameStateChecker.isInCheck(game: testGame, color: movingPiece.color)

        return inCheck
    }

    // MARK: - Piece-Specific Move Generation

    /// Generate all possible pawn moves including captures and en passant
    private static func getPawnMoves(game: ChessGame, from: Position) -> [Position] {
        var moves: [Position] = []
        let piece = game.getPiece(at: from)

        // Pawn direction: White moves up (decreasing row), Black moves down (increasing row)
        let direction = piece.color == .white ? -1 : 1
        let startRow = piece.color == .white ? 6 : 1  // Starting row for two-square move

        // Forward move (one square)
        let oneForward = Position(row: from.row + direction, col: from.col)
        if game.isValidPosition(oneForward) && game.getPiece(at: oneForward).type == .empty {
            moves.append(oneForward)

            // Forward move (two squares from starting position)
            if from.row == startRow {
                let twoForward = Position(row: from.row + (direction * 2), col: from.col)
                if game.getPiece(at: twoForward).type == .empty {
                    moves.append(twoForward)
                }
            }
        }

        // Diagonal captures
        for colOffset in [-1, 1] {
            let capturePos = Position(row: from.row + direction, col: from.col + colOffset)
            if game.isValidPosition(capturePos) {
                let targetPiece = game.getPiece(at: capturePos)

                // Regular capture
                if targetPiece.type != .empty && targetPiece.color != piece.color {
                    moves.append(capturePos)
                }

                // En passant capture
                if game.enPassantAvailable && capturePos == game.enPassantTarget {
                    moves.append(capturePos)
                }
            }
        }

        return moves
    }

    /// Generate all possible rook moves (sliding horizontally and vertically)
    private static func getRookMoves(game: ChessGame, from: Position) -> [Position] {
        var moves: [Position] = []
        let piece = game.getPiece(at: from)

        // Four directions: up, down, left, right
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        for (dRow, dCol) in directions {
            var row = from.row + dRow
            var col = from.col + dCol

            // Slide until we hit edge or another piece
            while game.isValidPosition(Position(row: row, col: col)) {
                let pos = Position(row: row, col: col)
                let targetPiece = game.getPiece(at: pos)

                if targetPiece.type == .empty {
                    moves.append(pos)
                } else {
                    // Can capture opponent piece
                    if targetPiece.color != piece.color {
                        moves.append(pos)
                    }
                    break  // Can't move past any piece
                }

                row += dRow
                col += dCol
            }
        }

        return moves
    }

    /// Generate all possible bishop moves (sliding diagonally)
    private static func getBishopMoves(game: ChessGame, from: Position) -> [Position] {
        var moves: [Position] = []
        let piece = game.getPiece(at: from)

        // Four diagonal directions
        let directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]

        for (dRow, dCol) in directions {
            var row = from.row + dRow
            var col = from.col + dCol

            // Slide until we hit edge or another piece
            while game.isValidPosition(Position(row: row, col: col)) {
                let pos = Position(row: row, col: col)
                let targetPiece = game.getPiece(at: pos)

                if targetPiece.type == .empty {
                    moves.append(pos)
                } else {
                    // Can capture opponent piece
                    if targetPiece.color != piece.color {
                        moves.append(pos)
                    }
                    break  // Can't move past any piece
                }

                row += dRow
                col += dCol
            }
        }

        return moves
    }

    /// Generate all possible knight moves (L-shaped jumps)
    private static func getKnightMoves(game: ChessGame, from: Position) -> [Position] {
        var moves: [Position] = []
        let piece = game.getPiece(at: from)

        // All eight possible knight move offsets
        let offsets = [
            (-2, -1), (-2, 1), (-1, -2), (-1, 2),
            (1, -2), (1, 2), (2, -1), (2, 1)
        ]

        for (dRow, dCol) in offsets {
            let pos = Position(row: from.row + dRow, col: from.col + dCol)
            if game.isValidPosition(pos) {
                let targetPiece = game.getPiece(at: pos)
                // Can move to empty square or capture opponent piece
                if targetPiece.type == .empty || targetPiece.color != piece.color {
                    moves.append(pos)
                }
            }
        }

        return moves
    }

    /// Generate all possible queen moves (combination of rook and bishop)
    private static func getQueenMoves(game: ChessGame, from: Position) -> [Position] {
        // Queen combines rook and bishop movement
        var moves = getRookMoves(game: game, from: from)
        moves.append(contentsOf: getBishopMoves(game: game, from: from))
        return moves
    }

    /// Generate all possible king moves including castling
    /// Ported from terminal project chess.c:682-726
    private static func getKingMoves(game: ChessGame, from: Position) -> [Position] {
        var moves: [Position] = []
        let piece = game.getPiece(at: from)

        // All eight adjacent squares
        let offsets = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),           (0, 1),
            (1, -1),  (1, 0),  (1, 1)
        ]

        for (dRow, dCol) in offsets {
            let pos = Position(row: from.row + dRow, col: from.col + dCol)
            if game.isValidPosition(pos) {
                let targetPiece = game.getPiece(at: pos)
                // Can move to empty square or capture opponent piece
                if targetPiece.type == .empty || targetPiece.color != piece.color {
                    moves.append(pos)
                }
            }
        }

        // Castling moves (ported from terminal project chess.c:682-726)
        // TODO Phase 3: Add check detection to prevent castling while in check
        // TODO Phase 3: Add is_square_attacked() checks for squares king moves through

        if piece.color == .white {
            // White kingside castling (king moves to g1)
            if !game.whiteKingMoved && !game.whiteRookKingsideMoved &&
               from.row == 7 && from.col == 4 && // King is on e1
               game.getPiece(at: Position(row: 7, col: 5)).type == .empty && // f1 empty
               game.getPiece(at: Position(row: 7, col: 6)).type == .empty {  // g1 empty
                moves.append(Position(row: 7, col: 6)) // g1
            }

            // White queenside castling (king moves to c1)
            if !game.whiteKingMoved && !game.whiteRookQueensideMoved &&
               from.row == 7 && from.col == 4 && // King is on e1
               game.getPiece(at: Position(row: 7, col: 1)).type == .empty && // b1 empty
               game.getPiece(at: Position(row: 7, col: 2)).type == .empty && // c1 empty
               game.getPiece(at: Position(row: 7, col: 3)).type == .empty {  // d1 empty
                moves.append(Position(row: 7, col: 2)) // c1
            }
        } else { // BLACK
            // Black kingside castling (king moves to g8)
            if !game.blackKingMoved && !game.blackRookKingsideMoved &&
               from.row == 0 && from.col == 4 && // King is on e8
               game.getPiece(at: Position(row: 0, col: 5)).type == .empty && // f8 empty
               game.getPiece(at: Position(row: 0, col: 6)).type == .empty {  // g8 empty
                moves.append(Position(row: 0, col: 6)) // g8
            }

            // Black queenside castling (king moves to c8)
            if !game.blackKingMoved && !game.blackRookQueensideMoved &&
               from.row == 0 && from.col == 4 && // King is on e8
               game.getPiece(at: Position(row: 0, col: 1)).type == .empty && // b8 empty
               game.getPiece(at: Position(row: 0, col: 2)).type == .empty && // c8 empty
               game.getPiece(at: Position(row: 0, col: 3)).type == .empty {  // d8 empty
                moves.append(Position(row: 0, col: 2)) // c8
            }
        }

        return moves
    }

    /// Generate king moves WITHOUT castling logic
    /// Used by GameStateChecker to prevent infinite recursion when checking if squares are attacked
    /// Ported from terminal project chess.c get_king_moves_no_castling()
    static func getKingMovesNoCastling(game: ChessGame, from: Position) -> [MoveInfo] {
        var moves: [Position] = []
        let piece = game.getPiece(at: from)

        // All eight adjacent squares
        let offsets = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),           (0, 1),
            (1, -1),  (1, 0),  (1, 1)
        ]

        for (dRow, dCol) in offsets {
            let pos = Position(row: from.row + dRow, col: from.col + dCol)
            if game.isValidPosition(pos) {
                let targetPiece = game.getPiece(at: pos)
                // Can move to empty square or capture opponent piece
                if targetPiece.type == .empty || targetPiece.color != piece.color {
                    moves.append(pos)
                }
            }
        }

        // Convert to MoveInfo with capture detection
        return moves.map { destination in
            let targetPiece = game.getPiece(at: destination)
            let isCapture = targetPiece.type != .empty
            return MoveInfo(
                destination: destination,
                isCapture: isCapture,
                capturedPiece: isCapture ? targetPiece : nil
            )
        }
    }
}
