//
//  Piece.swift
//  Claude_Chess
//
//  Chess piece representation combining type and color
//

import Foundation

/// Represents a chess piece with its type and color
struct Piece: Equatable, Hashable, Codable {
    /// The type of the piece (pawn, rook, knight, etc.)
    let type: PieceType

    /// The color of the piece (white or black)
    let color: Color

    /// Creates a new chess piece
    /// - Parameters:
    ///   - type: The type of the piece
    ///   - color: The color of the piece
    init(type: PieceType, color: Color) {
        self.type = type
        self.color = color
    }

    /// Creates a piece from a FEN character
    /// - Parameter fenCharacter: FEN character (uppercase = white, lowercase = black)
    /// - Returns: Piece if valid FEN character, nil otherwise
    init?(fenCharacter: Character) {
        let upperChar = fenCharacter.uppercased().first!

        let pieceType: PieceType?
        switch upperChar {
        case "K": pieceType = .king
        case "Q": pieceType = .queen
        case "R": pieceType = .rook
        case "B": pieceType = .bishop
        case "N": pieceType = .knight
        case "P": pieceType = .pawn
        default: pieceType = nil
        }

        guard let type = pieceType else { return nil }

        self.type = type
        self.color = fenCharacter.isUppercase ? .white : .black
    }

    /// Returns the Unicode symbol for this piece
    var symbol: String {
        type.symbol(for: color)
    }

    /// Returns the FEN character for this piece
    var fenCharacter: Character {
        type.fenCharacter(for: color)
    }

    /// Returns a descriptive name for the piece (e.g., "White Queen")
    var displayName: String {
        "\(color.displayName) \(type.displayName)"
    }
}
