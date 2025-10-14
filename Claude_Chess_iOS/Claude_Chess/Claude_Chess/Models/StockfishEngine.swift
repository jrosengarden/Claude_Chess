//
//  StockfishEngine.swift
//  Claude_Chess
//
//  Created by Claude Code on 10/14/25.
//

import Foundation
import ChessKitEngine

/// Stockfish chess engine implementation conforming to ChessEngine protocol.
///
/// Provides offline chess AI using Stockfish 17 via the ChessKitEngine package.
/// Implements UCI (Universal Chess Interface) protocol communication for move
/// generation, position evaluation, and hints.
///
/// ## Terminal Project Parity
/// Replicates the behavior of `stockfish.c` and `stockfish.h` from the terminal
/// project, providing identical functionality in native iOS/Swift:
/// - UCI protocol communication
/// - Skill level control (0-20)
/// - Move generation with time/depth control
/// - Position evaluation
/// - Fast hint system
///
/// ## Usage
/// ```swift
/// let engine = StockfishEngine()
/// try await engine.initialize()
/// try await engine.setSkillLevel(10)  // Intermediate strength
///
/// let move = try await engine.getBestMove(position: fenString, timeLimit: nil)
/// print("Engine suggests: \(move ?? "none")")
///
/// await engine.shutdown()
/// ```
///
/// ## Neural Networks
/// Stockfish 17 requires two NNUE files to be present in the app bundle:
/// - `nn-1111cefa1111.nnue` (EvalFile)
/// - `nn-37f18f62d772.nnue` (EvalFileSmall)
///
/// These files are configured automatically during initialization if present.
///
/// - SeeAlso: `ChessEngine` protocol documentation
/// - SeeAlso: Terminal project `stockfish.c` for reference implementation
@MainActor
class StockfishEngine: ChessEngine {

    // MARK: - Properties

    /// The underlying ChessKitEngine instance
    private var engine: Engine?

    /// Task handle for the response stream listener
    private var responseTask: Task<Void, Never>?

    /// Current best move received from engine
    private var currentBestMove: String?

    /// Current evaluation score in centipawns
    private var currentEvaluation: Int?

    /// Whether engine has completed initialization
    private var initialized: Bool = false

    /// Current skill level (0-20)
    private var skillLevel: Int = 5  // Default from terminal project

    // MARK: - ChessEngine Protocol Conformance

    let engineName: String = "Stockfish"

    let requiresInternet: Bool = false

    var isReady: Bool {
        get async {
            return initialized && engine != nil
        }
    }

    // MARK: - Initialization

    init() {
        // Engine will be initialized in initialize()
    }

    func initialize() async throws {
        // Create Stockfish engine
        engine = Engine(type: .stockfish)

        guard let engine = engine else {
            throw ChessEngineError.initializationFailed("Failed to create engine instance")
        }

        // Start response stream listener
        startResponseListener()

        // Start engine
        await engine.start()

        // Wait briefly for engine to start
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Check if engine is running
        guard await engine.isRunning else {
            throw ChessEngineError.initializationFailed("Engine failed to start")
        }

        // Send UCI initialization commands
        await engine.send(command: .uci)
        await engine.send(command: .isready)

        // Configure neural network files if available
        try await configureNeuralNetworks()

        // Set default skill level
        try await setSkillLevel(skillLevel)

        initialized = true
    }

    func shutdown() async {
        // Stop response listener
        responseTask?.cancel()
        responseTask = nil

        // Quit engine
        if let engine = engine {
            await engine.send(command: .quit)
            await engine.stop()
        }

        engine = nil
        initialized = false
    }

    // MARK: - Configuration

    func setSkillLevel(_ level: Int) async throws {
        guard await isReady else {
            throw ChessEngineError.engineNotReady
        }

        // Validate skill level range (terminal project: 0-20)
        let clampedLevel = min(max(level, 0), 20)
        skillLevel = clampedLevel

        // Send UCI setoption command for Skill Level
        await engine?.send(command: .setoption(id: "Skill Level", value: "\(clampedLevel)"))

        // Disable MultiPV (terminal project behavior)
        await engine?.send(command: .setoption(id: "MultiPV", value: "1"))

        // Disable pondering (terminal project: prevents thinking on opponent time)
        await engine?.send(command: .setoption(id: "Ponder", value: "false"))
    }

    // MARK: - Move Generation

    func getBestMove(position: String, timeLimit: Int?) async throws -> String? {
        guard await isReady else {
            throw ChessEngineError.engineNotReady
        }

        guard let engine = engine else {
            throw ChessEngineError.initializationFailed("Engine not initialized")
        }

        // Reset current best move
        currentBestMove = nil

        // Stop any ongoing analysis
        await engine.send(command: .stop)

        // Small delay to ensure stop is processed
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // Set position
        await engine.send(command: .position(.fen(position)))

        // Send go command based on time limit
        if let timeLimit = timeLimit {
            // Time-based search (terminal project: uses 1/20th of remaining time)
            await engine.send(command: .go(movetime: timeLimit))
        } else {
            // Depth-based search (terminal project: depth 10 for consistent speed)
            await engine.send(command: .go(depth: 10))
        }

        // Wait for bestmove response (timeout after 30 seconds)
        let startTime = Date()
        while currentBestMove == nil {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Timeout check
            if Date().timeIntervalSince(startTime) > 30.0 {
                throw ChessEngineError.timeout
            }
        }

        return currentBestMove
    }

    func getHint(position: String) async throws -> String? {
        guard await isReady else {
            throw ChessEngineError.engineNotReady
        }

        guard let engine = engine else {
            throw ChessEngineError.initializationFailed("Engine not initialized")
        }

        // Reset current best move
        currentBestMove = nil

        // Stop any ongoing analysis
        await engine.send(command: .stop)

        // Small delay
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // Set position
        await engine.send(command: .position(.fen(position)))

        // Hint uses shallow depth for speed (terminal project: fast, doesn't burn user time)
        await engine.send(command: .go(depth: 8))

        // Wait for bestmove response (shorter timeout for hints)
        let startTime = Date()
        while currentBestMove == nil {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Shorter timeout for hints
            if Date().timeIntervalSince(startTime) > 10.0 {
                throw ChessEngineError.timeout
            }
        }

        return currentBestMove
    }

    // MARK: - Position Evaluation

    func evaluatePosition(position: String) async throws -> Int? {
        guard await isReady else {
            throw ChessEngineError.engineNotReady
        }

        guard let engine = engine else {
            throw ChessEngineError.initializationFailed("Engine not initialized")
        }

        // Reset current evaluation
        currentEvaluation = nil

        // Stop any ongoing analysis
        await engine.send(command: .stop)

        // Small delay
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // Set position
        await engine.send(command: .position(.fen(position)))

        // Evaluation uses deeper search for accuracy (terminal project: depth 15)
        await engine.send(command: .go(depth: 15))

        // Wait for evaluation response
        let startTime = Date()
        while currentEvaluation == nil {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Timeout check
            if Date().timeIntervalSince(startTime) > 20.0 {
                throw ChessEngineError.timeout
            }
        }

        return currentEvaluation
    }

    // MARK: - Private Methods

    /// Start listening to engine response stream.
    ///
    /// Parses UCI protocol responses and updates internal state:
    /// - `bestmove <move>` → Updates `currentBestMove`
    /// - `info ... score cp <centipawns>` → Updates `currentEvaluation`
    private func startResponseListener() {
        responseTask = Task { [weak self] in
            guard let self = self,
                  let engine = self.engine else {
                return
            }

            // responseStream is async property
            guard let stream = await engine.responseStream else {
                return
            }

            for await response in stream {
                self.handleEngineResponse(response)
            }
        }
    }

    /// Handle engine response and update internal state.
    private func handleEngineResponse(_ response: EngineResponse) {
        switch response {
        case .bestmove(let move, _):
            // Extract move string (terminal project: parse "bestmove e2e4")
            currentBestMove = move

        case .info(let info):
            // Extract evaluation score if available
            if let score = info.score {
                // Score can be centipawns (Double?) or mate (Int?)
                if let cp = score.cp {
                    // Centipawn score (terminal project: used for evaluation display)
                    // Convert Double to Int
                    currentEvaluation = Int(cp)
                } else if let mate = score.mate {
                    // Mate in N moves (terminal project: convert to large centipawn value)
                    // Positive = White mates, Negative = Black mates
                    currentEvaluation = mate > 0 ? 10000 : -10000
                }
            }

        default:
            // Ignore other responses (uciok, readyok, etc.)
            break
        }
    }

    /// Configure Stockfish neural network files if available in bundle.
    ///
    /// Stockfish 17 requires two NNUE files:
    /// - `nn-1111cefa1111.nnue` (EvalFile - larger, more accurate)
    /// - `nn-37f18f62d772.nnue` (EvalFileSmall - faster, lighter)
    ///
    /// These files must be added to the Xcode project's Resources.
    private func configureNeuralNetworks() async throws {
        guard let engine = engine else { return }

        // Look for neural network files in bundle
        let bundle = Bundle.main

        // Configure EvalFile (large network)
        if let evalFilePath = bundle.path(forResource: "nn-1111cefa1111", ofType: "nnue") {
            await engine.send(command: .setoption(id: "EvalFile", value: evalFilePath))
        } else {
            print("⚠️ Warning: nn-1111cefa1111.nnue not found in bundle. Stockfish will use default evaluation.")
        }

        // Configure EvalFileSmall (small network)
        if let evalFileSmallPath = bundle.path(forResource: "nn-37f18f62d772", ofType: "nnue") {
            await engine.send(command: .setoption(id: "EvalFileSmall", value: evalFileSmallPath))
        } else {
            print("⚠️ Warning: nn-37f18f62d772.nnue not found in bundle. Stockfish will use default evaluation.")
        }
    }
}

// MARK: - Centipawn Conversion (Terminal Project Parity)

extension StockfishEngine {
    /// Convert centipawn score to scaled score (-9 to +9).
    ///
    /// Matches `centipawns_to_scale()` from terminal project's `stockfish.c`.
    ///
    /// ## Conversion Table (from terminal project)
    /// - ±1000+ cp → ±9
    /// - ±700 cp → ±8
    /// - ±500 cp → ±7
    /// - ±400 cp → ±6
    /// - ±300 cp → ±5
    /// - ±200 cp → ±4
    /// - ±100 cp → ±3
    /// - ±50 cp → ±2
    /// - ±25 cp → ±1
    /// - 0 cp → 0
    ///
    /// - Parameter centipawns: Evaluation score in centipawns
    /// - Returns: Scaled score from -9 (Black winning) to +9 (White winning)
    static func centipawnsToScale(_ centipawns: Int) -> Int {
        let abs_cp = abs(centipawns)
        let sign = centipawns >= 0 ? 1 : -1

        let scale: Int
        if abs_cp >= 1000 {
            scale = 9
        } else if abs_cp >= 700 {
            scale = 8
        } else if abs_cp >= 500 {
            scale = 7
        } else if abs_cp >= 400 {
            scale = 6
        } else if abs_cp >= 300 {
            scale = 5
        } else if abs_cp >= 200 {
            scale = 4
        } else if abs_cp >= 100 {
            scale = 3
        } else if abs_cp >= 50 {
            scale = 2
        } else if abs_cp >= 25 {
            scale = 1
        } else {
            scale = 0
        }

        return sign * scale
    }
}
