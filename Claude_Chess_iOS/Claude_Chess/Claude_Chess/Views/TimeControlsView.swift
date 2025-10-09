//
//  TimeControlsView.swift
//  Claude_Chess
//
//  Time controls configuration view
//  Allows user to set separate time allocations for White and Black players
//  with minutes and increment (seconds added after each move)
//

import SwiftUI

/// Time controls configuration view
/// - Separate settings for White and Black players
/// - Minutes: Starting time allocation (0-60 minutes)
/// - Increment: Seconds added after each move (0-60 seconds)
/// - Setting both players to 0/0 disables time controls
struct TimeControlsView: View {
    // White player time controls
    @AppStorage("whiteMinutes") private var whiteMinutes = 30
    @AppStorage("whiteIncrement") private var whiteIncrement = 10

    // Black player time controls
    @AppStorage("blackMinutes") private var blackMinutes = 5
    @AppStorage("blackIncrement") private var blackIncrement = 0

    var body: some View {
        List {
            // Time controls status - now selectable
            Section {
                Picker("Status", selection: Binding(
                    get: { isTimeControlsEnabled },
                    set: { newValue in
                        if !newValue {
                            // User selected "Disabled" - set all to 0
                            whiteMinutes = 0
                            whiteIncrement = 0
                            blackMinutes = 0
                            blackIncrement = 0
                        } else {
                            // User selected "Enabled" - set to terminal defaults if all were 0
                            if whiteMinutes == 0 && whiteIncrement == 0 && blackMinutes == 0 && blackIncrement == 0 {
                                whiteMinutes = 30
                                whiteIncrement = 10
                                blackMinutes = 5
                                blackIncrement = 0
                            }
                        }
                    }
                )) {
                    Text("Enabled").tag(true)
                    Text("Disabled").tag(false)
                }
                .pickerStyle(.segmented)
            }

            // White player section
            Section(header: Text("White Player")) {
                VStack(alignment: .leading, spacing: 16) {
                    // Minutes slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Starting Time:")
                                .font(.subheadline)
                            Spacer()
                            Text("\(whiteMinutes) minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(whiteMinutes) },
                            set: { whiteMinutes = Int($0) }
                        ), in: 0...60, step: 1)
                    }

                    // Increment slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Increment:")
                                .font(.subheadline)
                            Spacer()
                            Text("\(whiteIncrement) seconds")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(whiteIncrement) },
                            set: { whiteIncrement = Int($0) }
                        ), in: 0...60, step: 1)
                    }
                }
            }

            // Black player section
            Section(header: Text("Black Player")) {
                VStack(alignment: .leading, spacing: 16) {
                    // Minutes slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Starting Time:")
                                .font(.subheadline)
                            Spacer()
                            Text("\(blackMinutes) minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(blackMinutes) },
                            set: { blackMinutes = Int($0) }
                        ), in: 0...60, step: 1)
                    }

                    // Increment slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Increment:")
                                .font(.subheadline)
                            Spacer()
                            Text("\(blackIncrement) seconds")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(blackIncrement) },
                            set: { blackIncrement = Int($0) }
                        ), in: 0...60, step: 1)
                    }
                }
            }

            // Quick presets section
            Section(header: Text("Quick Presets")) {
                Button("Blitz (5 min + 0 sec)") {
                    whiteMinutes = 5
                    whiteIncrement = 0
                    blackMinutes = 5
                    blackIncrement = 0
                }

                Button("Rapid (10 min + 5 sec)") {
                    whiteMinutes = 10
                    whiteIncrement = 5
                    blackMinutes = 10
                    blackIncrement = 5
                }

                Button("Classical (30 min + 10 sec)") {
                    whiteMinutes = 30
                    whiteIncrement = 10
                    blackMinutes = 30
                    blackIncrement = 10
                }

                Button("Terminal Default (30/10 vs 5/0)") {
                    whiteMinutes = 30
                    whiteIncrement = 10
                    blackMinutes = 5
                    blackIncrement = 0
                }
            }

            // About time controls
            Section(header: Text("About Time Controls")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Starting Time: Total minutes each player has at game start.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Increment: Seconds added to a player's clock after each move they make.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("To disable time controls, use the Status picker above to select 'Disabled' or move all 4 sliders to 0.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)

                    Text("Time controls cannot be changed after the game starts.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
            }
        }
        .navigationTitle("Time Controls")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Check if time controls are enabled
    private var isTimeControlsEnabled: Bool {
        return !(whiteMinutes == 0 && whiteIncrement == 0 && blackMinutes == 0 && blackIncrement == 0)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        TimeControlsView()
    }
}

