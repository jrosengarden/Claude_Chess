//
//  StockfishEngine.swift
//  Claude_Chess
//
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

    // MARK: - Singleton

    /// Shared singleton instance to prevent multiple Stockfish processes.
    ///
    /// ChessKitEngine's Stockfish process appears to be a singleton at the system level.
    /// Only one Stockfish instance can run at a time. Multiple instances interfere with
    /// each other, causing timeouts and unresponsive behavior.
    ///
    /// This singleton pattern ensures:
    /// - Only one StockfishEngine instance exists
    /// - The engine can be reused across different game sessions
    /// - No resource conflicts between multiple engine instances
    static let shared = StockfishEngine()

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

    /// Engine version string (captured from UCI "id name" response)
    private var engineVersion: String = "Unknown"

    // MARK: - ChessEngine Protocol Conformance

    let engineName: String = "Stockfish"

    let requiresInternet: Bool = false

    var isReady: Bool {
        get async {
            return initialized && engine != nil
        }
    }

    // MARK: - Initialization

    private init() {
        // Private init to enforce singleton pattern
        // Engine will be initialized in initialize()
    }

    deinit {
        // Emergency cleanup if shutdown() wasn't called
        // Note: Can't use async in deinit, but cancel the task
        responseTask?.cancel()
    }

    func initialize() async throws {
        // Prevent multiple initializations
        if initialized {
            print("⚠️ Warning: Engine already initialized. Shutting down first...")
            await shutdown()
        }

        // Ensure any previous engine is fully cleaned up
        if engine != nil {
            await shutdown()
        }

        // Create Stockfish engine
        engine = Engine(type: .stockfish)

        guard let engine = engine else {
            throw ChessEngineError.initializationFailed("Failed to create engine instance")
        }

        // Start response stream listener
        startResponseListener()

        // Start engine
        await engine.start()

        // Give engine more time to start (500ms instead of 100ms)
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // Send UCI initialization commands
        await engine.send(command: .uci)

        // Wait for engine to process UCI command
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        await engine.send(command: .isready)

        // Wait for engine to be ready
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Configure neural network files if available
        try await configureNeuralNetworks()

        // Mark as initialized before setting skill level
        initialized = true

        // Set default skill level (requires initialized = true)
        try await setSkillLevel(skillLevel)
    }

    func shutdown() async {
        // Mark as not initialized first
        initialized = false

        // Stop response listener first
        responseTask?.cancel()
        responseTask = nil

        // Give the task time to actually cancel
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Quit engine with proper cleanup
        if let engine = engine {
            // Send quit command
            await engine.send(command: .quit)

            // Wait for engine to process quit
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

            // Force stop the engine process
            await engine.stop()

            // Additional wait to ensure process termination
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        engine = nil

        // Reset state
        currentBestMove = nil
        currentEvaluation = nil
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

    /// Get engine version string.
    ///
    /// Returns the version information captured from UCI "id name" response
    /// during initialization (e.g., "Stockfish 17").
    ///
    /// - Returns: Engine version string
    func getEngineVersion() -> String {
        return engineVersion
    }

    // MARK: - Move Generation

    func getBestMove(position: String, timeLimit: Int?) async throws -> String? {
        guard await isReady else {
            throw ChessEngineError.engineNotReady
        }

        guard let engine = engine else {
            throw ChessEngineError.initializationFailed("Engine not initialized")
        }

        // Stop any ongoing analysis and clear stale responses
        await engine.send(command: .stop)

        // Wait for stop to process and for any pending bestmove to arrive
        // This ensures we flush out stale responses from previous position
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Reset current best move (after stale responses have been discarded)
        currentBestMove = nil

        // Set position
        await engine.send(command: .position(.fen(position)))

        // Send go command based on time limit
        if let timeLimit = timeLimit {
            // Time-based search (terminal project: uses 1/20th of remaining time)
            await engine.send(command: .go(movetime: timeLimit))
        } else {
            // Depth-based search with skill-adjusted depth (terminal project behavior)
            // Lower skill levels use shallower depth for more realistic play
            let searchDepth = calculateSearchDepth(for: skillLevel)
            await engine.send(command: .go(depth: searchDepth))
        }

        // Wait for bestmove response (timeout after 30 seconds)
        let startTime = Date()
        while currentBestMove == nil {
            // Check if engine was shut down during wait
            guard initialized else {
                print("⚠️ Engine shut down during getBestMove() wait")
                return nil
            }

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
            // Check if engine was shut down during wait
            guard initialized else {
                print("⚠️ Engine shut down during getHint() wait")
                return nil
            }

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
            // Check if engine was shut down during wait
            guard initialized else {
                print("⚠️ Engine shut down during evaluatePosition() wait")
                return nil
            }

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

            // Listen for responses with cancellation support
            for await response in stream {
                // Check if task was cancelled
                if Task.isCancelled {
                    break
                }

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

        case .id(.name(let engineName)):
            // Capture engine version from UCI "id name" response
            engineVersion = engineName
            print("✅ Detected engine: \(engineName)")

        case .id(.author(let authorName)):
            // Capture author information (optional, for future use)
            print("ℹ️ Engine author: \(authorName)")

        default:
            // Ignore other responses (uciok, readyok, etc.)
            break
        }
    }

    /// Calculate search depth based on skill level.
    ///
    /// Lower skill levels use shallower depth for more realistic play and faster moves.
    /// Matches terminal project behavior where skill affects both UCI setting and search depth.
    ///
    /// ## Depth Mapping
    /// - Skill 0-5: Depth 1-3 (beginner, fast and weak)
    /// - Skill 6-10: Depth 4-6 (casual player)
    /// - Skill 11-15: Depth 7-10 (intermediate)
    /// - Skill 16-20: Depth 11-15 (advanced to maximum)
    ///
    /// - Parameter skillLevel: Skill level (0-20)
    /// - Returns: Search depth (1-15 plies)
    private func calculateSearchDepth(for skillLevel: Int) -> Int {
        switch skillLevel {
        case 0...2:
            return 1  // Beginner - very weak, instant moves
        case 3...5:
            return 3  // Beginner+ - weak but sees basic tactics
        case 6...8:
            return 5  // Casual - decent moves, some mistakes
        case 9...11:
            return 7  // Intermediate - solid play
        case 12...14:
            return 9  // Intermediate+ - strong play
        case 15...17:
            return 11  // Advanced - very strong
        case 18...19:
            return 13  // Expert - nearly perfect
        case 20:
            return 15  // Maximum - full strength
        default:
            return 5  // Fallback
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
