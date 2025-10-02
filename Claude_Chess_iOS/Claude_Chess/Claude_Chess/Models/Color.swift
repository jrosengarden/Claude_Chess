//
//  Color.swift
//  Claude_Chess
//
//  Chess piece color enumeration
//

import Foundation

/// Represents the color of a chess piece or player
enum Color: String, CaseIterable, Codable {
    case white
    case black

    /// Returns the opposite color
    var opposite: Color {
        switch self {
        case .white: return .black
        case .black: return .white
        }
    }

    /// Returns display name with capitalization
    var displayName: String {
        rawValue.capitalized
    }
}
