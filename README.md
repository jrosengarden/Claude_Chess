# Chess Game with Stockfish AI

A complete chess implementation in C featuring:
- Full chess rules and piece movement
- Visual board display with move highlighting
- Capture tracking for both sides
- Check detection and restricted movement during check
- Stockfish AI engine integration for computer opponent
- Human vs AI gameplay (White vs Black)

## Features

- **Complete Chess Rules**: All standard chess piece movements, capturing, check detection, and castling (kingside and queenside)
- **Clean Single-Board UI**: Screen clears after each move showing only current game state
- **Undo Functionality**: Single-level undo to revert the last move pair (White + AI)
- **Visual Board**: Clear ASCII representation with coordinates (a-h, 1-8)
- **Move Visualization**: Shows possible moves with `*` for empty squares and `[piece]` for captures
- **Capture Tracking**: Displays "Black Has Captured:" and "White Has Captured:" with color-coded labels (ordered to match board layout)
- **Check Protection**: When king is in check, only allows moves that resolve the check
- **Castling Support**: Full kingside (O-O) and queenside (O-O-O) castling with proper rule validation
- **AI Integration**: Uses Stockfish engine for intelligent computer moves
- **Game State Detection**: Detects checkmate and stalemate conditions
- **Interactive Commands**: Help, hints, position analysis, undo, and game information
- **FEN to PGN Utility**: Standalone tool to convert FEN position files to PGN format (compatible with new FEN logging)

## Requirements

- GCC compiler (or compatible C compiler)
- Stockfish chess engine
- POSIX-compatible system (Linux, macOS, etc.)

## Installation

1. **Install Stockfish**:
   ```bash
   # On macOS with Homebrew
   brew install stockfish
   
   # On Ubuntu/Debian
   sudo apt update && sudo apt install stockfish
   
   # Or use the Makefile helper
   make install-deps
   ```

2. **Compile the game**:
   ```bash
   make
   ```
   This builds both the main chess game (`chess`) and the FEN to PGN utility (`fen_to_pgn`).

3. **Run the game**:
   ```bash
   make run
   # or directly
   ./chess
   
   # Run with debug output
   ./chess DEBUG
   ```

4. **Use the FEN to PGN utility**:
   ```bash
   ./fen_to_pgn
   ```
   The utility will prompt for a filename and create a PGN file with the same base name.
   **Note**: The utility now properly handles FEN files that include the initial board position.

## How to Play

1. **Starting the Game**: You play as White, AI plays as Black. The startup screen shows game information - press Enter to continue.
2. **Clean Interface**: The screen shows only the current game state with a single chess board at any time.
3. **Making Moves**: Enter moves in algebraic notation format: `e2 e4`. For castling, move the king two squares: `e1 g1` (kingside) or `e1 c1` (queenside). After each move, press Enter to continue.
4. **Undo Moves**: Type `undo` to revert both your last move and the AI's response. Only one level of undo is supported.
5. **Viewing Possible Moves**: Enter just a position (e.g., `e2`) to see highlighted moves on the board.
6. **Special Displays**:
   - `*` = Empty square you can move to
   - `[piece]` = Enemy piece you can capture
   - Check warnings appear when your king is threatened

## Game Controls

- `help` - Show help message
- `hint` - Get Stockfish's best move suggestion for White
- `fen` - Display current board position in FEN notation
- `title` - Re-display the game title and startup information
- `undo` - Undo the last move pair (White + AI moves) - single level only
- `quit` - Exit the game
- `e2 e4` - Move from e2 to e4
- `e2` - Show possible moves from e2

**Note**: All commands pause after displaying information, allowing you to read the output before returning to the game board.

## Board Representation

```
    a b c d e f g h
  +----------------+
8 | r n b q k b n r | 8
7 | p p p p p p p p | 7
6 | . . . . . . . . | 6
5 | . . . . . . . . | 5
4 | . . . . . . . . | 4
3 | . . . . . . . . | 3
2 | P P P P P P P P | 2
1 | R N B Q K B N R | 1
  +----------------+
    a b c d e f g h
```

- **Uppercase = White pieces** (displayed in bold magenta)
- **Lowercase = Black pieces** (displayed in bold cyan)
- `.` = Empty square

## FEN Position Logging

Every game automatically creates a timestamped FEN log file:
- **Filename format**: `CHESS_mmddyy_HHMMSS.fen` (e.g., `CHESS_090725_143022.fen`)
- **Complete game history**: Each board state is appended after every half-move (one FEN per line)  
- **Session tracking**: Each game gets its own unique timestamped log file
- **Always enabled**: Available for all games for analysis and review
- **FEN to PGN compatible**: Files include initial position and work directly with the conversion utility
- Enables step-by-step examination of game progression and position analysis

## Debug Mode

Run the game with `./chess DEBUG` to enable debug output that shows:
- Raw Stockfish move strings (e.g., "e7e5") 
- Parsed move coordinates for AI moves and hints
- Additional diagnostic information during gameplay
- FEN logging confirmation messages

This is useful for development and troubleshooting engine communication.

## Testing

The project includes an automated test suite for castling functionality:

```bash
# Run castling tests
./test_castling.sh
```

**Test Coverage:**
- ✅ **Kingside Castling**: Verifies e1→g1 king movement with rook repositioning
- ✅ **Castling Prevention**: Ensures castling blocked after king/rook moves  
- 🔄 **Queenside Castling**: Tests e1→c1 movement (may be AI-dependent)
- 🔄 **Move Display**: Verifies castling moves appear in possible moves list

Tests are designed for regression testing to ensure castling functionality remains stable across code changes.

## Files

- `chess.h/chess.c` - Core chess logic and move validation
- `stockfish.h/stockfish.c` - Stockfish AI engine integration  
- `main.c` - Game loop and user interface
- `fen_to_pgn.c` - Standalone FEN to PGN conversion utility (updated for new FEN logging compatibility)
- `Makefile` - Build configuration (builds both chess game and fen_to_pgn utility)
- `test_castling.sh` - Automated test suite for castling functionality
- `CLAUDE.md` - Development notes and technical documentation

## Troubleshooting

1. **Stockfish not found**: Ensure Stockfish is installed and in your PATH
2. **Compilation errors**: Make sure you have GCC and development tools installed  
3. **Permission errors**: Ensure the compiled binary has execute permissions

## Development

For technical details, architecture information, and development notes, see `CLAUDE.md`.

## License

This is a demonstration chess implementation. Stockfish is licensed under GPL v3.