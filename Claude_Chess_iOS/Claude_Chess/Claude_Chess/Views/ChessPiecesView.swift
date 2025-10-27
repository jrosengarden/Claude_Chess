//
//  ChessPiecesView.swift
//  Claude_Chess
//
//  Chess piece style selection view
//  Allows user to select different chess piece graphic sets
//  Currently supports Cburnett style (more styles to be added later)
//

import SwiftUI

/// Chess piece style selection view
/// - Currently supports Cburnett (Wikimedia) style
/// - Future: Additional piece styles planned for end of project
struct ChessPiecesView: View {
    @AppStorage("chessPieceStyle") private var chessPieceStyle = "cburnett"

    var body: some View {
        List {
            Section(header: Text("Piece Style")) {
                Button {
                    chessPieceStyle = "cburnett"
                } label: {
                    HStack {
                        Text("Cburnett (Wikimedia)")
                            .foregroundColor(.primary)

                        Spacer()

                        if chessPieceStyle == "cburnett" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }

            Section(header: Text("About Cburnett Pieces")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The Cburnett chess piece set is a professional, widely-used design from Wikimedia Commons.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("These pieces are used by Wikipedia, chess.com (early versions), and many chess applications worldwide.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
            }

            Section(header: Text("License")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cburnett Chess Pieces")
                        .font(.headline)

                    Text("Licensed under CC-BY-SA 3.0 (Creative Commons Attribution-ShareAlike)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Creator: User:Cburnett")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Source: Wikimedia Commons")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("URL: https://commons.wikimedia.org/wiki/Category:SVG_chess_pieces")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section(header: Text("Coming Soon")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional piece styles will be added near the end of the project.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Planned styles may include:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Modern minimalist pieces")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Classic Staunton style")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 3D rendered pieces")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Custom color variations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Chess Pieces")
        .navigationBarTitleDisplayMode(.inline)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ChessPiecesView()
    }
}
