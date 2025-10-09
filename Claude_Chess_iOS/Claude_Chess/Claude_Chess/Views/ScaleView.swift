//
//  ScaleView.swift
//  Claude_Chess
//
//  Scale settings for position evaluation display
//  This view allows users to configure how position evaluation scores
//  are displayed (e.g., centipawns, -9 to +9 scale, win probability)
//

import SwiftUI

/// Scale settings view for position evaluation display
/// - Configure evaluation display format (centipawns, scaled, percentage)
/// - Customize evaluation bar appearance and sensitivity
struct ScaleView: View {
    @AppStorage("evaluationScale") private var evaluationScale = "scaled"

    var body: some View {
        List {
            Section(header: Text("Evaluation Display Format")) {
                Picker(selection: $evaluationScale, label: EmptyView()) {
                    Text("Centipawns").tag("centipawns")
                    Text("Scaled (-9 to +9)").tag("scaled")
                    Text("Win Probability").tag("percentage")
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            // Show conversion chart button only when scaled format is selected
            if evaluationScale == "scaled" {
                Section {
                    NavigationLink(destination: ScoreConversionChartView()) {
                        Label("View Conversion Chart", systemImage: "tablecells")
                    }
                }
            }

            Section(header: Text("About Scales")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Centipawns")
                        .font(.headline)
                    Text("Standard chess engine evaluation where 100 centipawns = 1 pawn advantage. Example: +250 means White is up 2.5 pawns.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Scaled (-9 to +9)")
                        .font(.headline)
                    Text("Terminal project format where scores are scaled to -9 to +9 range for easier visualization. Matches the terminal version's display.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Win Probability")
                        .font(.headline)
                    Text("Shows percentage likelihood of winning from current position (e.g., 65% for White).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Scale Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ScaleView()
    }
}
