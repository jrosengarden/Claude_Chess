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
    @State private var showingFEN = false
    @State private var showingPGN = false
    @State private var isEvaluatingDraw = false
    @State private var showingDrawResult = false
    @State private var drawAccepted = false

    // Board orientation (persisted across app restarts)
    @AppStorage("boardFlipped") private var boardFlipped: Bool = false

    // Opponent settings for engine initialization
    @AppStorage("selectedEngine") private var selectedEngine = "human"
    @AppStorage("stockfishSkillLevel") private var skillLevel = 5

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

                        // Initialize AI engine if needed, THEN start game
                        Task {
                            do {
                                try await game.initializeEngine(selectedEngine: selectedEngine, skillLevel: skillLevel)
                            } catch {
                                print("ERROR: Failed to initialize engine: \(error)")
                            }

                            // Start game AFTER engine is initialized
                            await MainActor.run {
                                game.gameInProgress = true
                                game.startMoveTimer()

                                // Trigger AI move check in case it's AI's turn (e.g., after Setup Board with Black to move)
                                game.aiMoveCheckTrigger += 1

                                dismiss()
                            }

                            // Wait for Quick Menu to dismiss and UI to settle
                            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms

                            // Update position evaluation after game starts
                            await game.updatePositionEvaluation()
                        }
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
                        boardFlipped.toggle()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                            Text("Flip Board")
                        }
                    }

                    Button(action: {
                        #if os(iOS)
                        if hapticFeedbackEnabled {
                            lightHaptic.impactOccurred()
                        }
                        #endif
                        Task {
                            isEvaluatingDraw = true
                            drawAccepted = await game.offerDraw()
                            isEvaluatingDraw = false
                            showingDrawResult = true
                        }
                    }) {
                        HStack {
                            if isEvaluatingDraw {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                Text("Evaluating...")
                            } else {
                                Image(systemName: "equal.circle")
                                    .foregroundColor(.red)
                                Text("Offer Draw")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .disabled(!game.gameInProgress || game.selectedEngine == "human" || isEvaluatingDraw)
                    .opacity((!game.gameInProgress || game.selectedEngine == "human" || isEvaluatingDraw) ? 0.3 : 1.0)

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
                    .disabled(!game.gameInProgress)
                    .opacity(!game.gameInProgress ? 0.3 : 1.0)
                }

                Section("Position Info") {
                    NavigationLink(destination: ScoreView(game: game)) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.blue)
                            Text("Score")
                        }
                    }
                    .disabled(!game.gameInProgress)
                    .opacity(!game.gameInProgress ? 0.3 : 1.0)

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
        .alert(drawAccepted ? "Draw Accepted!" : "Draw Declined", isPresented: $showingDrawResult) {
            Button("OK") {
                if drawAccepted {
                    // End game as draw
                    game.gameInProgress = false
                    dismiss()
                } else {
                    // Continue playing
                    dismiss()
                }
            }
        } message: {
            Text(drawAccepted
                 ? "Your opponent has accepted the draw offer. Game ends in a draw."
                 : "Your opponent has declined the draw offer. The game continues.")
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

// MARK: - Preview

#Preview {
    QuickGameMenuView(game: ChessGame())
}
