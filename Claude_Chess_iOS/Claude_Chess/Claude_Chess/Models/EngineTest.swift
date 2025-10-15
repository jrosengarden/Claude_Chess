//
//  EngineTest.swift
//  Claude_Chess
//
//

import Foundation

/// Test utilities for verifying Stockfish engine integration.
///
/// This file contains simple test functions to verify that:
/// - The engine initializes correctly
/// - Neural network files are found
/// - The engine can generate moves
/// - The engine can evaluate positions
///
/// These tests can be called from a button in the UI during development.
@MainActor
class EngineTest {

    /// Run a comprehensive test of the Stockfish engine.
    ///
    /// This test:
    /// 1. Creates and initializes the engine
    /// 2. Sets a skill level
    /// 3. Requests a move for the starting position
    /// 4. Requests a position evaluation
    /// 5. Tests the hint system
    ///
    /// - Returns: A string describing test results
    static func runEngineTest() async -> String {
        var results = "🧪 Stockfish Engine Test\n\n"

        // Test 1: Engine Initialization
        results += "1️⃣ Testing engine initialization...\n"
        let engine = StockfishEngine()

        do {
            try await engine.initialize()
            results += "   ✅ Engine initialized successfully\n"
            results += "   Engine: \(engine.engineName)\n"
            results += "   Requires Internet: \(engine.requiresInternet)\n\n"
        } catch {
            results += "   ❌ Initialization failed: \(error.localizedDescription)\n"
            return results
        }

        // Test 2: Skill Level
        results += "2️⃣ Testing skill level configuration...\n"
        do {
            try await engine.setSkillLevel(10)
            results += "   ✅ Skill level set to 10 (Intermediate)\n\n"
        } catch {
            results += "   ❌ Failed to set skill level: \(error.localizedDescription)\n\n"
        }

        // Test 3: Get Best Move
        results += "3️⃣ Testing move generation...\n"
        let startingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

        do {
            if let move = try await engine.getBestMove(position: startingFEN, timeLimit: nil) {
                results += "   ✅ Engine suggests move: \(move)\n"
                results += "   (Using depth-based search)\n\n"
            } else {
                results += "   ⚠️ Engine returned no move\n\n"
            }
        } catch {
            results += "   ❌ Move generation failed: \(error.localizedDescription)\n\n"
        }

        // Test 4: Position Evaluation
        results += "4️⃣ Testing position evaluation...\n"
        do {
            if let eval = try await engine.evaluatePosition(position: startingFEN) {
                results += "   ✅ Position evaluation: \(eval) centipawns\n"
                let scaled = StockfishEngine.centipawnsToScale(eval)
                results += "   Scaled score: \(scaled) (-9 to +9)\n\n"
            } else {
                results += "   ⚠️ No evaluation returned\n\n"
            }
        } catch {
            results += "   ❌ Evaluation failed: \(error.localizedDescription)\n\n"
        }

        // Test 5: Hint System
        results += "5️⃣ Testing hint system...\n"
        do {
            if let hint = try await engine.getHint(position: startingFEN) {
                results += "   ✅ Hint move: \(hint)\n"
                results += "   (Fast depth-based search)\n\n"
            } else {
                results += "   ⚠️ No hint returned\n\n"
            }
        } catch {
            results += "   ❌ Hint failed: \(error.localizedDescription)\n\n"
        }

        // Test 6: Shutdown
        results += "6️⃣ Testing engine shutdown...\n"
        await engine.shutdown()
        results += "   ✅ Engine shut down successfully\n\n"

        results += "✅ All tests completed!"

        return results
    }

    /// Quick test - just verify engine can be initialized and generate one move.
    static func quickTest() async -> String {
        let engine = StockfishEngine()

        do {
            try await engine.initialize()
            try await engine.setSkillLevel(5)

            let startingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
            if let move = try await engine.getBestMove(position: startingFEN, timeLimit: nil) {
                await engine.shutdown()
                return "✅ Stockfish working! Suggested move: \(move)"
            } else {
                await engine.shutdown()
                return "❌ No move returned"
            }
        } catch {
            await engine.shutdown()
            return "❌ Error: \(error.localizedDescription)"
        }
    }
}
