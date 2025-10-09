//
//  ChessComSettingsView.swift
//  Claude_Chess
//
//  Chess.com engine configuration view (placeholder)
//  Future implementation will include Chess.com API integration
//  with account authentication and difficulty settings
//

import SwiftUI

/// Chess.com engine settings view (placeholder for future implementation)
/// - Will include API authentication
/// - Difficulty level selection
/// - Online game features
struct ChessComSettingsView: View {
    @AppStorage("selectedEngine") private var selectedEngine = "stockfish"

    var body: some View {
        List {
            Section(header: Text("Engine Selection")) {
                Button(action: {
                    selectedEngine = "chesscom"
                }) {
                    HStack {
                        Text("Use Chess.com")
                        Spacer()
                        if selectedEngine == "chesscom" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }

            Section(header: Text("Coming Soon")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chess.com Integration")
                        .font(.headline)

                    Text("Future features will include:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Account authentication")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Multiple difficulty levels")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Online game analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Position evaluation via Chess.com API")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("This feature is planned for Phase 3 of development.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .navigationTitle("Chess.com")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ChessComSettingsView()
    }
}
