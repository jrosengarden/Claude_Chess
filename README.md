# Claude Chess

A complete terminal chess game with AI opponent and comprehensive study
  features.

**Quick Start:** `make && make run`

## Features

### Core Gameplay
- Complete chess rules with all standard piece movements
- Castling (kingside/queenside), en passant, 50-move rule, and
  **pawn promotion**
- Clean ASCII board display with coordinates
- Move visualization with `*` and highlighted captures
- **Comprehensive time controls** with separate White/Black allocations
  (e.g., `TIME 30/10/5/0`)
- **Intelligent AI timing**: Depth-based search when disabled,
  time-based when enabled
- Unlimited undo functionality (disables time controls for remainder
  of game)
- AI opponent powered by Stockfish (adjustable difficulty 0-20)
- **Command line options** for customizing file creation and
  debug output

### Game Analysis & Study
- Position evaluation with visual scoring scale (-9 to +9)
- **Live PGN display** in side-by-side terminal windows that updates
  automatically after each move
- Custom board setup using FEN notation
- Interactive game loading with arrow key navigation
- **Verified classical opening library** (12 authenticated openings)
- **Verified demonstration opening library** (12 authenticated
  demo fen files)
- Automatic game recording in FEN and PGN formats
- Captured pieces display shows complete capture history for
  loaded positions
- **Opening validation tools** ensure legal positions and
  authentic sequences

## Requirements

- C compiler (GCC or compatible)
- Stockfish chess engine
- POSIX system (macOS, Linux)

**Tested on:** macOS 15.6.1, Ubuntu 22.04

## Installation

```bash
# Install Stockfish
brew install stockfish          # macOS
sudo apt install stockfish      # Ubuntu/Debian
# or: make install-deps

# Build and run
make && make run
```

## Command Line Options

The chess program supports several command line options for
  customizing behavior:

```bash
chess [options]
```

**Available options** (case-insensitive, can be used in any order):

- **`DEBUG`** - Enable debug mode with diagnostic output
- **`PGNOFF`** - Suppress automatic PGN file creation on game exit
- **`FENOFF`** - Delete FEN log file on game exit
  (after PGN creation)
- **`/HELP`** - Display detailed help information and exit

**Examples:**
```bash
chess                    # Start normal game
chess DEBUG              # Start with debug output
chess PGNOFF             # No PGN file created on exit
chess FENOFF             # FEN file deleted on exit
chess PGNOFF FENOFF      # No files saved on exit
chess debug pgnoff       # Mixed case works fine
chess /help              # Show detailed help
```

**Notes:**
- All options are case-insensitive
  (`DEBUG`, `debug`, `Debug` all work)
- Options can be combined in any order
- **Configuration integration**: Options override settings in
  CHESS.ini file
- **Set preferences in config**: Use CHESS.ini to avoid typing
  options repeatedly
- Use `chess /help` for detailed descriptions and more examples
- Invalid options will show an error and exit
  (won't start the game)

## How to Play

**Basic Controls:**
- Move: `e2 e4` (algebraic notation)
- Castling: `e1 g1` (move king two squares)
- **Pawn promotion**: Automatic when pawn reaches end -
  choose Q/R/B/N
	- Black (Stockfish) decides on it's promotion piece choice
- View moves: `e2` (show possible moves & captures from e2)
	[Captures appear in reverse text block]
- **Time controls**: `TIME 30/10/5/0`
  (White: 30min+10s, Black: 5min+0s)
- Undo: `undo` (unlimited, disables time controls for
  remainder of game)

**Game Flow:**
- You play White, AI (Stockfish) plays Black
- Clean single-board interface
- Automatic detection of checkmate, stalemate, draws
- **Interactive pawn promotion** with piece selection menu
- All games automatically saved as FEN and PGN files
- **File saving preferences**: Configure in CHESS.ini or use
  command line options

## Commands

### Gameplay
- `help` - Show help (paginated display with 11 lines per page)
- `hint` - Get AI's best move suggestion
- `skill N` - Set AI difficulty (0-20, before first move only)
- `time xx/yy` - Set time controls (before first move only,
  see Time Controls section below)
- Press RETURN - Update remaining time display
- `undo` - Unlimited undo (disables time controls for
  remainder of game)
- `resign` - Resign with confirmation
- `quit` - Exit game
- `title`- Redisplay game startup title screen

### Analysis & Study
- `score` - Position evaluation (-9 to +9 scale)
- `scale` - Shows conversion scale between Stockfish & Game
	-  Stockfish Centipawns score converted to Chess Game
	   -9/+9 scale
- `pgn` - View game in standard notation
  (live-updating side-by-side window)
- `fen` - View Current position in FEN format
	- Can use OS copy cmd to copy current board in FEN format
- `setup` - Configure custom position from FEN
- `load` - Show help for LOAD FEN and LOAD PGN commands
- `load fen` - Browse saved FEN games with arrow key navigation
- `load pgn` - Browse saved PGN games with arrow key navigation

### Special Features
- **Verified classical opening library** accessible via
  `load fen` command
- **Verified demonstration tactical library** accessible via
  `load fen` command
- **PGN file support** accessible via `load pgn` command for
  full move-by-move navigation
- All games auto-saved as timestamped FEN and PGN files
  (customizable via config file or command line)
- **Enhanced configuration system** via `CHESS.ini` file with
  file management preferences
- **Opening validation utilities** for study and analysis
- **Command line help system** with `/help` option for
  user guidance

## Time Controls

### Overview
Complete time control system with separate time allocations for
  White and Black players. Perfect for balancing human vs AI gameplay!

### Format Options
```bash
TIME xx/yy          # Same time controls for both players
TIME xx/yy/zz/ww    # Different: White gets xx/yy, Black zz/ww
TIME 0/0            # Disable time controls entirely
```

### Examples
```bash
TIME 15/5           # Both: 15 minutes + 5 second increment
TIME 30/10/5/0      # White: 30min+10sec, Black: 5min+0sec
                    # (recommended!)
TIME 45/15/10/2     # White: 45min+15sec, Black: 10min+2sec
TIME 1/0/1/0        # Blitz: 1 minute each, no increment
TIME 0/0            # No time limits (fastest AI moves)
```

### How It Works

**When Time Controls Are ENABLED (anything other than 0/0):**
- ⏱️ **Real-time countdown**: See your time decrease as you
  think
- 🤖 **AI uses actual time**: Stockfish thinks for appropriate
  duration based on time remaining
- ⚡ **Smart AI timing**: Uses ~1/20th of remaining time per
  move (min 500ms, max 10s)
- 🏃 **Time pressure**: Both players must manage their time
  strategically
- 💀 **Time forfeit**: Run out of time = automatic loss
- ➕ **Increment bonus**: Gain seconds after each move
  (if configured)

**When Time Controls Are DISABLED (0/0):**
- 🚀 **Instant AI moves**: Stockfish uses fast depth-10 search
- ⚡ **No time pressure**: Think as long as you want
- 🎯 **Consistent difficulty**: AI strength doesn't vary with
  "time pressure"

### Perfect for Balance!
**Problem**: Humans think slowly, Stockfish thinks instantly
**Solution**: Give yourself more time, give Stockfish less time!

```bash
TIME 30/10/3/0      # You: 30min+10s, AI: 3min total
                    # (fair fight!)
TIME 15/5/1/0       # Casual: You get plenty of time,
                    # AI gets 1 minute
TIME 60/30/10/0     # Tournament: You get 1 hour,
                    # AI gets 10 minutes
```

### Display
**With time controls enabled:**
```
White: 29:45 | Captured: [pieces] | Black: 1:23 |
  Captured: [pieces]
```

**With time controls disabled:**
```
White Captured: [pieces] | Black Captured: [pieces]
```

### Important Notes
- **TIME command locked after first move**: Like the `skill`
  command, time controls can only be changed before making your
  first move
- **Undo disables time controls**: Using `undo` turns off timers
  for the rest of that game
- **Real-time updates**: Timer shows live countdown during
  your turn
- **Fair play**: AI cannot think during your time
  (pondering disabled)
- **Time forfeit**: Game ends immediately when a player runs
  out of time

## Configuration (CHESS.ini)

Auto-created configuration file with settings:

```ini
[Paths]
FENDirectory=.                    # Directory for saved FEN
                                  # games (for LOAD FEN)
PGNDirectory=PGN_FILES            # Directory for saved PGN
                                  # games (for LOAD PGN)

[Settings]
DefaultSkillLevel=5               # AI difficulty (0-20)
AutoCreatePGN=true               # Create PGN files on exit
                                  # (true=PGNON, false=PGNOFF)
AutoDeleteFEN=false              # Delete FEN files on exit
                                  # (true=FENOFF, false=FENON)
DefaultTimeControl=30/10/5/0     # Default time controls
                                  # (White/Black can differ)
```

**Customization:**
- Move FEN files to custom directory and update `FENDirectory`
- Move PGN files to custom directory and update `PGNDirectory`
- Set default AI skill level
- **Configure file management preferences**: Set
  `AutoCreatePGN=false` for PGNOFF behavior,
  `AutoDeleteFEN=true` for FENOFF behavior
- **Set default time controls**: Use 2-value format
  (same for both) or 4-value format (different for each player)
- **Boolean values**: Use `true/false`, `yes/no`, `on/off`,
  or `1/0` (case-insensitive)
- **Command line override**: Command line options
  (PGNOFF/FENOFF) override config file settings
- **Runtime override**: `TIME` command during gameplay overrides
  config settings
- Cross-platform path support

## Board Display

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

- **Uppercase** = White pieces (bold magenta)
- **Lowercase** = Black pieces (bold cyan)
- `*` = Available move
- Highlighted piece = Capturable

## Pawn Promotion

When a pawn reaches the opposite end of the board (8th rank for
  White, 1st rank for Black), it **automatically promotes**
  as follows:

### Human Player (White)
You'll see this interactive menu when your pawn promotes:

```
Pawn promotion! Choose a piece to promote to:
Q - Queen (most powerful)
R - Rook
B - Bishop
N - Knight
Enter choice (Q/R/B/N):
```

Simply enter your choice (Q/R/B/N) and the pawn will transform
  into your selected piece.

### AI Player (Black)
The AI (Stockfish) **automatically selects** its preferred
  promotion piece without asking you. The game will display the
  AI's choice:

```
AI played: e7 to e8 (promoted to Queen)
```

This works for both regular promotion moves and promotion captures.

## Game Loading System

The chess program provides dual game loading capabilities for
  both FEN and PGN files:

### LOAD FEN Command
Browse and load saved FEN games from your chess game history:
- **Dual directory scanning**: Current directory and
  FENDirectory (from CHESS.ini)
- **Arrow key navigation**: Browse through positions with ← → keys
- **Interactive selection**: Press ENTER at any position to
  continue playing from that point
- **Classical opening library**: Access to 12 verified
  opening sequences
- **Demonstration positions**: 12 tactical scenarios for study
- **Smart filtering**: Current game's FEN file is automatically
  excluded from the list

### LOAD PGN Command
Browse and load PGN games with full move-by-move navigation:
- **Dual directory scanning**: Current directory and
  PGNDirectory (from CHESS.ini)
- **Full PGN parsing**: Supports standard PGN format with
  headers and move notation
- **Arrow key navigation**: Browse through moves with ← → keys
- **Interactive selection**: Press ENTER at any position to
  continue playing from that point
- **Automatic conversion**: PGN moves converted to FEN
  positions for seamless navigation

### Game Continuation Features
When you select a position from either FEN or PGN files:
- **Save current game prompt**: Choose whether to save your
  current game before loading
- **New game creation**: Fresh FEN log created with complete
  history up to selected position
- **Settings reset**: Game settings (skill level, time controls)
  become adjustable again
- **Seamless transition**: Continue playing from the selected
  position with full game logging

### Usage Examples
```bash
load          # Show help for both commands
load fen      # Browse FEN files
load pgn      # Browse PGN files
```

## Classical Opening Library

**Authenticated 12 classic chess openings** plus
  **feature demonstration files** using the `load fen` command:

**Classical Openings:**
- Italian Game, Ruy López, Queen's Gambit
- Sicilian Four Knights, French Defense, King's Indian
- English Opening, Caro-Kann, Alekhine's Defense
- Scandinavian, Nimzo-Indian, King's Gambit

**Feature Demonstrations:**
- Castling, En Passant, Pawn Promotion, Check, Checkmate,
  Stalemate
- Tactical concepts: Fork, Pin, Discovered Attack, Sacrifice,
  Back Rank

**All files are engine-validated and historically accurate!**

**Study workflow:**
1. Type `load fen` and select an opening or demonstration
2. Navigate through moves with ← → arrow keys (openings only)
3. Press ENTER at any position to resume play
	- Choose whether to save your current game
	- New time stamped FEN file created containing all moves from
	  the original game up to the point selected to continue play.
	  At that point normal move/FEN logging continues
4. Practice continuations against AI

**Feature Demonstrations:** Load any demo file to see chess
  rules and tactics in action. See `DEMONSTRATIONS.md` in the
  FEN_FILES directory for detailed explanations and suggested
  moves for each demonstration.

## Opening Validation Tools

**For advanced users and chess study:**

### Validate Opening Files
Verify that all FEN files contain legal chess positions:
```bash
./validate_openings # Check all 24 FEN files
                    # (openings + demonstrations)
./validate_openings FEN_FILES/RUY_LOPEZ.fen  # Check specific opening
```

### Verify Opening Authenticity
Confirm that opening files match expected patterns and tactical
  demonstrations are correct:
```bash
./verify_openings   # Verify all files against
                    # expected patterns
./verify_openings FEN_FILES/BackRank.fen  # Verify specific tactical position
```

### Convert Chess Moves to Positions (pgn_to_fen)
Generate clean FEN positions from standard PGN files:
```bash
./pgn_to_fen game.pgn > output.fen        # Convert PGN file to FEN
./pgn_to_fen < game.pgn > output.fen      # Pipe PGN file to converter
```

### Convert Chess Moves to Positions (fen_to_pgn)
Generate clean, standard,  PGN file from FEN files:
```bash
./fen_to_pgn 							  # Convert FEN to PGN
	(will request .fen file to convert)      
	(will output valid, standard, PGN file with same name as FEN file)
```

### Regenerate Complete Chess Library
Recreate all 24 FEN files from authentic sources:
```bash
./regenerate_openings  # Rebuild all openings + tactical demonstrations with 
     verified content
```

**Use cases:**
- Study opening theory with verified classical sequences (12 openings)
- Practice chess tactics with demonstration positions (12 tactical scenarios)
- Create custom opening collections from PGN files
- Validate downloaded FEN files for legal positions
- Verify authenticity of chess position libraries

## Building and Testing

```bash
make                   # Build chess and all utilities
make all			   # Build chess and all utilities
make debug			   # Build debug programs only
make utilities		   # Build utility programs only
make run               # Build and run chess game
make test              # Run micro-tests
make clean             # Clean build files
./test_compile_only.sh # Cross-platform compilation test
./validate_openings    # Verify chess library integrity (legal positions)
./verify_openings      # Verify library authenticity (opening theory + tactics)
```

## Troubleshooting

- **Stockfish not found**: Ensure Stockfish is installed and in PATH
- **Compilation errors**: Install GCC and development tools
- **macOS timeout issues**: Install `gtimeout` with `brew install coreutils`









**For developers:** See `CLAUDE.md` for technical details and architecture.

## License

This is a demonstration chess implementation. Stockfish is licensed under 
GPL v3.