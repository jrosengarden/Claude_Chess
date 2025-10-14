//
//  ChessEngine.swift
//  Claude_Chess
//
//  Created by Claude Code on 10/14/25.
//

import Foundation

/// Protocol defining the interface for chess engines (Stockfish, Lichess,
/// Chess.com).
///
/// This protocol abstracts chess engine communication, allowing the app to
/// support multiple engines with a unified interface. Conforming types handle
/// UCI protocol communication, move generation, position evaluation, and hints.
///
/// ## Terminal Project Parity
/// Matches the behavior of `stockfish.c` from the terminal project:
/// - `getBestMove()` → `get_best_move()`
/// - `getHint()` → `get_hint_move()`
/// - `evaluatePosition()` → `get_position_evaluation()`
/// - `setSkillLevel()` → `set_skill_level()`
///
/// ## Supported Engines
/// - **Stockfish**: Native offline engine (UCI protocol, skill 0-20)
/// - **Lichess**: Cloud-based API (future Phase 4)
/// - **Chess.com**: Cloud-based API (future Phase 4)
protocol ChessEngine {

    // MARK: - Engine Properties

    /// Human-readable engine name (e.g., "Stockfish", "Lichess", "Chess.com")
    var engineName: String { get }

    /// Whether this engine requires internet connectivity
    var requiresInternet: Bool { get }

    /// Whether the engine is currently initialized and ready for commands
    var isReady: Bool { get async }

    // MARK: - Initialization

    /// Initialize the engine and prepare for UCI communication.
    ///
    /// For Stockfish: Starts engine process, sends `uci` and `isready` commands
    /// For API engines: Establishes network connection, validates API credentials
    ///
    /// - Throws: `ChessEngineError` if initialization fails
    func initialize() async throws

    /// Shutdown the engine and clean up resources.
    ///
    /// Sends `quit` command to UCI engines, closes network connections for APIs.
    func shutdown() async

    // MARK: - Configuration

    /// Set the engine's skill level or playing strength.
    ///
    /// **Stockfish**: Maps to UCI "Skill Level" option (0-20)
    /// - 0 = Beginner (~800 Elo)
    /// - 10 = Intermediate (~1500 Elo)
    /// - 20 = Maximum strength (~3500 Elo)
    ///
    /// **API engines**: Maps skill level to appropriate rating/difficulty
    ///
    /// ## Terminal Project Behavior
    /// Matches `set_skill_level()` from terminal project's `stockfish.c`.
    /// Sends UCI command: `setoption name Skill Level value <level>`
    ///
    /// - Parameter level: Skill level (0-20 for Stockfish, engine-specific otherwise)
    /// - Throws: `ChessEngineError` if command fails
    func setSkillLevel(_ level: Int) async throws

    // MARK: - Move Generation

    /// Get the engine's best move for the current position.
    ///
    /// This is the primary method for AI opponent moves. The engine analyzes
    /// the position and returns its chosen move in UCI notation (e.g., "e2e4",
    /// "e7e8q" for promotion).
    ///
    /// ## Terminal Project Behavior
    /// Matches `get_best_move()` from terminal project's `stockfish.c`:
    /// - Sends `position fen <fen_string>`
    /// - Sends `go depth 10` (if time controls disabled) OR
    ///   `go movetime <milliseconds>` (if time controls enabled)
    /// - Parses `bestmove <move>` response
    ///
    /// ## Search Modes
    /// - **Depth-based**: Fast, consistent (time controls disabled)
    /// - **Time-based**: Uses allocated time (time controls enabled)
    ///
    /// - Parameters:
    ///   - position: FEN string representing the current board position
    ///   - timeLimit: Optional time limit in milliseconds (nil = depth-based search)
    /// - Returns: Best move in UCI notation (e.g., "e2e4", "a7a8q"), or nil if no legal moves
    /// - Throws: `ChessEngineError` if engine communication fails
    func getBestMove(position: String, timeLimit: Int?) async throws -> String?

    /// Get a hint move for the current position (fast, shallow search).
    ///
    /// Used for the hint feature. Uses depth-based search (typically depth 5-10)
    /// to provide quick suggestions without consuming the player's time.
    ///
    /// ## Terminal Project Behavior
    /// Matches `get_hint_move()` from terminal project's `stockfish.c`:
    /// - Always uses depth-based search (never time-based)
    /// - Faster than `getBestMove()` for instant feedback
    /// - Does not burn user's time allocation
    ///
    /// - Parameter position: FEN string representing the current board position
    /// - Returns: Hint move in UCI notation, or nil if position is terminal
    /// - Throws: `ChessEngineError` if engine communication fails
    func getHint(position: String) async throws -> String?

    // MARK: - Position Evaluation

    /// Evaluate the current position and return a score.
    ///
    /// Returns the engine's evaluation of the position in centipawns
    /// (hundredths of a pawn). Positive = White advantage, Negative = Black advantage.
    ///
    /// ## Terminal Project Behavior
    /// Matches `get_position_evaluation()` from terminal project's `stockfish.c`:
    /// - Sends `position fen <fen_string>`
    /// - Sends `go depth 15` (deeper than moves for accuracy)
    /// - Parses `info ... score cp <centipawns>` response
    ///
    /// ## Score Interpretation
    /// - `+100` = White ahead by 1 pawn
    /// - `0` = Equal position
    /// - `-300` = Black ahead by 3 pawns
    /// - `+10000` = White has forced checkmate
    ///
    /// Terminal project converts to scaled score (-9 to +9) using
    /// `centipawns_to_scale()`.
    ///
    /// - Parameter position: FEN string representing the current board position
    /// - Returns: Evaluation score in centipawns, or nil if unavailable
    /// - Throws: `ChessEngineError` if engine communication fails
    func evaluatePosition(position: String) async throws -> Int?
}

// MARK: - Chess Engine Errors

/// Errors that can occur during chess engine operations.
enum ChessEngineError: Error, LocalizedError {
    case initializationFailed(String)
    case engineNotReady
    case communicationFailed(String)
    case invalidResponse(String)
    case networkError(String)
    case timeout
    case unsupportedOperation(String)

    var errorDescription: String? {
        switch self {
        case .initializationFailed(let reason):
            return "Engine initialization failed: \(reason)"
        case .engineNotReady:
            return "Engine is not ready. Call initialize() first."
        case .communicationFailed(let reason):
            return "Engine communication failed: \(reason)"
        case .invalidResponse(let response):
            return "Invalid engine response: \(response)"
        case .networkError(let reason):
            return "Network error: \(reason)"
        case .timeout:
            return "Engine response timeout"
        case .unsupportedOperation(let operation):
            return "Unsupported operation: \(operation)"
        }
    }
}
