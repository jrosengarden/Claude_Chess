//
//  PromotionPiecePickerView.swift
//  Claude_Chess
//
//  Pawn promotion piece selection dialog
//  Ported from terminal project chess.c:get_promotion_choice()
//
//  Phase 2: Used for both White and Black (human testing)
//  Phase 3: Will only be used for human player (White), Black will use
//           AI engine's promotion piece via ChessEngine protocol
//

import SwiftUI

/// Dialog for selecting which piece to promote a pawn to
/// Displays 4 options: Queen, Rook, Bishop, Knight
struct PromotionPiecePickerView: View {
    let color: Color
    let onSelection: (PieceType) -> Void

    // Promotion piece options (no King or Pawn allowed)
    private let promotionPieces: [PieceType] = [.queen, .rook, .bishop, .knight]

    var body: some View {
        VStack(spacing: 20) {
            Text("Pawn Promotion")
                .font(.title2)
                .fontWeight(.bold)

            Text("Choose a piece:")
                .font(.headline)

            HStack(spacing: 16) {
                ForEach(promotionPieces, id: \.self) { pieceType in
                    promotionButton(for: pieceType)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(SwiftUI.Color(.systemBackground))
                .shadow(radius: 20)
        )
        .padding(40)
    }

    /// Create button for a specific promotion piece
    @ViewBuilder
    private func promotionButton(for pieceType: PieceType) -> some View {
        Button {
            onSelection(pieceType)
        } label: {
            VStack(spacing: 8) {
                // Display piece image
                let assetName = pieceType.assetName(for: color)
                if !assetName.isEmpty {
                    Image(assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                }

                // Piece name
                Text(pieceType.displayName)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(SwiftUI.Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

// Preview for development
#Preview {
    ZStack {
        SwiftUI.Color.gray.opacity(0.3).ignoresSafeArea()
        PromotionPiecePickerView(color: .white) { piece in
            print("Selected: \(piece)")
        }
    }
}
