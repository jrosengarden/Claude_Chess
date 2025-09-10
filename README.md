# Chess Game with Stockfish AI

A complete chess implementation in C featuring:
- Full chess rules and piece movement
- Visual board display with move highlighting
- Capture tracking for both sides
- Check detection and restricted movement during check
- Stockfish AI engine integration for computer opponent
- Human vs AI gameplay (White vs Black)

## Features

- **Complete Chess Rules**: All standard chess piece movements, 
  capturing, check detection, and castling (kingside and queenside)
- **Clean Single-Board UI**: Screen clears after each move showing only 
  current game state
- **Unlimited Undo Functionality**: Unlimited undo to revert any number of 
  move pairs using FEN log-based restoration
- **Visual Board**: Clear ASCII representation with coordinates (a-h, 1-8)
- **Move Visualization**: Shows possible moves with `*` for empty squares 
  and highlighted pieces for captures
- **Capture Tracking**: Displays "Black Has Captured:" and "White Has 
  Captured:" with color-coded labels (ordered to match board layout)
- **Check Protection**: When king is in check, only allows moves that 
  resolve the check
- **Castling Support**: Full kingside (O-O) and queenside (O-O-O) 
  castling with proper rule validation
- **AI Integration**: Uses Stockfish engine for intelligent computer moves
- **Game State Detection**: Detects checkmate and stalemate conditions
- **Interactive Commands**: Help, hints, position analysis, undo, custom 
  board setup, and game information
- **Custom Board Setup**: Setup any chess position using FEN notation 
  with the SETUP command
- **FEN Logging**: FEN logging to file (based on date & time at game 
  start) for all moves
- **Automatic PGN Generation**: Automatically converts FEN logs to PGN 
  format on game exit (quit, checkmate, stalemate)
- **File Notification**: Shows generated FEN and PGN filenames when games 
  end so users know where their game records are saved
- **FEN to PGN Utility**: Standalone tool to convert FEN position files 
  to PGN format (compatible with new FEN logging)

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
   This builds both the main chess game (`chess`) and the FEN to PGN 
   utility (`fen_to_pgn`).

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
   The utility will prompt for a filename and create a PGN file with 
   the same base name.
   **Note**: The utility now properly handles FEN files that include 
   the initial board position.

## How to Play

1. **Starting the Game**: You play as White, AI plays as Black. The 
   startup screen shows game information - press Enter to continue.
2. **Clean Interface**: The screen shows only the current game state 
   with a single chess board at any time.
3. **Making Moves**: Enter moves in algebraic notation format: `e2 e4`. 
   For castling, move the king two squares: `e1 g1` (kingside) or 
   `e1 c1` (queenside). After each move, press Enter to continue.
4. **Custom Board Setup**: Type `setup` to enter a FEN string and 
   configure any chess position. The game will continue from your custom 
   position with a new FEN log file.
5. **Unlimited Undo**: Type `undo` to revert any number of move pairs. 
   You can undo back to the beginning of the game. The system will ask 
   how many move pairs to undo if multiple are available.
6. **Viewing Possible Moves**: Enter just a position (e.g., `e2`) to see 
   highlighted moves on the board.
7. **Special Displays**:
   - `*` = Empty square you can move to
   - highlighted piece = Enemy piece you can capture (inverted colors)
   - Check warnings appear when your king is threatened

## Game Controls

- `help` - Show help message
- `hint` - Get Stockfish's best move suggestion for White
- `fen` - Display current board position in FEN notation
- `title` - Re-display the game title and startup information
- `setup` - Setup custom board position from FEN string (creates new 
  FEN log file)
- `undo` - Unlimited undo of move pairs using FEN log restoration 
  (can undo back to game start)
- `resign` - Resign the game (with YES/NO confirmation)
- `quit` - Exit the game
- `e2 e4` - Move from e2 to e4
- `e2` - Show possible moves from e2

**Note**: All commands pause after displaying information, allowing you to 
read the output before returning to the game board.

## Custom Board Setup (SETUP Command)

The SETUP command allows you to configure any chess position using FEN 
(Forsyth-Edwards Notation):

1. **Usage**: Type `setup` during White's turn
2. **FEN Input**: Enter a valid FEN string when prompted
3. **Automatic Management**: 
   - Current FEN log file is deleted
   - New timestamped FEN log file is created
   - Game continues from your custom position
4. **FEN Format**: Standard FEN notation including board position, active 
   player, castling rights, en passant, and move counts

**Example FEN Strings:**
- Starting position: 
  `rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1`
- Italian Game: 
  `r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 4 4`
- Empty board: `8/8/8/8/8/8/8/8 w - - 0 1`

**Validation**: Invalid FEN strings are rejected with helpful error 
messages.

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

## Game History and File Generation

### FEN Position Logging
Every game automatically creates a timestamped FEN log file:
- **Filename format**: `CHESS_mmddyy_HHMMSS.fen` 
  (e.g., `CHESS_090725_143022.fen`)
- **Complete game history**: Each board state is appended after every 
  half-move (one FEN per line)
- **Accurate FEN notation**: Includes proper halfmove clock and fullmove 
  number tracking according to chess standards
- **Session tracking**: Each game gets its own unique timestamped log file
- **Always enabled**: Available for all games for analysis and review - 
  operates silently in background
- **Never deleted**: FEN files persist after games end - new games create 
  new timestamped files
- **Undo synchronization**: When undo command is used, the FEN file is 
  automatically truncated to match the reverted game state
- **SETUP preservation**: Custom board positions via SETUP command 
  correctly preserve original halfmove clock and fullmove numbers

### Automatic PGN Generation
When any game ends (quit, checkmate, or stalemate), the system 
automatically:
- **Silent conversion**: Converts the session's FEN log to PGN format 
  without user prompts
- **Matching filenames**: Creates PGN file with same base name as FEN file 
  (e.g., `CHESS_090725_143022.pgn`)
- **Standard format**: Generates proper PGN with headers, move notation, 
  and algebraic notation
- **No manual steps**: Happens automatically - no need to run separate 
  utility
- **Both formats preserved**: You get both FEN log for position analysis 
  and PGN for sharing/importing
- **File notification**: Shows both generated filenames so you know exactly 
  where your game records are saved

### Manual FEN to PGN Conversion
For older FEN files or manual conversion, use the standalone utility:
- **FEN to PGN compatible**: All FEN files include initial position and 
  work directly with the conversion utility
- Enables step-by-step examination of game progression and position 
  analysis

### FEN Notation Accuracy
The game now implements complete FEN notation standards:
- **Halfmove Clock**: Automatically tracks halfmoves since last pawn move 
  or capture (resets to 0 on pawn moves/captures, increments on piece moves)
- **Fullmove Number**: Correctly increments after each Black move 
  (standard chess move pair counting)
- **SETUP Command**: Preserves exact halfmove clock and fullmove numbers 
  from input FEN strings (no longer resets to "0 1")
- **Standards Compliant**: All generated FEN strings follow official 
  Forsyth-Edwards Notation specification
- **50-Move Rule Ready**: Halfmove clock tracking prepares for future 
  automatic draw detection implementation

## Debug Mode

Run the game with `./chess DEBUG` to enable debug output that shows:
- Raw Stockfish move strings (e.g., "e7e5")
- Parsed move coordinates for AI moves and hints
- Additional diagnostic information during gameplay

This is useful for development and troubleshooting engine communication.

## Testing

The project includes multiple testing approaches:

### Micro-Testing Framework (Safe for Development)
```bash
# Run safe, minimal-output tests
make test
```
This runs targeted tests of specific chess functions with minimal output, 
safe for use during development.

### Compilation Testing (Always Safe)
```bash
# Test that code compiles and basic functionality works
./test_compile_only.sh
```

### Full Feature Testing (Run Manually Outside Development Sessions)
For comprehensive end-to-end testing including full game scenarios, 
castling integration, and AI interactions, use manual testing during 
gameplay. The micro-testing framework validates core logic, while manual 
gameplay testing validates full integration.

**Test Coverage:**
- ✅ **Micro-Tests**: Board initialization, position conversion, move 
  validation, castling rights, piece operations, FEN parsing, FEN 
  validation, character conversion
- ✅ **Compilation Tests**: Code builds successfully, executables created, 
  basic startup functionality
- ✅ **Integration Tests**: Manual gameplay testing for full feature 
  validation

The testing approach is designed to prevent development session crashes 
while ensuring code quality.

## Files

- `chess.h/chess.c` - Core chess logic and move validation
- `stockfish.h/stockfish.c` - Stockfish AI engine integration
- `main.c` - Game loop and user interface
- `fen_to_pgn.c` - Standalone FEN to PGN conversion utility
- `micro_test.c` - Safe micro-testing framework for development
- `test_compile_only.sh` - Safe compilation and basic functionality tests
- `Makefile` - Build configuration (builds chess, fen_to_pgn, and 
  micro_test)
- `CLAUDE.md` - Development notes and technical documentation

## Troubleshooting

1. **Stockfish not found**: Ensure Stockfish is installed and in your PATH
2. **Compilation errors**: Make sure you have GCC and development tools 
   installed
3. **Permission errors**: Ensure the compiled binary has execute 
   permissions
4. **Testing timeout issues on macOS**: The testing script requires 
   `gtimeout` (from GNU coreutils) instead of the standard `timeout` 
   command. Install with `brew install coreutils` if needed.

## Development

For technical details, architecture information, and development notes, 
see `CLAUDE.md`.

## License

This is a demonstration chess implementation. Stockfish is licensed under 
GPL v3.