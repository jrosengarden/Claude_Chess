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

    /// Maximum depth seen for current evaluation (terminal project: only use deepest depth)
    private var currentEvaluationDepth: Int = 0

    /// Generation counter to track which bestmove responses are valid
    /// Increments every time we start a new move search to invalidate stale responses
    private var requestGeneration: Int = 0

    /// The generation number of the most recent bestmove response received
    private var responseGeneration: Int = 0

    /// Generation counter to track which evaluation responses are valid
    /// Increments every time we start a new evaluation to invalidate stale responses
    private var evalRequestGeneration: Int = 0

    /// The generation number of the most recent evaluation response received
    private var evalResponseGeneration: Int = 0

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

        // Brief delay for engine startup (reduced from 500ms)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Send UCI initialization commands
        await engine.send(command: .uci)

        // Brief delay for UCI processing (reduced from 200ms)
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        await engine.send(command: .isready)

        // Brief delay for readyok response (reduced from 200ms)
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

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

        // Brief delay for task cancellation (reduced from 100ms)
        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms

        // Quit engine with proper cleanup
        if let engine = engine {
            // Send quit command
            await engine.send(command: .quit)

            // Brief delay for quit processing (reduced from 200ms)
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

            // Force stop the engine process
            await engine.stop()

            // Brief delay for process termination (reduced from 100ms)
            try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
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

        // Reset current best move
        currentBestMove = nil

        // Stop any ongoing analysis
        await engine.send(command: .stop)

        // Delay to let stop command process fully (increased from 20ms to ensure engine clears state)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Set position
        await engine.send(command: .position(.fen(position)))

        // Small delay to ensure position is fully processed before sending go command
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // Increment generation BEFORE sending go command
        // This ensures any stale responses arriving after this point will have wrong generation
        requestGeneration += 1
        let expectedGeneration = requestGeneration

        // Send go command based on time limit
        if let timeLimit = timeLimit {
            // Time-based search (terminal project: uses 1/20th of remaining time)
            await engine.send(command: .go(movetime: timeLimit))
        } else {
            // Depth-based search (terminal project: fixed depth 10, skill controlled by UCI option)
            // Stockfish's "Skill Level" UCI option handles strength variation internally
            // Using consistent depth ensures Stockfish can see tactics and choose when to make mistakes
            await engine.send(command: .go(depth: 10))
        }

        // Wait for bestmove response from THIS generation (timeout after 30 seconds)
        // Only accept responses matching expectedGeneration to ignore stale results
        let startTime = Date()
        while currentBestMove == nil || responseGeneration != expectedGeneration {
            // Check if engine was shut down during wait
            guard initialized else {
                return nil
            }

            // Much shorter polling interval for faster response (reduced from 100ms)
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms

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

        // Delay to let stop command process (increased from 10ms)
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // Set position
        await engine.send(command: .position(.fen(position)))

        // Increment generation BEFORE sending go command
        requestGeneration += 1
        let expectedGeneration = requestGeneration

        // Hint uses shallow depth for speed (terminal project: fast, doesn't burn user time)
        await engine.send(command: .go(depth: 8))

        // Wait for bestmove response from THIS generation (shorter timeout for hints)
        let startTime = Date()
        while currentBestMove == nil || responseGeneration != expectedGeneration {
            // Check if engine was shut down during wait
            guard initialized else {
                return nil
            }

            // Faster polling for hints (reduced from 100ms)
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms

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

        // Reset current evaluation and depth tracking
        currentEvaluation = nil
        currentEvaluationDepth = 0

        // Stop any ongoing analysis
        await engine.send(command: .stop)

        // Delay to let stop command process (increased from 10ms)
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // CRITICAL FIX: Temporarily set skill to maximum (20) for accurate evaluation
        // Terminal project evaluates at full strength regardless of play skill level
        // This prevents unreliable/varying evaluations from low skill levels (Session 25 bug fix)
        let savedSkillLevel = skillLevel
        if savedSkillLevel < 20 {
            await engine.send(command: .setoption(id: "Skill Level", value: "20"))
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms for setting to apply
        }

        // Set position
        await engine.send(command: .position(.fen(position)))

        // Increment generation BEFORE sending go command
        evalRequestGeneration += 1
        let expectedGeneration = evalRequestGeneration

        // Evaluation uses deeper search for accuracy (terminal project: depth 15)
        await engine.send(command: .go(depth: 15))

        // Wait for evaluation response from THIS generation
        // AND wait for depth 15 to be reached (terminal project behavior)
        let startTime = Date()
        while currentEvaluation == nil || evalResponseGeneration != expectedGeneration || currentEvaluationDepth < 15 {
            // Check if engine was shut down during wait
            guard initialized else {
                return nil
            }

            // Faster polling (reduced from 100ms)
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms

            // Timeout check
            if Date().timeIntervalSince(startTime) > 20.0 {
                break  // Use whatever depth we got instead of failing completely
            }
        }

        // Restore original skill level for gameplay
        if savedSkillLevel < 20 {
            await engine.send(command: .setoption(id: "Skill Level", value: "\(savedSkillLevel)"))
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms for setting to apply
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
            // Update the move AND mark this response with current request generation
            currentBestMove = move
            responseGeneration = requestGeneration

        case .info(let info):
            // Extract evaluation score if available
            // Terminal project: only use score from deepest depth to ensure most accurate evaluation
            if let score = info.score, let depth = info.depth {
                // Only update evaluation if this depth is >= current max depth
                if depth >= currentEvaluationDepth {
                    currentEvaluationDepth = depth

                    // Score can be centipawns (Double?) or mate (Int?)
                    if let cp = score.cp {
                        // Centipawn score (terminal project: used for evaluation display)
                        // Convert Double to Int
                        currentEvaluation = Int(cp)
                        // Mark this evaluation with current request generation
                        evalResponseGeneration = evalRequestGeneration
                    } else if let mate = score.mate {
                        // Mate in N moves (terminal project: convert to large centipawn value)
                        // Positive = White mates, Negative = Black mates
                        currentEvaluation = mate > 0 ? 10000 : -10000
                        // Mark this evaluation with current request generation
                        evalResponseGeneration = evalRequestGeneration
                    }
                }
            }

        case .id(.name(let engineName)):
            // Capture engine version from UCI "id name" response
            engineVersion = engineName

        case .id(.author):
            // Capture author information (optional, for future use)
            break

        default:
            // Ignore other responses (uciok, readyok, etc.)
            break
        }
    }

    /// Calculate search depth based on skill level.
    ///
    /// **DEPRECATED - NO LONGER USED**
    ///
    /// This function is retained for reference only. Current implementation uses FIXED depth 10
    /// matching the terminal project. Variable depth was causing all skill levels to play
    /// identically because shallow depths (1-3) don't have enough move diversity for Stockfish's
    /// "Skill Level" UCI option to work effectively.
    ///
    /// **Correct approach (terminal project parity):**
    /// - Set UCI "Skill Level" option to 0-20 (done in setSkillLevel())
    /// - Use FIXED depth 10 for all moves (done in getBestMove())
    /// - Let Stockfish's internal algorithm decide when to make mistakes
    ///
    /// ## Old Depth Mapping (NOT USED)
    /// - Skill 0-5: Depth 1-3 (beginner, fast and weak)
    /// - Skill 6-10: Depth 4-6 (casual player)
    /// - Skill 11-15: Depth 7-10 (intermediate)
    /// - Skill 16-20: Depth 11-15 (advanced to maximum)
    ///
    /// - Parameter skillLevel: Skill level (0-20)
    /// - Returns: Search depth (1-15 plies) - NOT USED, always depth 10 now
    @available(*, deprecated, message: "Use fixed depth 10 with UCI Skill Level option instead")
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
        }

        // Configure EvalFileSmall (small network)
        if let evalFileSmallPath = bundle.path(forResource: "nn-37f18f62d772", ofType: "nnue") {
            await engine.send(command: .setoption(id: "EvalFileSmall", value: evalFileSmallPath))
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
