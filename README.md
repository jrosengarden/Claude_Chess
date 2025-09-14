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
  capturing, check detection, castling (kingside and queenside), 
  en passant capture, and 50-move rule automatic draw detection
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
- **En Passant Capture**: Complete en passant capture implementation 
  following standard chess rules
- **AI Integration**: Uses Stockfish engine for intelligent computer moves 
  with adjustable difficulty levels (0-20)
- **Game State Detection**: Detects checkmate, stalemate, and 50-move 
  rule draw conditions automatically
- **Interactive Commands**: Help, hints, position analysis, undo, custom
  board setup, interactive game loading, game information, on-demand position
  evaluation, and real-time PGN display
- **Position Evaluation System**: Real-time Stockfish analysis with visual 
  scoring scale from -9 (Black winning) to +9 (White winning)
- **Custom Board Setup**: Setup any chess position using FEN notation 
  with the SETUP command
- **FEN Logging**: FEN logging to file (based on date & time at game 
  start) for all moves
- **Automatic PGN Generation**: Automatically converts FEN logs to PGN 
  format on game exit (quit, checkmate, stalemate)
- **File Notification**: Shows generated FEN and PGN filenames when games 
  end so users know where their game records are saved
- **Interactive Game Loading**: Browse and load any .fen file with arrow key
  navigation through positions, resume from any point with complete history preservation
- **Classical Opening Library**: Comprehensive collection of 12 classic chess
  openings for study and learning (Italian Game, Ruy López, Queen's Gambit,
  Sicilian Najdorf, French Defense, King's Indian, English Opening, Caro-Kann,
  Alekhine's Defense, Scandinavian, Nimzo-Indian, King's Gambit)
- **Automatic File Cleanup**: Removes meaningless starting-position-only files
  automatically, keeps only games that actually progressed
- **FEN to PGN Utility**: Standalone tool to convert FEN position files
  to PGN format (compatible with new FEN logging)

## Requirements

- GCC compiler (or compatible C compiler)
- Stockfish chess engine
- Cross-platform POSIX-compatible system (Linux, macOS, etc.)
- **Tested Platforms**: macOS Sequoia 15.6.1, Ubuntu Linux

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
   `e1 c1` (queenside). For en passant, move your pawn to the target 
   square behind the enemy pawn (e.g., `e5 f6` to capture en passant). 
   After each move, press Enter to continue.
4. **Custom Board Setup**: Type `setup` to enter a FEN string and 
   configure any chess position. The game will continue from your custom 
   position with a new FEN log file.
5. **Unlimited Undo**: Type `undo` to revert any number of move pairs. 
   You can undo back to the beginning of the game. The system will ask 
   how many move pairs to undo if multiple are available.
6. **Viewing Possible Moves**: Enter just a position (e.g., `e2`) to see 
   highlighted moves on the board.
7. **Automatic Draw Detection**: The game automatically detects and ends 
   in a draw when the 50-move rule is triggered (50 moves without pawn 
   moves or captures).
8. **Special Displays**:
   - `*` = Empty square you can move to
   - highlighted piece = Enemy piece you can capture (inverted colors)
   - Check warnings appear when your king is threatened
   - Game ending displays show final board position with ending reason 
     (checkmate, stalemate, 50-move rule draw) and wait for user to continue

## Game Controls

- `help` - Show help message
- `hint` - Get Stockfish's best move suggestion for White
- `score` - Display current position evaluation with visual scale
- `scale` - View the score conversion chart (centipawns to -9/+9 scale)
- `skill N` - Set AI difficulty level (0-20, only before first move)
- `fen` - Display current board position in FEN notation
- `pgn` - Display current game in PGN (Portable Game Notation) format
- `title` - Re-display the game title and startup information
- `setup` - Setup custom board position from FEN string (creates new
  FEN log file)
- `load` - Interactive browser for all .fen files with arrow key navigation
  (← → navigate positions, ENTER to resume, ESC ESC to cancel)
  **Includes 12 classic opening libraries for study and learning!**
- `undo` - Unlimited undo of move pairs using FEN log restoration
  (can undo back to game start)
- `resign` - Resign the game (with YES/NO confirmation)
- `quit` - Exit the game
- `e2 e4` - Move from e2 to e4
- `e2` - Show possible moves from e2

**Note**: All commands pause after displaying information, allowing you to
read the output before returning to the game board.

## Configuration File (CHESS.ini)

The chess game automatically creates and uses a `CHESS.ini` configuration file
to customize your experience. The file is created automatically on first run
with default settings.

### Configuration Options

**[Paths] Section:**
- **FENDirectory** - Directory containing FEN files for the LOAD command
  - Default: `.` (current directory)
  - Example: `FENDirectory=/home/user/chess/games`
  - Example: `FENDirectory=C:\Users\User\Chess\Games`

**[Settings] Section:**
- **DefaultSkillLevel** - Default AI difficulty level (0-20)
  - Default: `5` (beginner-friendly)
  - Range: `0` (easiest) to `20` (strongest)
  - Applied automatically at game startup
  - Can be overridden with `skill N` command before first move
  - Invalid values automatically corrected with debug warnings

### Example CHESS.ini File:
```ini
[Paths]
# Directory containing FEN files for the LOAD command
FENDirectory=.

[Settings]
# Default AI skill level (0=easiest, 20=strongest)
# Can be overridden with 'skill N' command before first move
DefaultSkillLevel=5

# Future settings can be added here
# AutoSavePGN=true
```

### Customizing FEN File Location

To move your FEN files to a different directory:

1. Create your desired directory: `mkdir ~/chess_games`
2. Move your FEN files: `mv *.fen ~/chess_games/`
3. Edit CHESS.ini: `FENDirectory=~/chess_games`
4. The LOAD command will now browse files in your custom directory

**Cross-Platform Paths:**
- Linux/macOS: `FENDirectory=/home/user/chess/games`
- Windows: `FENDirectory=C:\Users\User\Chess\Games`
- Relative paths: `FENDirectory=games` (subdirectory of current location)

## Position Evaluation System

The game includes a sophisticated position evaluation system powered by 
Stockfish that helps players understand the current state of the game:

### Score Command
- **Usage**: Type `score` during your turn to get real-time position analysis
- **Display**: Shows a visual scale from -9 (Black winning) to +9 (White winning)
- **Analysis Depth**: Uses Stockfish depth 15 for thorough position evaluation
- **Information Provided**:
  - Visual scale with tick marks and position indicator
  - In DEBUG mode: Raw centipawn score from Stockfish

### Scale Command  
- **Usage**: Type `scale` to view the conversion chart
- **Purpose**: Shows exactly how Stockfish centipawn evaluations map to the 
  -9 to +9 visual scale
- **Format**: Two-page display for easy reading on any terminal size
- **Content**: Complete breakdown of all evaluation ranges from "crushing" 
  to "barely ahead"

### Understanding the Scale
- **-9 to -1**: Black advantage (larger numbers = bigger advantage)
- **0**: Perfectly equal position
- **+1 to +9**: White advantage (larger numbers = bigger advantage)
- **Reference**: 100 centipawns ≈ 1 pawn advantage in material value

### On-Demand Analysis
The evaluation system is designed to be non-intrusive:
- **No automatic display**: Keeps the board clean during normal play
- **Fast analysis**: Uses existing Stockfish communication for quick results
- **User-controlled**: Only analyzes when you specifically request it

## Real-Time PGN Display

The game includes a real-time PGN (Portable Game Notation) display system
that allows you to view your current game progress in standard chess notation
at any time during play:

### PGN Command
- **Usage**: Type `pgn` during your turn to display the current game in
  standard PGN format
- **Side-by-side viewing**: Opens PGN notation in a separate terminal window
  while keeping the chess board visible for reference (NEW)
- **Cross-platform support**: Works on both macOS and Linux with automatic
  terminal detection (Terminal.app, gnome-terminal, konsole, etc.)
- **Seamless workflow**: Simply close the PGN window when done - no additional
  keystrokes needed to return to gameplay
- **Automatic fallback**: If new window cannot be opened, displays full-screen
  PGN with traditional interface
- **Real-time conversion**: Converts your active FEN log file to properly
  formatted PGN notation instantly
- **Complete game history**: Shows all moves from game start to current
  position with proper algebraic notation
- **Undo synchronization**: Updates correctly after undo operations, always
  showing accurate game state
- **Clean formatting**: Displays with proper PGN headers and move numbering
  for easy reading

### PGN Features
- **Dual display modes**:
  - **Side-by-side**: Separate terminal window (preferred method)
  - **Full-screen**: Traditional display (fallback method)
- **Enhanced user experience**: View chess board and PGN notation
  simultaneously for better game analysis
- **Smart terminal detection**: Automatically finds and uses the best
  available terminal application on your system
- **Standard notation**: Uses proper algebraic notation (e.g., `1. e4 e5
  2. Nf3 Nc6 3. Bc4`)
- **Special moves**: Correctly displays castling (`O-O`, `O-O-O`), captures
  (`Nxf7`), en passant, and promotions
- **Game headers**: Includes standard PGN headers with event information and
  current date
- **Clean presentation**: New terminal windows open with cleared screen
  showing only PGN content
- **Non-intrusive**: On-demand only - doesn't interrupt normal gameplay
- **Memory efficient**: Generates display string dynamically, no permanent
  storage overhead

### Viewing Your Game Progress
The enhanced PGN display system provides comprehensive game analysis:
- **`fen`** command: Shows current position in technical FEN notation
- **`pgn`** command: Opens side-by-side view with complete game in readable
  chess notation (or full-screen if new window unavailable)
- **`score`** command: Shows current position evaluation
- **Simultaneous viewing**: Chess board and PGN notation can be viewed
  together for enhanced game analysis and learning
- **Real-time updates**: All commands update automatically with game state
  and undo operations

## Interactive Game Loading

The game includes a sophisticated interactive game loading system with dual directory
scanning, organized display, and pagination that allows you to browse, navigate,
and resume from any saved chess game:

### Enhanced LOAD Command
- **Usage**: Type `load` during your turn to open the game browser
- **Dual directory scanning**: Automatically scans BOTH current directory (where
  your games are saved) AND your configured FENDirectory (for study files)
- **Organized section display**: Files shown in clean sections with headers:
  - **"Chess Program Directory"**: Your saved games from current sessions
  - **"FEN Files Directory"**: Study files, classical openings, imported games
- **Smart duplicate handling**: Files with same names shown only once (current
  directory takes precedence)
- **20-line pagination**: Large file lists automatically paginated with "Press Enter
  to continue" prompts and proper section continuation headers
- **Universal file support**: Loads any .fen file, not just files created by this program
- **File compatibility**: Works with FEN exports from other chess software, manual
  files, and shared games

### Interactive Navigation
Once you select a game to load, you enter the interactive browser:
- **← → Arrow keys**: Navigate through positions in the loaded game
- **Real-time board display**: See the exact position for each move
- **Position indicator**: Shows current position (e.g., "Position 8/15 - Move 4")
- **Move information**: Displays move numbers extracted from FEN notation
- **ENTER key**: Resume game from currently displayed position
- **ESC ESC (twice)**: Cancel and return to current game

### Complete Game History Preservation
When you resume from a loaded game:
- **Full history copying**: All positions from game start up to selected point
  are copied to your new game log
- **Perfect continuity**: No lost moves or missing history
- **New timestamped log**: Creates a fresh FEN log file for continued play
- **UNDO compatibility**: Can undo through the complete loaded history
- **PGN generation**: Includes the full game progression when creating PGN files

### Example Usage
```
White's turn. Enter move (e.g., 'e2 e4') or 'help': load

=== LOAD SAVED GAME ===

Chess Program Directory:
1. 09/14/25 11:05:50 - 1 moves
2. 09/13/25 12:00:00 - 18 moves

FEN Files Directory:
3. ITALIAN.fen - 34 moves
4. RUY_LOPEZ.fen - 23 moves
5. endgame_study.fen - 25 moves

Select game to load (1-5) or 0 to cancel: 3

[Interactive browser opens - navigate with ← → arrows]
```

**Pagination Example** (with 25+ files):
```
=== LOAD SAVED GAME ===

Chess Program Directory:
1. 09/14/25 11:05:50 - 1 moves
...
18. 09/01/25 14:22:15 - 45 moves

FEN Files Directory:
19. ITALIAN.fen - 34 moves
20. RUY_LOPEZ.fen - 23 moves

Press Enter to continue...

[Screen clears]

=== LOAD SAVED GAME ===

FEN Files Directory (continued):
21. QUEENS_GAMBIT.fen - 22 moves
...
25. KINGS_GAMBIT.fen - 21 moves

Select game to load (1-25) or 0 to cancel:
```

## Classical Opening Library

The game includes a comprehensive library of 12 classic chess openings
specifically designed for study and learning. These opening files work
seamlessly with the LOAD feature to provide an excellent educational experience.

### Available Openings
- **ITALIAN.fen** - Italian Game (34 positions)
- **RUY_LOPEZ.fen** - Ruy López/Spanish Opening (23 positions)
- **QUEENS_GAMBIT.fen** - Queen's Gambit (22 positions)
- **SICILIAN_NAJDORF.fen** - Sicilian Defense, Najdorf Variation (23 positions)
- **FRENCH_DEFENSE.fen** - French Defense (22 positions)
- **KINGS_INDIAN.fen** - King's Indian Defense (23 positions)
- **ENGLISH.fen** - English Opening (22 positions)
- **CARO_KANN.fen** - Caro-Kann Defense (21 positions)
- **ALEKHINES_DEFENSE.fen** - Alekhine's Defense (21 positions)
- **SCANDINAVIAN.fen** - Scandinavian Defense (21 positions)
- **NIMZO_INDIAN.fen** - Nimzo-Indian Defense (21 positions)
- **KINGS_GAMBIT.fen** - King's Gambit (21 positions)

### Study Features
**Perfect for Learning Chess Openings:**
1. **Move-by-Move Analysis**: Use the LOAD command and arrow keys to step
   through each opening move by move
2. **Resume and Explore**: Press ENTER at any position to resume the game
   from that point and explore your own variations
3. **Complete History**: When you resume from a position, the game preserves
   the entire opening sequence in your new game log
4. **AI Practice**: Continue playing against Stockfish from any opening
   position to practice your middle-game skills

### How to Use for Study
```
White's turn. Enter move (e.g., 'e2 e4') or 'help': load

=== LOAD SAVED GAME ===

Available saved games:
1. ITALIAN.fen - 34 moves
2. RUY_LOPEZ.fen - 23 moves
3. QUEENS_GAMBIT.fen - 22 moves
[... and more classical openings]

Select game to load: 1

[Navigate through Italian Game positions with ← → arrows]
[Press ENTER at move 15 to start playing from that position]
```

**Study Workflow:**
1. **Choose Opening**: Select any classical opening from the LOAD menu
2. **Study Theory**: Navigate through the theoretical moves with arrow keys
3. **Pick Your Spot**: Press ENTER at any interesting position
4. **Practice**: Continue the game against AI to improve your play
5. **Repeat**: Try different openings or different starting positions

This makes the LOAD feature a phenomenal study and learning tool for
chess openings!

## AI Difficulty Control

The game allows you to adjust the AI's playing strength to match your skill 
level:

### Skill Level Command
- **Usage**: Type `skill N` where N is a number from 0 to 20
- **Range**: 
  - **0**: Easiest (beginner friendly, makes obvious mistakes)
  - **10**: Intermediate (good for casual players)
  - **20**: Strongest (default, full Stockfish strength)
- **Timing Restriction**: Can ONLY be set before making your first move
- **Purpose**: Ensures fair games by preventing mid-game difficulty changes

### Setting Difficulty
1. **Start the game**: Launch chess normally
2. **Before moving**: Type `skill 5` (or your preferred level)
3. **Confirmation**: Game confirms the skill level is set
4. **Play normally**: AI will play at the chosen difficulty level
5. **No changes allowed**: Once you make your first move, skill level is locked

### Skill Level Guidelines
- **Beginners (0-5)**: AI makes tactical mistakes and doesn't see complex patterns
- **Intermediate (6-12)**: AI plays solidly but may miss deeper combinations  
- **Advanced (13-17)**: Strong tactical play with good positional understanding
- **Expert (18-20)**: Near-maximum strength, suitable for strong players

### Example Usage
```
White's turn. Enter move (e.g., 'e2 e4') or 'help': skill 8
Stockfish skill level set to 8 (0=easiest, 20=strongest)

[After first move attempt...]
White's turn. Enter move (e.g., 'e2 e4') or 'help': skill 12
Skill level cannot be changed after the game has started!
Use this command only before making your first move.
```

## En Passant Capture

The game includes full support for the en passant capture rule:

### How En Passant Works
- **Trigger**: When an enemy pawn moves two squares from its starting 
  position and lands next to your pawn
- **Opportunity**: You can immediately capture "en passant" by moving 
  your pawn diagonally to the square the enemy pawn passed over
- **Result**: The enemy pawn is removed from the board even though you 
  didn't move to its square
- **Timing**: En passant must be used immediately - the opportunity 
  disappears after any other move

### Example En Passant Scenario
1. White pawn on e5, Black plays f7-f5 (two-square pawn move)
2. Black pawn now on f5 is adjacent to White pawn on e5  
3. White can immediately capture en passant with `e5 f6`
4. Result: White pawn moves to f6, Black pawn on f5 is captured

### FEN Integration
- En passant opportunities are properly tracked in FEN notation
- SETUP command supports FEN strings with en passant target squares
- Game state accurately maintains en passant availability

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
- En passant available: 
  `rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3`
- 50-move rule draw (immediate): `8/8/8/8/4K3/8/8/4k3 w - - 100 50`
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
- **Automatic cleanup**: Files containing only the starting position are
  automatically removed - no clutter from games that never progressed

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
- **Smart cleanup**: If a game never progressed beyond the starting position,
  no files are created and user is notified with "No game files created"

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
  from input FEN strings
- **Complex FEN Support**: Handles complex board positions with high move 
  counts and advanced game states without crashes or infinite recursion
- **50-Move Rule Integration**: Automatically detects draw conditions when 
  halfmove clock reaches 100 (50 full moves without pawn move or capture)
- **Standards Compliant**: All generated FEN strings follow official 
  Forsyth-Edwards Notation specification

## Debug Mode

Run the game with `./chess DEBUG` to enable debug output that shows:
- **Configuration loading**: Shows loaded FEN directory and default skill level
- **Configuration validation**: Warns about invalid settings being corrected:
  - `WARNING: Invalid FENDirectory in CHESS.ini - using default '.'`
  - `WARNING: Invalid DefaultSkillLevel in CHESS.ini - using default 5`
- **Raw Stockfish move strings** (e.g., "e7e5")
- **Parsed move coordinates** for AI moves and hints
- **Additional diagnostic information** during gameplay

This is useful for development, troubleshooting engine communication, and verifying
your configuration settings are loading correctly.

## Building and Testing

```bash
# Compile the game (works on both macOS and Linux)
make

# Run the chess game  
./chess

# Test that everything works (cross-platform compatible)
make test

# Run safe compilation tests (cross-platform)
./test_compile_only.sh
```

### Cross-Platform Notes
- **macOS & Linux**: Project compiles cleanly on both platforms with no 
  warnings
- **Automatic platform detection**: Build and test scripts automatically 
  adapt to your operating system
- **Full compatibility**: All features work identically on both macOS and 
  Linux

## Troubleshooting

1. **Stockfish not found**: Ensure Stockfish is installed and in your PATH
2. **Compilation errors**: Make sure you have GCC and development tools 
   installed
3. **Permission errors**: Ensure the compiled binary has execute 
   permissions
4. **Cross-platform timeout issues**: 
   - **macOS**: The testing script may require `gtimeout` (from GNU 
     coreutils) instead of the standard `timeout` command. Install with 
     `brew install coreutils` if needed.
   - **Linux**: Uses standard `timeout` command (usually pre-installed)
   - **Automatic detection**: The test script automatically detects and 
     uses the correct timeout command for your platform

## Development

For technical details, architecture information, and development notes, 
see `CLAUDE.md`.

## License

This is a demonstration chess implementation. Stockfish is licensed under 
GPL v3.