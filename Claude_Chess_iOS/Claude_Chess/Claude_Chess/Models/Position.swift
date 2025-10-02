//
//  Position.swift
//  Claude_Chess
//
//  Chess board position representation
//

import Foundation

/// Represents a position on the chess board
struct Position: Equatable, Hashable, Codable {
    /// Row index (0-7, where 0 is rank 8 and 7 is rank 1)
    let row: Int

    /// Column index (0-7, where 0 is file 'a' and 7 is file 'h')
    let col: Int

    /// Creates a new position with validation
    /// - Parameters:
    ///   - row: Row index (0-7)
    ///   - col: Column index (0-7)
    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    /// Creates a position from algebraic notation (e.g., "e4", "a1")
    /// - Parameter algebraic: Algebraic notation string
    /// - Returns: Position if valid, nil otherwise
    init?(algebraic: String) {
        guard algebraic.count == 2 else { return nil }

        let chars = Array(algebraic.lowercased())
        guard let file = chars[0].asciiValue,
              let rankChar = chars[1].asciiValue else { return nil }

        // File: 'a' = 0, 'b' = 1, ..., 'h' = 7
        let col = Int(file) - Int(Character("a").asciiValue!)
        guard col >= 0 && col < 8 else { return nil }

        // Rank: '1' = row 7, '2' = row 6, ..., '8' = row 0
        let rank = Int(rankChar) - Int(Character("1").asciiValue!)
        guard rank >= 0 && rank < 8 else { return nil }
        let row = 7 - rank

        self.row = row
        self.col = col
    }

    /// Returns true if the position is within board bounds
    var isValid: Bool {
        row >= 0 && row < 8 && col >= 0 && col < 8
    }

    /// Returns algebraic notation for this position (e.g., "e4")
    var algebraic: String {
        let file = Character(UnicodeScalar(UInt8(col) + UInt8(ascii: "a")))
        let rank = 8 - row
        return "\(file)\(rank)"
    }

    /// Returns the rank number (1-8)
    var rank: Int {
        8 - row
    }

    /// Returns the file letter ('a'-'h')
    var file: Character {
        Character(UnicodeScalar(UInt8(col) + UInt8(ascii: "a")))
    }
}
