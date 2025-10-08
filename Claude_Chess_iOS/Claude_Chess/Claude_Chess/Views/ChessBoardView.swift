//
//  ChessBoardView.swift
//  Claude_Chess
//
//  Chess board visual representation with 8x8 grid
//

import SwiftUI

// Chess board color scheme
fileprivate let lightSquareColor = SwiftUI.Color(
    red: 0.93,
    green: 0.85,
    blue: 0.71
)

fileprivate let darkSquareColor = SwiftUI.Color(
    red: 0.72,
    green: 0.53,
    blue: 0.30
)

/// Visual representation of a chess board with alternating light/dark squares
/// and piece placement
struct ChessBoardView: View {
    // Chess board dimensions
    private let rows = 8
    private let columns = 8

    // Optional: pass in board state (for now, we'll start with empty)
    var board: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8),
                                   count: 8)

    var body: some View {
        GeometryReader { geometry in
            // Calculate square size to fit the board in available space
            let squareSize = min(geometry.size.width, geometry.size.height) / 8

            VStack(spacing: 0) {
                // Iterate through rows (rank 8 to rank 1)
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        // Iterate through columns (file a to file h)
                        ForEach(0..<columns, id: \.self) { col in
                            ChessSquareView(
                                row: row,
                                col: col,
                                piece: board[row][col],
                                isLight: isLightSquare(row: row, col: col)
                            )
                            .frame(width: squareSize, height: squareSize)
                        }
                    }
                }
            }
            .frame(
                width: squareSize * CGFloat(columns),
                height: squareSize * CGFloat(rows)
            )
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
        }
    }

    /// Determine if a square should be light colored based on chess board
    /// pattern
    /// - Parameters:
    ///   - row: Row index (0-7)
    ///   - col: Column index (0-7)
    /// - Returns: true if square is light colored, false if dark
    private func isLightSquare(row: Int, col: Int) -> Bool {
        return (row + col) % 2 == 0
    }
}

/// Individual chess board square with optional piece
struct ChessSquareView: View {
    let row: Int
    let col: Int
    let piece: Piece?
    let isLight: Bool

    var body: some View {
        ZStack {
            // Square background
            Rectangle()
                .fill(isLight ? lightSquareColor : darkSquareColor)

            // Piece (if present)
            if let piece = piece {
                Image(piece.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Preview

#Preview {
    ChessBoardView()
        .frame(width: 400, height: 400)
}
