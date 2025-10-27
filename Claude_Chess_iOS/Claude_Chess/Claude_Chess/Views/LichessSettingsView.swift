//
//  LichessSettingsView.swift
//  Claude_Chess
//
//  Lichess engine configuration view (placeholder)
//  Future implementation will include Lichess API integration
//  with OAuth authentication and rating-based difficulty
//

import SwiftUI

/// Lichess engine settings view (placeholder for future implementation)
/// - Will include OAuth authentication
/// - Rating-based difficulty (800-2800)
/// - Opening explorer and cloud analysis
struct LichessSettingsView: View {
    @AppStorage("selectedEngine") private var selectedEngine = "stockfish"

    var body: some View {
        List {
            Section(header: Text("Engine Selection")) {
                Button(action: {
                    selectedEngine = "lichess"
                }) {
                    HStack {
                        Text("Use Lichess")
                        Spacer()
                        if selectedEngine == "lichess" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }

            Section(header: Text("Coming Soon")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Lichess Integration")
                        .font(.headline)

                    Text("Future features will include:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• OAuth account authentication")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Rating-based difficulty (800-2800)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Opening explorer integration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Cloud analysis and position evaluation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Free and open-source platform")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("This feature is planned for Phase 2 of development.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .navigationTitle("Lichess")
        .navigationBarTitleDisplayMode(.inline)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        LichessSettingsView()
    }
}
