//
//  ChessBoardView.swift
//  Claude_Chess
//
//  Chess board visual representation with 8x8 grid
//

import SwiftUI

/// Visual representation of a chess board with alternating light/dark squares
/// and piece placement
struct ChessBoardView: View {
    // Chess board dimensions
    private let rows = 8
    private let columns = 8

    // Board state
    var board: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8),
                                   count: 8)

    // Color theme (persisted via AppStorage)
    @AppStorage("boardThemeId") private var boardThemeId = "classic"

    // Custom color storage
    @AppStorage("customLightRed") private var customLightRed: Double = 0.93
    @AppStorage("customLightGreen") private var customLightGreen: Double = 0.85
    @AppStorage("customLightBlue") private var customLightBlue: Double = 0.71
    @AppStorage("customDarkRed") private var customDarkRed: Double = 0.72
    @AppStorage("customDarkGreen") private var customDarkGreen: Double = 0.53
    @AppStorage("customDarkBlue") private var customDarkBlue: Double = 0.30

    private var currentTheme: BoardColorTheme {
        if boardThemeId == "custom" {
            let lightComponents = BoardColorTheme.ColorComponents(
                red: customLightRed, green: customLightGreen, blue: customLightBlue
            )
            let darkComponents = BoardColorTheme.ColorComponents(
                red: customDarkRed, green: customDarkGreen, blue: customDarkBlue
            )
            return BoardColorTheme.theme(withId: boardThemeId,
                                        customLight: lightComponents,
                                        customDark: darkComponents)
        }
        return BoardColorTheme.theme(withId: boardThemeId)
    }

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
                                isLight: isLightSquare(row: row, col: col),
                                lightColor: currentTheme.lightSquare.color,
                                darkColor: currentTheme.darkSquare.color
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
    let lightColor: SwiftUI.Color
    let darkColor: SwiftUI.Color

    var body: some View {
        ZStack {
            // Square background
            (isLight ? lightColor : darkColor)

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
