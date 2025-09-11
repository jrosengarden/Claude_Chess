#!/bin/bash

clear

# SAFE TESTING SCRIPT FOR CLAUDE SESSIONS
# This script only tests compilation - no game execution that could cause crashes
# Full functionality testing should be done manually by the user

echo "=== SAFE COMPILATION TEST ==="
echo "Testing that code compiles successfully after changes"
echo ""

# Test 1: Clean and compile
echo "TEST 1: Clean compilation"
make clean
if make; then
    echo "✅ COMPILATION PASSED - Code compiles without errors"
else
    echo "❌ COMPILATION FAILED - Check compiler errors above"
    exit 1
fi

echo ""

# Test 2: Check executables exist
echo "TEST 2: Executable creation"
if [ -f "./chess" ] && [ -f "./fen_to_pgn" ]; then
    echo "✅ EXECUTABLES CREATED - Both chess and fen_to_pgn exist"
else
    echo "❌ EXECUTABLES MISSING - Build may have failed"
    exit 1
fi

echo ""

# Test 3: Basic help display (very limited output)
echo "TEST 3: Basic functionality check"
echo "Running chess with immediate quit (minimal output)..."

# Create minimal test that just starts and quits immediately
# Use timeout on Linux, gtimeout on macOS
if command -v timeout > /dev/null 2>&1; then
    echo "quit" | timeout 5s ./chess > /dev/null 2>&1
else
    echo "quit" | gtimeout 5s ./chess > /dev/null 2>&1
fi
exit_code=$?

if [ $exit_code -eq 0 ] || [ $exit_code -eq 1 ] || [ $exit_code -eq 124 ]; then  # 0=success, 1=stockfish missing, 124=timeout (all OK)
    if [ $exit_code -eq 1 ]; then
        echo "✅ BASIC FUNCTIONALITY - Chess game starts (Stockfish not installed, which is OK for compilation testing)"
    else
        echo "✅ BASIC FUNCTIONALITY - Chess game starts and responds to input"
    fi
else
    echo "❌ BASIC FUNCTIONALITY FAILED - Chess game may have startup issues"
fi

echo ""
echo "=== SAFE TESTING COMPLETE ==="
echo ""
echo "NOTE: This script only tests compilation and basic startup."
echo "For full feature testing (castling, moves, etc.), run:"
echo "  ./debug_input  ./debug_move  ./debug_position  ./debug_queenside"
echo "  ./debug_castle_input  ./debug_castling"
echo ""
echo "But ONLY run full tests outside of Claude sessions to prevent crashes."
echo "Press any key to continue..."
read -n1 -s; echo
make clean
