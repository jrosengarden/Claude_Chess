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
    @State private var showingResignConfirmation = false

    // Board orientation (persisted across app restarts)
    @AppStorage("boardFlipped") private var boardFlipped: Bool = false

    // Opponent settings for engine initialization
    @AppStorage("selectedEngine") private var selectedEngine = "human"
    @AppStorage("stockfishSkillLevel") private var skillLevel = 5
    @AppStorage("stockfishPlaysColor") private var stockfishPlaysColor = "black"

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
                                try await game.initializeEngine(selectedEngine: selectedEngine, skillLevel: skillLevel, stockfishColor: stockfishPlaysColor)
                            } catch {
                                print("ERROR: Failed to initialize engine: \(error)")
                            }

                            // Start game AFTER engine is initialized
                            await MainActor.run {
                                game.gameInProgress = true
                                game.startMoveTimer()

                                dismiss()
                            }

                            // If Stockfish plays White, add 2-second delay before first move
                            // This gives user time to return to main view
                            if selectedEngine == "stockfish" && stockfishPlaysColor == "white" {
                                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                            }

                            // Trigger AI move check in case it's AI's turn
                            await MainActor.run {
                                game.aiMoveCheckTrigger += 1
                            }

                            // Wait for Quick Menu to dismiss and UI to settle
                            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms

                            // TEMPORARILY COMMENTED OUT FOR TESTING
                            // Update position evaluation after game starts
                            // await game.updatePositionEvaluation()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                                .foregroundColor(.green)
                            Text("Start Game")
                        }
                    }
                    .disabled(game.gameInProgress || game.gameHasEnded)

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
                        showingResignConfirmation = true
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
        .overlay {
            if showingFEN {
                FENDisplayView(
                    game: game,
                    isPresented: $showingFEN,
                    dismissParent: dismiss
                )
            }
        }
        .overlay {
            if showingPGN {
                PGNDisplayView(
                    game: game,
                    isPresented: $showingPGN,
                    dismissParent: dismiss
                )
            }
        }
        .overlay {
            if showingDrawResult {
                DrawResultAlertView(
                    isPresented: $showingDrawResult,
                    drawAccepted: drawAccepted,
                    onOK: {
                        if drawAccepted {
                            // End game as draw
                            game.gameInProgress = false
                            game.gameHasEnded = true
                            dismiss()
                        } else {
                            // Continue playing
                            dismiss()
                        }
                    }
                )
            }
        }
        .overlay {
            if showingResignConfirmation {
                ResignConfirmationAlertView(
                    isPresented: $showingResignConfirmation,
                    onCancel: {
                        // Return to main view (dismiss Quick Menu)
                        dismiss()
                    },
                    onResign: {
                        // Determine winner (opponent of current player)
                        let winner = game.currentPlayer == .white ? "Black" : "White"

                        // Set resignation winner for alert display
                        game.resignationWinner = winner

                        // End game permanently
                        game.gameInProgress = false
                        game.gameHasEnded = true
                        game.stopMoveTimer()

                        dismiss()
                    }
                )
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
    }
}

/// Custom FEN display overlay with copy functionality
struct FENDisplayView: View {
    @ObservedObject var game: ChessGame
    @Binding var isPresented: Bool
    let dismissParent: DismissAction
    @State private var showingCopiedConfirmation = false

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Current Position (FEN)")
                    .font(.headline)
                    .padding(.top)

                VStack(spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: true) {
                        Text(game.boardToFEN())
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .lineLimit(1)
                    }
                    .frame(height: 50)
                    .background(SwiftUI.Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)

                    if showingCopiedConfirmation {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Copied to clipboard!")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .transition(.opacity)
                    }
                }
                .padding()

                VStack(spacing: 12) {
                    Button(action: {
                        // Copy FEN to clipboard
                        UIPasteboard.general.string = game.boardToFEN()

                        // Show confirmation briefly
                        withAnimation {
                            showingCopiedConfirmation = true
                        }

                        // Dismiss alert and parent Quick Menu after showing confirmation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                showingCopiedConfirmation = false
                            }
                            isPresented = false
                            dismissParent()
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy FEN")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Cancel") {
                        isPresented = false
                        dismissParent()
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(width: 340)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
    }
}

/// Custom PGN display overlay with copy functionality
struct PGNDisplayView: View {
    @ObservedObject var game: ChessGame
    @Binding var isPresented: Bool
    let dismissParent: DismissAction
    @State private var showingCopiedConfirmation = false

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Move History (PGN)")
                    .font(.headline)
                    .padding(.top)

                VStack(spacing: 12) {
                    ScrollView {
                        Text(game.generatePGN())
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 200)
                    .background(SwiftUI.Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)

                    if showingCopiedConfirmation {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Copied to clipboard!")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .transition(.opacity)
                    }
                }
                .padding()

                VStack(spacing: 12) {
                    Button(action: {
                        // Copy PGN to clipboard
                        UIPasteboard.general.string = game.generatePGN()

                        // Show confirmation briefly
                        withAnimation {
                            showingCopiedConfirmation = true
                        }

                        // Dismiss alert and parent Quick Menu after showing confirmation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                showingCopiedConfirmation = false
                            }
                            isPresented = false
                            dismissParent()
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy PGN")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Cancel") {
                        isPresented = false
                        dismissParent()
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(width: 340)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // Cap text size to prevent layout breaking
    }
}

/// Custom draw result alert overlay
struct DrawResultAlertView: View {
    @Binding var isPresented: Bool
    let drawAccepted: Bool
    let onOK: () -> Void

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(drawAccepted ? "Draw Accepted!" : "Draw Declined")
                    .font(.headline)
                    .padding(.top)

                Text(drawAccepted
                     ? "Your opponent has accepted the draw offer. Game ends in a draw."
                     : "Your opponent has declined the draw offer. The game continues.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("OK") {
                    isPresented = false
                    onOK()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .frame(width: 300)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// Custom resign confirmation alert overlay
struct ResignConfirmationAlertView: View {
    @Binding var isPresented: Bool
    let onCancel: () -> Void
    let onResign: () -> Void

    var body: some View {
        ZStack {
            SwiftUI.Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Resign Game")
                    .font(.headline)
                    .padding(.top)

                Text("Are you sure you want to resign? Your opponent will win the game.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                    Button("Resign") {
                        isPresented = false
                        onResign()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(.bottom)
            }
            .frame(width: 300)
            .background(SwiftUI.Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

// MARK: - Preview

#Preview {
    QuickGameMenuView(game: ChessGame())
}
