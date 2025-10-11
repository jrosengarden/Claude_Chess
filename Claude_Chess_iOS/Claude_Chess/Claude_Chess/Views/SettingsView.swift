//
//  SettingsView.swift
//  Claude_Chess
//
//  Settings and preferences view
//

import SwiftUI

/// Main settings view with all configuration options
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("boardThemeId") private var boardThemeId = "classic"
    @AppStorage("showPossibleMoves") private var showPossibleMoves: Bool = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true

    // Custom color storage
    @AppStorage("customLightRed") private var customLightRed: Double = 0.93
    @AppStorage("customLightGreen") private var customLightGreen: Double = 0.85
    @AppStorage("customLightBlue") private var customLightBlue: Double = 0.71
    @AppStorage("customDarkRed") private var customDarkRed: Double = 0.72
    @AppStorage("customDarkGreen") private var customDarkGreen: Double = 0.53
    @AppStorage("customDarkBlue") private var customDarkBlue: Double = 0.30

    var body: some View {
        NavigationStack {
            List {
                // Game Options Section
                Section {
                    Toggle("Show Possible Moves", isOn: $showPossibleMoves)

                    #if os(iOS)
                    Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                    #endif
                } header: {
                    Text("Game Options")
                } footer: {
                    #if os(iOS)
                    Text("Show Possible Moves: Legal moves are automatically highlighted when you select a piece.\n\nHaptic Feedback: Vibration feedback for piece selection, moves, and invalid actions (iOS only).")
                    #else
                    Text("When enabled, legal moves are automatically highlighted when you select a piece. You can still preview moves for any piece by double-tapping it.")
                    #endif
                }

                // Board Settings Section
                Section("Board") {
                    NavigationLink {
                        BoardColorThemePickerView(
                            selectedThemeId: $boardThemeId,
                            customLightRed: $customLightRed,
                            customLightGreen: $customLightGreen,
                            customLightBlue: $customLightBlue,
                            customDarkRed: $customDarkRed,
                            customDarkGreen: $customDarkGreen,
                            customDarkBlue: $customDarkBlue
                        )
                    } label: {
                        HStack {
                            Text("Color Theme")
                            Spacer()
                            Text(BoardColorTheme.theme(withId: boardThemeId).name)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Future sections will go here
                // Section("Game") { ... }
                // Section("AI Opponent") { ... }
                // Section("Time Controls") { ... }

                // Appearance Section
                Section("Appearance") {
                    NavigationLink {
                        ChessPiecesView()
                    } label: {
                        HStack {
                            Text("Chess Pieces")
                            Spacer()
                            Text("Cburnett")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0 (Phase 1)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Board color theme picker view
struct BoardColorThemePickerView: View {
    @Binding var selectedThemeId: String

    // Custom color bindings
    @Binding var customLightRed: Double
    @Binding var customLightGreen: Double
    @Binding var customLightBlue: Double
    @Binding var customDarkRed: Double
    @Binding var customDarkGreen: Double
    @Binding var customDarkBlue: Double

    var body: some View {
        List(BoardColorTheme.allThemes) { theme in
            if theme.id == "custom" {
                NavigationLink {
                    CustomColorPickerView(
                        lightRed: $customLightRed,
                        lightGreen: $customLightGreen,
                        lightBlue: $customLightBlue,
                        darkRed: $customDarkRed,
                        darkGreen: $customDarkGreen,
                        darkBlue: $customDarkBlue,
                        selectedThemeId: $selectedThemeId
                    )
                    .onAppear {
                        // Set theme to custom when user taps into custom color picker
                        selectedThemeId = "custom"
                    }
                } label: {
                    HStack {
                        // Theme preview with current custom colors
                        HStack(spacing: 0) {
                            SwiftUI.Color(red: customLightRed, green: customLightGreen,
                                         blue: customLightBlue)
                                .frame(width: 30, height: 30)
                            SwiftUI.Color(red: customDarkRed, green: customDarkGreen,
                                         blue: customDarkBlue)
                                .frame(width: 30, height: 30)
                        }
                        .cornerRadius(4)

                        Text(theme.name)
                            .foregroundColor(.primary)

                        Spacer()

                        if selectedThemeId == theme.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            } else {
                Button {
                    selectedThemeId = theme.id
                } label: {
                    HStack {
                        // Theme preview
                        HStack(spacing: 0) {
                            theme.lightSquare.color
                                .frame(width: 30, height: 30)
                            theme.darkSquare.color
                                .frame(width: 30, height: 30)
                        }
                        .cornerRadius(4)

                        Text(theme.name)
                            .foregroundColor(.primary)

                        Spacer()

                        if selectedThemeId == theme.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Board Colors")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Custom color picker view for user-defined board colors
struct CustomColorPickerView: View {
    @Binding var lightRed: Double
    @Binding var lightGreen: Double
    @Binding var lightBlue: Double
    @Binding var darkRed: Double
    @Binding var darkGreen: Double
    @Binding var darkBlue: Double
    @Binding var selectedThemeId: String

    var lightColor: SwiftUI.Color {
        SwiftUI.Color(red: lightRed, green: lightGreen, blue: lightBlue)
    }

    var darkColor: SwiftUI.Color {
        SwiftUI.Color(red: darkRed, green: darkGreen, blue: darkBlue)
    }

    var body: some View {
        List {
            // Preview section
            Section("Preview") {
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            lightColor.frame(width: 40, height: 40)
                            darkColor.frame(width: 40, height: 40)
                            lightColor.frame(width: 40, height: 40)
                            darkColor.frame(width: 40, height: 40)
                        }
                        HStack(spacing: 0) {
                            darkColor.frame(width: 40, height: 40)
                            lightColor.frame(width: 40, height: 40)
                            darkColor.frame(width: 40, height: 40)
                            lightColor.frame(width: 40, height: 40)
                        }
                        HStack(spacing: 0) {
                            lightColor.frame(width: 40, height: 40)
                            darkColor.frame(width: 40, height: 40)
                            lightColor.frame(width: 40, height: 40)
                            darkColor.frame(width: 40, height: 40)
                        }
                        HStack(spacing: 0) {
                            darkColor.frame(width: 40, height: 40)
                            lightColor.frame(width: 40, height: 40)
                            darkColor.frame(width: 40, height: 40)
                            lightColor.frame(width: 40, height: 40)
                        }
                    }
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(SwiftUI.Color.clear)
            }

            // Light square color picker
            Section("Light Squares") {
                ColorPicker("Light Square Color", selection: Binding(
                    get: { lightColor },
                    set: { newColor in
                        let components = BoardColorTheme.componentsFrom(color: newColor)
                        lightRed = components.red
                        lightGreen = components.green
                        lightBlue = components.blue
                        selectedThemeId = "custom"
                    }
                ))
            }

            // Dark square color picker
            Section("Dark Squares") {
                ColorPicker("Dark Square Color", selection: Binding(
                    get: { darkColor },
                    set: { newColor in
                        let components = BoardColorTheme.componentsFrom(color: newColor)
                        darkRed = components.red
                        darkGreen = components.green
                        darkBlue = components.blue
                        selectedThemeId = "custom"
                    }
                ))
            }
        }
        .navigationTitle("Custom Colors")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
