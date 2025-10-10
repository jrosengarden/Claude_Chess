//
//  PieceType.swift
//  Claude_Chess
//
//  Chess piece type enumeration
//

import Foundation

/// Represents the type of a chess piece
enum PieceType: String, CaseIterable, Codable {
    case empty   // Represents an empty square
    case pawn
    case rook
    case knight
    case bishop
    case queen
    case king

    /// Returns the Unicode symbol for the piece (for UI display)
    /// - Parameter color: The color of the piece
    /// - Returns: Unicode chess piece symbol
    func symbol(for color: Color) -> String {
        switch (self, color) {
        case (.empty, _):       return " "
        case (.king, .white):   return "♔"
        case (.queen, .white):  return "♕"
        case (.rook, .white):   return "♖"
        case (.bishop, .white): return "♗"
        case (.knight, .white): return "♘"
        case (.pawn, .white):   return "♙"
        case (.king, .black):   return "♚"
        case (.queen, .black):  return "♛"
        case (.rook, .black):   return "♜"
        case (.bishop, .black): return "♝"
        case (.knight, .black): return "♞"
        case (.pawn, .black):   return "♟"
        }
    }

    /// Returns the asset image name for the piece (Cburnett SVG style)
    /// - Parameter color: The color of the piece
    /// - Returns: Asset name matching the Wikimedia Commons Cburnett naming, or empty string for empty squares
    func assetName(for color: Color) -> String {
        let pieceCode: String
        switch self {
        case .empty:  return ""  // No asset for empty squares
        case .king:   pieceCode = "k"
        case .queen:  pieceCode = "q"
        case .rook:   pieceCode = "r"
        case .bishop: pieceCode = "b"
        case .knight: pieceCode = "n"
        case .pawn:   pieceCode = "p"
        }

        let colorCode = color == .white ? "l" : "d"
        return "Chess_\(pieceCode)\(colorCode)t45"
    }

    /// Returns the FEN character representation of the piece
    /// - Parameter color: The color of the piece
    /// - Returns: FEN character (uppercase for white, lowercase for black), or space for empty
    func fenCharacter(for color: Color) -> Character {
        let char: Character
        switch self {
        case .empty:  return " "  // Empty square
        case .king:   char = "K"
        case .queen:  char = "Q"
        case .rook:   char = "R"
        case .bishop: char = "B"
        case .knight: char = "N"
        case .pawn:   char = "P"
        }
        return color == .white ? char : Character(char.lowercased())
    }

    /// Returns display name with capitalization
    var displayName: String {
        rawValue.capitalized
    }
}
