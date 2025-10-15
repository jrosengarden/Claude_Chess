//
//  MoveRecord.swift
//  Claude_Chess
//
//
//  Move history tracking for undo functionality and PGN generation.
//  Records complete move information and game state for perfect restoration.
//

import Foundation

/// Records a single move with all information needed for undo and notation
struct MoveRecord {
    // MARK: - Move Information

    /// Starting position of the piece
    let from: Position

    /// Ending position of the piece
    let to: Position

    /// The piece that moved
    let piece: Piece

    /// Piece captured by this move (nil if no capture)
    let capturedPiece: Piece?

    /// Position where piece was captured (differs from 'to' only for en passant)
    let capturedAt: Position?

    // MARK: - Special Move Flags

    /// True if this move was a castling move
    let wasCastling: Bool

    /// True if this move was an en passant capture
    let wasEnPassant: Bool

    /// True if this move was a pawn promotion
    let wasPromotion: Bool

    /// Piece type the pawn was promoted to (nil if not a promotion)
    let promotedTo: PieceType?

    // MARK: - Game State Snapshot (for Undo)

    /// Castling rights before this move (needed for undo)
    let previousCastlingRights: CastlingRights

    /// En passant target square before this move
    let previousEnPassantTarget: Position?

    /// Whether en passant was available before this move
    let previousEnPassantAvailable: Bool

    /// Halfmove clock value before this move
    let previousHalfmoveClock: Int

    /// Fullmove number before this move
    let previousFullmoveNumber: Int

    /// Player who made this move
    let player: Color

    // MARK: - Initialization

    /// Create a move record capturing complete game state
    /// - Parameters:
    ///   - from: Starting position
    ///   - to: Ending position
    ///   - piece: Piece that moved
    ///   - capturedPiece: Piece captured (if any)
    ///   - capturedAt: Position where capture occurred (for en passant)
    ///   - wasCastling: Whether this was a castling move
    ///   - wasEnPassant: Whether this was en passant capture
    ///   - wasPromotion: Whether this was pawn promotion
    ///   - promotedTo: Piece type promoted to (if applicable)
    ///   - previousCastlingRights: Castling rights before move
    ///   - previousEnPassantTarget: En passant target before move
    ///   - previousEnPassantAvailable: En passant availability before move
    ///   - previousHalfmoveClock: Halfmove clock before move
    ///   - previousFullmoveNumber: Fullmove number before move
    ///   - player: Player making the move
    init(
        from: Position,
        to: Position,
        piece: Piece,
        capturedPiece: Piece? = nil,
        capturedAt: Position? = nil,
        wasCastling: Bool = false,
        wasEnPassant: Bool = false,
        wasPromotion: Bool = false,
        promotedTo: PieceType? = nil,
        previousCastlingRights: CastlingRights,
        previousEnPassantTarget: Position?,
        previousEnPassantAvailable: Bool,
        previousHalfmoveClock: Int,
        previousFullmoveNumber: Int,
        player: Color
    ) {
        self.from = from
        self.to = to
        self.piece = piece
        self.capturedPiece = capturedPiece
        self.capturedAt = capturedAt
        self.wasCastling = wasCastling
        self.wasEnPassant = wasEnPassant
        self.wasPromotion = wasPromotion
        self.promotedTo = promotedTo
        self.previousCastlingRights = previousCastlingRights
        self.previousEnPassantTarget = previousEnPassantTarget
        self.previousEnPassantAvailable = previousEnPassantAvailable
        self.previousHalfmoveClock = previousHalfmoveClock
        self.previousFullmoveNumber = previousFullmoveNumber
        self.player = player
    }

    // MARK: - Algebraic Notation

    /// Generate algebraic notation for this move (e.g., "e4", "Nf3", "O-O", "e8=Q")
    var notation: String {
        // Castling notation
        if wasCastling {
            // Kingside castling (king moves right)
            if to.col > from.col {
                return "O-O"
            } else {
                // Queenside castling (king moves left)
                return "O-O-O"
            }
        }

        var result = ""

        // Piece prefix (except for pawns)
        if piece.type != .pawn {
            result += piece.type.notation
        }

        // Starting square (for disambiguation - simplified for now)
        result += from.algebraic

        // Capture indicator
        if capturedPiece != nil {
            result += "x"
        } else {
            result += "-"
        }

        // Destination square
        result += to.algebraic

        // Promotion
        if wasPromotion, let promotedType = promotedTo {
            result += "=\(promotedType.notation)"
        }

        // En passant indicator
        if wasEnPassant {
            result += " e.p."
        }

        return result
    }
}

// MARK: - CastlingRights Helper Struct

/// Captures all castling rights at a point in time
struct CastlingRights: Equatable {
    var whiteKingMoved: Bool
    var whiteRookKingsideMoved: Bool
    var whiteRookQueensideMoved: Bool
    var blackKingMoved: Bool
    var blackRookKingsideMoved: Bool
    var blackRookQueensideMoved: Bool

    /// Create castling rights snapshot from game state
    init(
        whiteKingMoved: Bool,
        whiteRookKingsideMoved: Bool,
        whiteRookQueensideMoved: Bool,
        blackKingMoved: Bool,
        blackRookKingsideMoved: Bool,
        blackRookQueensideMoved: Bool
    ) {
        self.whiteKingMoved = whiteKingMoved
        self.whiteRookKingsideMoved = whiteRookKingsideMoved
        self.whiteRookQueensideMoved = whiteRookQueensideMoved
        self.blackKingMoved = blackKingMoved
        self.blackRookKingsideMoved = blackRookKingsideMoved
        self.blackRookQueensideMoved = blackRookQueensideMoved
    }
}

// MARK: - PieceType Notation Extension

extension PieceType {
    /// Standard algebraic notation for piece type
    var notation: String {
        switch self {
        case .king: return "K"
        case .queen: return "Q"
        case .rook: return "R"
        case .bishop: return "B"
        case .knight: return "N"
        case .pawn: return ""  // Pawns have no prefix
        case .empty: return ""  // Empty squares have no notation
        }
    }
}
