//
//  CapturedPiecesView.swift
//  Claude_Chess
//
//  Overlay view displaying captured pieces for a player
//  Shows all captured pieces as individual SVG icons in sorted order
//  Positioned at top of screen, covering White/Black info lines
//

import SwiftUI

// Import our chess Color enum explicitly to avoid SwiftUI.Color conflict
enum ChessPieceColor {
    case white
    case black

    var displayName: String {
        switch self {
        case .white: return "White"
        case .black: return "Black"
        }
    }
}

struct CapturedPiecesOverlay: View {
    let player: ChessPieceColor
    let capturedPieces: [Piece]
    @Binding var isPresented: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Check if running on larger device (iPad/macOS)
    private var isLargeDevice: Bool {
        #if os(macOS)
        return true
        #else
        return horizontalSizeClass == .regular
        #endif
    }

    /// Piece icon size in overlay (same as original display)
    private var pieceIconSize: CGFloat {
        isLargeDevice ? 30 : 20
    }

    var body: some View {
        VStack(spacing: 8) {
            // Title and close button
            HStack {
                Text("\(player.displayName) Captured Pieces")
                    .font(isLargeDevice ? .title3 : .headline)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(isLargeDevice ? .title2 : .title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if capturedPieces.isEmpty {
                // Empty state
                Text("No pieces captured yet")
                    .font(isLargeDevice ? .body : .caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                // Display all captured pieces as individual icons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(capturedPieces.enumerated()), id: \.offset) { _, piece in
                            Image(piece.assetName)
                                .resizable()
                                .frame(width: pieceIconSize, height: pieceIconSize)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: pieceIconSize + 8)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SwiftUI.Color(.systemBackground))
                .shadow(radius: 10)
        )
        .padding(.horizontal)
    }
}

// Keep the old sheet-based view for reference/backwards compatibility
struct CapturedPiecesView: View {
    let player: ChessPieceColor
    let capturedPieces: [Piece]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Check if running on larger device (iPad/macOS)
    private var isLargeDevice: Bool {
        #if os(macOS)
        return true
        #else
        return horizontalSizeClass == .regular
        #endif
    }

    /// Piece icon size in modal (same as original display)
    private var pieceIconSize: CGFloat {
        isLargeDevice ? 30 : 20
    }

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("\(player.displayName) Captured Pieces")
                .font(isLargeDevice ? .title : .title2)
                .fontWeight(.bold)
                .padding(.top)

            if capturedPieces.isEmpty {
                // Empty state
                Text("No pieces captured yet")
                    .font(isLargeDevice ? .title3 : .body)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                // Display all captured pieces as individual icons
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: pieceIconSize), spacing: 8)
                    ], spacing: 8) {
                        ForEach(Array(capturedPieces.enumerated()), id: \.offset) { _, piece in
                            Image(piece.assetName)
                                .resizable()
                                .frame(width: pieceIconSize, height: pieceIconSize)
                        }
                    }
                    .padding()
                }
            }

            // OK button
            Button(action: {
                dismiss()
            }) {
                Text("OK")
                    .font(isLargeDevice ? .title2 : .headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SwiftUI.Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    // Preview with some captured pieces
    let samplePieces = [
        Piece(type: .queen, color: .black),
        Piece(type: .rook, color: .black),
        Piece(type: .rook, color: .black),
        Piece(type: .knight, color: .black),
        Piece(type: .pawn, color: .black),
        Piece(type: .pawn, color: .black),
        Piece(type: .pawn, color: .black)
    ]

    return CapturedPiecesView(
        player: .white,
        capturedPieces: samplePieces
    )
}
