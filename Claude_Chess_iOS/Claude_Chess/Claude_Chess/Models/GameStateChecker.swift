//
//  GameStateChecker.swift
//  Claude_Chess
//
//  Game state analysis for check, checkmate, and stalemate detection.
//  Ported from terminal project's main.c and chess.c implementations.
//

import Foundation

/// Game state analysis functions for detecting check, checkmate, and stalemate conditions
struct GameStateChecker {

    /// Check if a square is attacked by any piece of the specified color
    /// Used to determine if a king is in check or if castling is safe
    ///
    /// - Parameters:
    ///   - game: Current game state
    ///   - position: Square to check for attacks
    ///   - byColor: Color of attacking pieces to check
    /// - Returns: true if square is attacked by the specified color
    static func isSquareAttacked(game: ChessGame, position: Position, byColor: Color) -> Bool {
        // Check all squares on the board
        for row in 0..<8 {
            for col in 0..<8 {
                let piece = game.getPiece(at: Position(row: row, col: col))

                // If there's a piece of the attacking color
                if piece.type != .empty && piece.color == byColor {
                    let piecePosition = Position(row: row, col: col)

                    // Get all possible moves for this piece
                    // Note: For king pieces, we need special handling to avoid infinite recursion
                    let moves: [MoveInfo]
                    if piece.type == .king {
                        // For king, only check non-castling moves to avoid recursion
                        moves = MoveValidator.getKingMovesNoCastling(game: game, from: piecePosition)
                    } else {
                        moves = MoveValidator.getPossibleMovesWithCaptures(game: game, from: piecePosition)
                    }

                    // Check if any move targets the position in question
                    for move in moves {
                        if move.destination == position {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }

    /// Check if the specified color's king is currently in check
    ///
    /// - Parameters:
    ///   - game: Current game state
    ///   - color: Color of king to check
    /// - Returns: true if the king is in check
    static func isInCheck(game: ChessGame, color: Color) -> Bool {
        let kingPos = (color == .white) ? game.whiteKingPos : game.blackKingPos
        let attackingColor: Color = (color == .white) ? .black : .white
        return isSquareAttacked(game: game, position: kingPos, byColor: attackingColor)
    }

    /// Check if a player has any legal moves available
    /// A legal move is one that doesn't leave the player's king in check
    ///
    /// - Parameters:
    ///   - game: Current game state
    ///   - color: Color of player to check
    /// - Returns: true if player has at least one legal move
    static func hasLegalMoves(game: ChessGame, color: Color) -> Bool {
        // Check all squares on the board
        for row in 0..<8 {
            for col in 0..<8 {
                let piece = game.getPiece(at: Position(row: row, col: col))

                // If there's a piece of the specified color
                if piece.type != .empty && piece.color == color {
                    let fromPos = Position(row: row, col: col)

                    // Get all possible moves for this piece
                    let moves = MoveValidator.getPossibleMovesWithCaptures(game: game, from: fromPos)

                    // Check if any move is legal (doesn't leave king in check)
                    for move in moves {
                        if MoveValidator.isValidMove(game: game, from: fromPos, to: move.destination) {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }

    /// Check if a player is in checkmate
    /// Checkmate occurs when the king is in check and has no legal moves to escape
    ///
    /// - Parameters:
    ///   - game: Current game state
    ///   - color: Color of player to check
    /// - Returns: true if player is in checkmate
    static func isCheckmate(game: ChessGame, color: Color) -> Bool {
        return isInCheck(game: game, color: color) && !hasLegalMoves(game: game, color: color)
    }

    /// Check if a player is in stalemate
    /// Stalemate occurs when the player is NOT in check but has no legal moves
    /// Results in a draw
    ///
    /// - Parameters:
    ///   - game: Current game state
    ///   - color: Color of player to check
    /// - Returns: true if player is in stalemate
    static func isStalemate(game: ChessGame, color: Color) -> Bool {
        return !isInCheck(game: game, color: color) && !hasLegalMoves(game: game, color: color)
    }
}
