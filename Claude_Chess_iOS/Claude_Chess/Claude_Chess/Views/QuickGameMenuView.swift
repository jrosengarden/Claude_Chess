//
//  QuickGameMenuView.swift
//  Claude_Chess
//
//  Quick access menu for in-game actions
//  Provides fast access to frequently used game features
//

import SwiftUI

/// Quick Game menu for in-game actions (Hint, FEN/PGN display, Undo, Resign)
/// Accessed via lightning bolt icon in header
struct QuickGameMenuView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var game: ChessGame
    @State private var showingHint = false
    @State private var showingFEN = false
    @State private var showingPGN = false
    @State private var showingEngineTest = false
    @State private var engineTestResults = ""
    @State private var isRunningEngineTest = false

    // Haptic feedback
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    #if os(iOS)
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    #endif

    var body: some View {
        NavigationStack {
            List {
                Section("Game Actions") {
                    // Start Game button - only enabled before game starts
                    Button {
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            lightHaptic.impactOccurred()
                        }
                        #endif
                        game.gameInProgress = true
                        game.startMoveTimer()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                                .foregroundColor(.green)
                            Text("Start Game")
                        }
                    }
                    .disabled(game.gameInProgress)

                    Button {
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            lightHaptic.impactOccurred()
                        }
                        #endif
                        showingHint = true
                    } label: {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Hint")
                        }
                    }
                    
                    Button {
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            lightHaptic.impactOccurred()
                        }
                        #endif
                        isRunningEngineTest = true
                        Task {
                            engineTestResults = await EngineTest.runEngineTest()
                            isRunningEngineTest = false
                            showingEngineTest = true
                        }
                    } label: {
                        HStack {
                            if isRunningEngineTest {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            Text("Stockfish Integration Tests")
                        }
                    }
                    .disabled(isRunningEngineTest)

                    Button(role: .destructive) {
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            lightHaptic.impactOccurred()
                        }
                        #endif
                        // TODO: Implement resign action
                    } label: {
                        HStack {
                            Image(systemName: "flag.fill")
                            Text("Resign Game")
                        }
                    }
                }

                Section("Position Info") {
                    Button {
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            lightHaptic.impactOccurred()
                        }
                        #endif
                        showingFEN = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.green)
                            Text("Show FEN")
                        }
                    }

                    Button {
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            lightHaptic.impactOccurred()
                        }
                        #endif
                        showingPGN = true
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(.purple)
                            Text("Show PGN")
                        }
                    }
                }
            }
            .navigationTitle("Quick Game Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingHint) {
            NavigationView {
                HintView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingHint = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingFEN) {
            NavigationView {
                FENDisplayView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingFEN = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingPGN) {
            NavigationView {
                PGNDisplayView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingPGN = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingEngineTest) {
            NavigationView {
                EngineTestResultsView(results: engineTestResults)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingEngineTest = false
                            }
                        }
                    }
            }
        }
    }
}

/// Placeholder view for FEN display
struct FENDisplayView: View {
    var body: some View {
        VStack {
            Text("FEN Display")
                .font(.title)
            Text("TODO: Display current board FEN string")
                .foregroundColor(.secondary)
        }
        .navigationTitle("FEN Position")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Placeholder view for PGN display
struct PGNDisplayView: View {
    var body: some View {
        VStack {
            Text("PGN Display")
                .font(.title)
            Text("TODO: Display game move history in PGN format")
                .foregroundColor(.secondary)
        }
        .navigationTitle("PGN Notation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Engine test results display view
struct EngineTestResultsView: View {
    let results: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(results)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
        }
        .navigationTitle("Stockfish Test Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    QuickGameMenuView(game: ChessGame())
}
