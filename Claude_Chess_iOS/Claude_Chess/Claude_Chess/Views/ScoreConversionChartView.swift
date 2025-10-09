//
//  ScoreConversionChartView.swift
//  Claude_Chess
//
//  Score conversion chart showing centipawn to scaled score mapping
//  Displays the conversion table used by the terminal project
//  for converting Stockfish centipawn evaluations to -9 to +9 scale
//

import SwiftUI

/// Score conversion chart view displaying centipawn to scaled score mapping
/// - Shows complete conversion table from terminal project
/// - Explains how Stockfish centipawns map to -9 to +9 game score scale
struct ScoreConversionChartView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("SCORE CONVERSION CHART")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)

                Text("Stockfish Centipawns → Game Score Scale")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 16)

                // Black Advantage Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Black Advantage:")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ConversionRow(centipawns: "-900+", score: "-9", description: "(Black crushing)")
                    ConversionRow(centipawns: "-500 to -900", score: "-8", description: "(Black winning big)")
                    ConversionRow(centipawns: "-300 to -500", score: "-7", description: "(Black significant advantage)")
                    ConversionRow(centipawns: "-200 to -300", score: "-6", description: "(Black moderate advantage)")
                    ConversionRow(centipawns: "-100 to -200", score: "-5", description: "(Black small advantage)")
                    ConversionRow(centipawns: "-50 to -100", score: "-4", description: "(Black slight advantage)")
                    ConversionRow(centipawns: "-25 to -50", score: "-3", description: "(Black tiny advantage)")
                    ConversionRow(centipawns: "-10 to -25", score: "-2", description: "(Black very slight edge)")
                    ConversionRow(centipawns: "-1 to -10", score: "-1", description: "(Black barely ahead)")
                }
                .padding(.bottom, 16)

                // Even Game Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Even Game:")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ConversionRow(centipawns: "0", score: "0", description: "(Perfectly equal)")
                }
                .padding(.bottom, 16)

                // White Advantage Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("White Advantage:")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ConversionRow(centipawns: "+1 to +10", score: "+1", description: "(White barely ahead)")
                    ConversionRow(centipawns: "+10 to +25", score: "+2", description: "(White very slight edge)")
                    ConversionRow(centipawns: "+25 to +50", score: "+3", description: "(White tiny advantage)")
                    ConversionRow(centipawns: "+50 to +100", score: "+4", description: "(White slight advantage)")
                    ConversionRow(centipawns: "+100 to +200", score: "+5", description: "(White small advantage)")
                    ConversionRow(centipawns: "+200 to +300", score: "+6", description: "(White moderate advantage)")
                    ConversionRow(centipawns: "+300 to +500", score: "+7", description: "(White significant advantage)")
                    ConversionRow(centipawns: "+500 to +900", score: "+8", description: "(White winning big)")
                    ConversionRow(centipawns: "+900+", score: "+9", description: "(White crushing)")
                }
            }
            .padding()
        }
        .navigationTitle("Conversion Chart")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Single row in the conversion chart
struct ConversionRow: View {
    let centipawns: String
    let score: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Centipawns column
            Text(centipawns)
                .font(.system(.body, design: .monospaced))
                .frame(width: 140, alignment: .leading)

            // Arrow
            Text("→")
                .foregroundColor(.secondary)

            // Score column
            Text(score)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .frame(width: 30, alignment: .trailing)

            // Description
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ScoreConversionChartView()
    }
}
